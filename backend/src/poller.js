import { Octokit } from "@octokit/rest";
import { upsertRepository, upsertWorkflowRuns, isAlertSent, markAlertSent } from "./db.js";
import { sendSlackAlert, sendEmailAlert } from "./alert.js";

const token = process.env.GITHUB_TOKEN;
const reposEnv = process.env.GITHUB_REPOS || "";
const pollIntervalSeconds = Number(process.env.POLL_INTERVAL_SECONDS || 60);

const octokit = new Octokit({ auth: token });

function parseRepos(input) {
	return input
		.split(",")
		.map(s => s.trim())
		.filter(Boolean);
}

export async function pollOnce() {
	const repos = parseRepos(reposEnv);
	for (const fullName of repos) {
		await ingestRepo(fullName);
	}
}

async function ingestRepo(fullName) {
	const repoId = await upsertRepository(fullName);
	const [owner, repo] = fullName.split("/");
	const { data } = await octokit.actions.listWorkflowRunsForRepo({ owner, repo, per_page: 50 });
	const runs = (data.workflow_runs || []).map(run => ({
		id: run.id,
		status: run.status,
		conclusion: run.conclusion,
		run_number: run.run_number,
		html_url: run.html_url,
		created_at: run.created_at,
		run_started_at: run.run_started_at,
		updated_at: run.updated_at,
		duration_seconds: run.run_started_at && run.updated_at ? Math.round((new Date(run.updated_at) - new Date(run.run_started_at)) / 1000) : null
	}));
	await upsertWorkflowRuns(repoId, runs);

	// Send alerts for fresh failures not alerted yet
	for (const run of runs) {
		if (!run.conclusion || run.conclusion === "success") continue;
		const already = await isAlertSent(run.id);
		if (already) continue;
		await notifyFailure(fullName, run);
		await markAlertSent(run.id);
	}
}

async function notifyFailure(fullName, run) {
	const link = run.html_url;
	const text = `❌ Pipeline failed: ${fullName} #${run.run_number} (${run.conclusion})\n${link}`;

	await sendSlackAlert(process.env.SLACK_WEBHOOK_URL, text);
	await sendEmailAlert(
		{
			host: process.env.SMTP_HOST,
			port: process.env.SMTP_PORT,
			secure: process.env.SMTP_SECURE,
			user: process.env.SMTP_USER,
			pass: process.env.SMTP_PASS
		},
		process.env.ALERT_EMAIL_TO,
		`Pipeline failed: ${fullName} #${run.run_number}`,
		text
	);
}

let intervalHandle = null;
export function startPolling() {
	if (intervalHandle) return;
	intervalHandle = setInterval(() => {
		pollOnce().catch(err => console.error("Polling error:", err.message));
	}, pollIntervalSeconds * 1000);
} 