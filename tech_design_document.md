##  Architecture Overview

### System Overview
The CI/CD Pipeline Health Dashboard follows a modern microservices architecture with containerized deployment, designed for scalability, maintainability, and real-time monitoring capabilities.

### High Level Architecture

```
┌─────────────────┐    GitHub API     ┌─────────────────┐
│ GitHub Actions  │ ────────────────▶  │   Node.js       │
│   Workflows     │                    │   Backend       │
└─────────────────┘                    │   (Port 4000)   │
                                       └─────────┬───────┘
                                                 │
                ┌─────────────────┐             │ REST API
                │   PostgreSQL    │ ◀───────────┤
                │   Database      │             │
                │  (Port 5432)    │             │
                └─────────────────┘             │
                                                │
┌─────────────────┐    HTTP API           ┌────▼────────────┐
│ React Frontend  │ ◀──────────────────────│  Express       │
│  (Port 5173)    │                        │  Server        │
└─────────────────┘                        └─────────────────┘
                                                │
                                           ┌────▼────────────┐
                                           │    Alerting     │
                                           │ (Slack/Email)   │
                                           └─────────────────┘
```

### Detailed System Architecture

#### 1. Data Flow Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   GitHub    │───▶│   Backend   │───▶│ PostgreSQL │───▶│  Frontend   │
│   Actions   │    │   Poller    │    │  Database  │    │   Display   │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │                   │
       │                   ▼                   ▼                   ▼
       │            ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
       │            │   Metrics   │    │   Data      │    │   Real-time │
       │            │ Calculator  │    │ Persistence │    │   Updates   │
       └───────────▶└─────────────┘    └─────────────┘    └─────────────┘
                            │                   │                   │
                            ▼                   ▼                   ▼
                   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
                   │   Alerting  │    │   Health    │    │   User      │
                   │   Engine    │    │   Checks    │    │   Interface │
                   └─────────────┘    └─────────────┘    └─────────────┘
```

#### 2. Container Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Docker Compose Stack                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │   Node.js API   │    │   React App     │
│   Container     │    │   Container     │    │   Container     │
│                 │    │                 │    │                 │
│ • Port: 5432    │    │ • Port: 4000    │    │ • Port: 5173    │
│ • Volume: db    │    │ • Env: GitHub   │    │ • Build: Vite   │
│ • User: actions │    │   Token, Repos  │    │ • Serve: Nginx  │
│ • DB: actions   │    │ • Depends: DB   │    │ • Depends: API  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         ▲                       ▲                       ▲
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │      Shared Network       │
                    │   (ci-cd-dashboard-net)  │
                    └───────────────────────────┘
```
