import React from 'react'

export default function RepoSelector({ repos, value, onChange }) {
	return (
		<div style={{display:'flex', alignItems:'center', gap: 12}}>
			<label style={{color:'#9ca3af'}}>Repository</label>
			<select value={value} onChange={e => onChange(e.target.value)}>
				{repos.map(r => (
					<option key={r.id} value={r.full_name}>{r.full_name}</option>
				))}
			</select>
		</div>
	)
} 