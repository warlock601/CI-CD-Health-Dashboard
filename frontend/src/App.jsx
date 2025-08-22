import React, { useEffect, useMemo, useState } from 'react'
import { fetchRepos, fetchMetrics, fetchRuns } from './api.js'
import RepoSelector from './components/RepoSelector.jsx'
import MetricsCards from './components/MetricsCards.jsx'
import RunsTable from './components/RunsTable.jsx'

export default function App() {
	const [repos, setRepos] = useState([])
	const [selectedRepo, setSelectedRepo] = useState('')
	const [metrics, setMetrics] = useState(null)
	const [runs, setRuns] = useState([])
	const [loading, setLoading] = useState(true)
	const [error, setError] = useState('')

	useEffect(() => {
		let mounted = true
		async function loadRepos() {
			try {
				const list = await fetchRepos()
				if (!mounted) return
				setRepos(list)
				if (!selectedRepo && list.length) {
					setSelectedRepo(list[0].full_name)
				}
			} catch (e) {
				setError(String(e.message || e))
			} finally {
				setLoading(false)
			}
		}
		loadRepos()
		return () => { mounted = false }
	}, [])

	useEffect(() => {
		if (!selectedRepo) return
		let mounted = true
		async function load() {
			try {
				const [m, r] = await Promise.all([
					fetchMetrics(selectedRepo),
					fetchRuns(selectedRepo, 25)
				])
				if (!mounted) return
				setMetrics(m)
				setRuns(r)
				setError('')
			} catch (e) {
				setError(String(e.message || e))
			}
		}
		load()
		const id = setInterval(load, 30000)
		return () => { mounted = false; clearInterval(id) }
	}, [selectedRepo])

	const lastStatusBadge = useMemo(() => {
		if (!metrics || !metrics.lastRun) return null
		const c = metrics.lastRun.conclusion
		const cls = c === 'success' ? 'badge badge-ok' : c ? 'badge badge-err' : 'badge badge-warn'
		const label = c || metrics.lastRun.status || 'unknown'
		return <span className={cls}>{label}</span>
	}, [metrics])

	return (
		<div className="container">
			<h2 style={{margin: 0, marginBottom: 12}}>Pipeline Health Dashboard</h2>
			<p style={{marginTop: 0, color: '#9ca3af'}}>GitHub Actions monitor with live metrics and alerts</p>

			<div className="card" style={{marginBottom: 16}}>
				<RepoSelector repos={repos} value={selectedRepo} onChange={setSelectedRepo} />
			</div>

			<div className="grid" style={{marginBottom: 16}}>
				<div className="card col-3">
					<div style={{color:'#9ca3af', fontSize:12}}>Success Rate (24h)</div>
					<div style={{fontSize:28, fontWeight:600}}>{metrics?.successRate != null ? metrics.successRate + '%' : '—'}</div>
				</div>
				<div className="card col-3">
					<div style={{color:'#9ca3af', fontSize:12}}>Failure Rate (24h)</div>
					<div style={{fontSize:28, fontWeight:600}}>{metrics?.failureRate != null ? metrics.failureRate + '%' : '—'}</div>
				</div>
				<div className="card col-3">
					<div style={{color:'#9ca3af', fontSize:12}}>Average Build Time</div>
					<div style={{fontSize:28, fontWeight:600}}>{metrics?.averageDurationSeconds != null ? formatDuration(metrics.averageDurationSeconds) : '—'}</div>
				</div>
				<div className="card col-3">
					<div style={{color:'#9ca3af', fontSize:12}}>Last Build Status</div>
					<div style={{fontSize:28, fontWeight:600}}>{lastStatusBadge || '—'}</div>
				</div>
			</div>

			<div className="card col-12" style={{marginBottom: 16}}>
				<h3 style={{marginTop:0}}>Latest Runs</h3>
				<RunsTable rows={runs} />
			</div>

			{error ? <div className="card" style={{borderColor:'#7f1d1d', color:'#fecaca'}}>{error}</div> : null}
			{loading ? <div className="card" style={{color:'#9ca3af'}}>Loading…</div> : null}
		</div>
	)
}

function formatDuration(totalSeconds) {
	const s = Number(totalSeconds || 0)
	const h = Math.floor(s / 3600)
	const m = Math.floor((s % 3600) / 60)
	const sec = s % 60
	if (h) return `${h}h ${m}m`
	if (m) return `${m}m ${sec}s`
	return `${sec}s`
} 