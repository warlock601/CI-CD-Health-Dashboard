import React from 'react'

export default function RunsTable({ rows }) {
	return (
		<div style={{overflowX:'auto'}}>
			<table>
				<thead>
					<tr>
						<th>Run</th>
						<th>Status</th>
						<th>Conclusion</th>
						<th>Duration</th>
						<th>Started</th>
						<th>Link</th>
					</tr>
				</thead>
				<tbody>
					{rows.map(r => (
						<tr key={r.id}>
							<td className="mono">#{r.run_number}</td>
							<td>{r.status || '—'}</td>
							<td>{r.conclusion || '—'}</td>
							<td>{formatDuration(r.duration_seconds)}</td>
							<td>{formatDateTime(r.created_at)}</td>
							<td><a href={r.html_url} target="_blank" rel="noreferrer">Open</a></td>
						</tr>
					))}
				</tbody>
			</table>
		</div>
	)
}

function formatDuration(totalSeconds) {
	if (totalSeconds == null) return '—'
	const s = Number(totalSeconds || 0)
	const h = Math.floor(s / 3600)
	const m = Math.floor((s % 3600) / 60)
	const sec = s % 60
	if (h) return `${h}h ${m}m`
	if (m) return `${m}m ${sec}s`
	return `${sec}s`
}

function formatDateTime(value) {
	if (!value) return '—'
	const d = new Date(value)
	return d.toLocaleString()
} 