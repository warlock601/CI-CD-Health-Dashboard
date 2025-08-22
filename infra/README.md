# Run locally with Docker Compose

1. Create an env file:
   - Copy `env.example` to `.env` and fill values.

2. Start the stack:
```bash
cd infra
docker compose up --build
```

Services:
- Frontend: http://localhost:5173
- API: http://localhost:4000/api/health
- Postgres: localhost:5432 (user: actions, pass: actions, db: actions) 