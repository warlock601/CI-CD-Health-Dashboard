import nodemailer from "nodemailer";

export async function sendSlackAlert(webhookUrl, text) {
	if (!webhookUrl) return;
	await fetch(webhookUrl, {
		method: "POST",
		headers: { "Content-Type": "application/json" },
		body: JSON.stringify({ text })
	});
}

export async function sendEmailAlert({ host, port, secure, user, pass }, to, subject, text) {
	if (!to || !host) return;
	const transporter = nodemailer.createTransport({ host, port: Number(port || 587), secure: String(secure) === "true", auth: user ? { user, pass } : undefined });
	await transporter.sendMail({ from: user || "pipeline-dashboard@example", to, subject, text });
} 