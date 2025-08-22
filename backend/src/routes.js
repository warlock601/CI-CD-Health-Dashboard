import express from "express";
import { getTrackedRepositories, getRecentRunsByRepo, getMetrics } from "./db.js";

export function createRouter() {
	const router = express.Router();

	router.get("/health", (req, res) => {
		res.json({ ok: true, time: new Date().toISOString() });
	});

	router.get("/repos", async (req, res) => {
		const repos = await getTrackedRepositories();
		res.json(repos);
	});

	router.get("/metrics", async (req, res) => {
		const repo = req.query.repo;
		if (!repo) return res.status(400).json({ error: "repo is required" });
		const metrics = await getMetrics(repo);
		if (!metrics) return res.status(404).json({ error: "repo not found" });
		res.json(metrics);
	});

	router.get("/runs", async (req, res) => {
		const repo = req.query.repo;
		const limit = Math.min(parseInt(req.query.limit || "25", 10), 100);
		if (!repo) return res.status(400).json({ error: "repo is required" });
		const runs = await getRecentRunsByRepo(repo, limit);
		res.json(runs);
	});

	return router;
} 