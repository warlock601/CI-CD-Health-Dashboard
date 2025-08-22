import pg from "pg";

const { Pool } = pg;

const databaseUrl = process.env.DATABASE_URL || "postgres://actions:actions@localhost:5432/actions";

export const pool = new Pool({ connectionString: databaseUrl });

export async function initSchema() {
	const client = await pool.connect();
	try {
		await client.query(`
			CREATE TABLE IF NOT EXISTS repositories (
				id SERIAL PRIMARY KEY,
				full_name TEXT UNIQUE NOT NULL
			);

			CREATE TABLE IF NOT EXISTS workflow_runs (
				id BIGINT PRIMARY KEY,
				repo_id INTEGER NOT NULL REFERENCES repositories(id) ON DELETE CASCADE,
				status TEXT,
				conclusion TEXT,
				run_number INTEGER,
				html_url TEXT,
				created_at TIMESTAMPTZ,
				started_at TIMESTAMPTZ,
				updated_at TIMESTAMPTZ,
				duration_seconds INTEGER
			);

			CREATE INDEX IF NOT EXISTS idx_runs_repo_created ON workflow_runs(repo_id, created_at DESC);

			CREATE TABLE IF NOT EXISTS alerts_sent (
				id SERIAL PRIMARY KEY,
				run_id BIGINT UNIQUE NOT NULL,
				alerted_at TIMESTAMPTZ DEFAULT now()
			);
		`);
	} finally {
		client.release();
	}
}

export async function upsertRepository(fullName) {
	const { rows } = await pool.query(
		`INSERT INTO repositories (full_name) VALUES ($1)
		 ON CONFLICT (full_name) DO UPDATE SET full_name = EXCLUDED.full_name
		 RETURNING id`,
		[fullName]
	);
	return rows[0].id;
}

export async function upsertWorkflowRuns(repoId, runs) {
	if (!runs || runs.length === 0) return 0;
	const values = [];
	const placeholders = [];
	runs.forEach((r, i) => {
		const idx = i * 10;
		placeholders.push(
			`($${idx + 1}, $${idx + 2}, $${idx + 3}, $${idx + 4}, $${idx + 5}, $${idx + 6}, $${idx + 7}, $${idx + 8}, $${idx + 9}, $${idx + 10})`
		);
		values.push(
			r.id,
			repoId,
			r.status,
			r.conclusion,
			r.run_number,
			r.html_url,
			r.created_at ? new Date(r.created_at) : null,
			r.run_started_at ? new Date(r.run_started_at) : null,
			r.updated_at ? new Date(r.updated_at) : null,
			r.duration_seconds ?? null
		);
	});
	const sql = `INSERT INTO workflow_runs (
		id, repo_id, status, conclusion, run_number, html_url, created_at, started_at, updated_at, duration_seconds
	) VALUES ${placeholders.join(", ")}
	ON CONFLICT (id) DO UPDATE SET
		status = EXCLUDED.status,
		conclusion = EXCLUDED.conclusion,
		run_number = EXCLUDED.run_number,
		html_url = EXCLUDED.html_url,
		created_at = EXCLUDED.created_at,
		started_at = EXCLUDED.started_at,
		updated_at = EXCLUDED.updated_at,
		duration_seconds = EXCLUDED.duration_seconds`;
	await pool.query(sql, values);
	return runs.length;
}

export async function getTrackedRepositories() {
	const { rows } = await pool.query("SELECT id, full_name FROM repositories ORDER BY full_name ASC");
	return rows;
}

export async function getRecentRunsByRepo(fullName, limit = 25) {
	const { rows } = await pool.query(
		`SELECT wr.* FROM workflow_runs wr
		 JOIN repositories r ON r.id = wr.repo_id
		 WHERE r.full_name = $1
		 ORDER BY created_at DESC NULLS LAST
		 LIMIT $2`,
		[fullName, limit]
	);
	return rows;
}

export async function getMetrics(fullName) {
	const { rows: repoRows } = await pool.query("SELECT id FROM repositories WHERE full_name = $1", [fullName]);
	if (repoRows.length === 0) return null;
	const repoId = repoRows[0].id;

	const { rows: lastRunRows } = await pool.query(
		`SELECT * FROM workflow_runs WHERE repo_id = $1 ORDER BY created_at DESC NULLS LAST LIMIT 1`,
		[repoId]
	);
	const lastRun = lastRunRows[0] || null;

	const { rows: windowRows } = await pool.query(
		`SELECT conclusion, duration_seconds FROM workflow_runs
		 WHERE repo_id = $1 AND created_at > now() - interval '24 hours'`,
		[repoId]
	);
	const total = windowRows.length;
	const successes = windowRows.filter(r => r.conclusion === "success").length;
	const failures = windowRows.filter(r => r.conclusion && r.conclusion !== "success").length;
	const avg = windowRows.length
		? Math.round(windowRows.filter(r => r.duration_seconds != null).reduce((a, b) => a + (b.duration_seconds || 0), 0) / windowRows.length)
		: null;

	return {
		repo: fullName,
		windowLast24h: total,
		successRate: total ? Math.round((successes / total) * 100) : null,
		failureRate: total ? Math.round((failures / total) * 100) : null,
		averageDurationSeconds: avg,
		lastRun
	};
}

export async function isAlertSent(runId) {
	const { rows } = await pool.query("SELECT 1 FROM alerts_sent WHERE run_id = $1", [runId]);
	return rows.length > 0;
}

export async function markAlertSent(runId) {
	await pool.query("INSERT INTO alerts_sent (run_id) VALUES ($1) ON CONFLICT (run_id) DO NOTHING", [runId]);
} 