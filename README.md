# CI/CD Pipeline Health Dashboard 
A simple, containerized dashboard to monitor GitHub Actions pipeline health across repositories. It collects workflow run metadata, computes success/failure rates and average build times, displays latest build status, and can send alerts to Slack and/or Email on failures.

## Stack
- Backend: Node.js (Express), GitHub API via Octokit, PostgreSQL
- Frontend: React (Vite), served by Nginx
- Database: PostgreSQL
- Alerting: Slack webhook and SMTP email (optional)
- Orchestration: Docker Compose (see `infra/docker-compose.yml`)

## Prerequisites
- Docker Desktop installed
- A GitHub Personal Access Token with `repo` and `actions:read` scopes

## Steps:
- Clone the repo and move ino the infra/ directory. Then open the .env file.
```bash
     cd infra
     vi .env
```
- Edit the .env file to add values as per the requirements like:
```bash
# Required
GITHUB_TOKEN=ghp_your_token_here
GITHUB_REPOS=owner1/repo1,owner2/repo2

# Optional
POLL_INTERVAL_SECONDS=60
SLACK_WEBHOOK_URL=
ALERT_EMAIL_TO=
SMTP_HOST=
SMTP_PORT=
SMTP_SECURE=
SMTP_USER=
SMTP_PASS=

```
- Start the Slack
```bash
docker compose up --build
```
