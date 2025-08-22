const resolveApiBaseUrl = () => {
	const fromEnv = import.meta?.env?.VITE_API_URL
	if (fromEnv) return fromEnv
	const loc = window.location
	const host = loc.hostname || 'localhost'
	const proto = loc.protocol || 'http:'
	const port = proto === 'https:' ? 443 : 4000
	return `${proto}//${host}:${port}`
}

const API_BASE = resolveApiBaseUrl()

async function httpGet(path) {
	const res = await fetch(`${API_BASE}${path}`)
	if (!res.ok) throw new Error(`Request failed: ${res.status}`)
	return await res.json()
}

export async function fetchRepos() {
	return await httpGet('/api/repos')
}

export async function fetchMetrics(repo) {
	const p = new URLSearchParams({ repo })
	return await httpGet(`/api/metrics?${p.toString()}`)
}

export async function fetchRuns(repo, limit = 25) {
	const p = new URLSearchParams({ repo, limit: String(limit) })
	return await httpGet(`/api/runs?${p.toString()}`)
} 