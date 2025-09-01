##  Architecture Overview

### System Overview
The CI/CD Pipeline Health Dashboard follows a modern microservices architecture with containerized deployment, designed for scalability, maintainability, and real-time monitoring capabilities.

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              CI/CD Health Dashboard                             │
│                              Technical Architecture                             │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐    GitHub API     ┌─────────────────────────────────────────┐
│ GitHub Actions  │ ◀─────────────────│           Node.js Backend               │
│   Workflows     │    Polling        │         (Port 4000)                     │
│                 │    (60s interval) │  ┌─────────────────────────────────────┐ │
│ • Workflow Runs │                   │  │ Express Server                       │ │
│ • Build Status  │                   │  │ • REST API Endpoints                │ │
│ • Duration      │                   │  │ • GitHub API Integration            │ │
│ • Conclusion    │                   │  │ • Metrics Calculation               │ │
└─────────────────┘                   │  │ • Alert Management                  │ │
                                      │  └─────────────────────────────────────┘ │
                                      └─────────────────┬───────────────────────┘
                                                        │
                                      ┌─────────────────▼───────────────────────┐
                                      │           PostgreSQL Database            │
                                      │           (Port 5432)                   │
                                      │  ┌─────────────────────────────────────┐ │
                                      │  │ • Workflow Runs Table               │ │
                                      │  │ • Repository Metadata               │ │
                                      │  │ • Metrics Cache                     │ │
                                      │  │ • Alert History                     │ │
                                      │  └─────────────────────────────────────┘ │
                                      └─────────────────┬───────────────────────┘
                                                        │
                                      ┌─────────────────▼───────────────────────┐
                                      │           React Frontend                │
                                      │           (Port 5173)                   │
                                      │  ┌─────────────────────────────────────┐ │
                                      │  │ • Dashboard UI                      │ │
                                      │  │ • Real-time Metrics                 │ │
                                      │  │ • Repository Selector               │ │
                                      │  │ • Build History Table               │ │
                                      │  └─────────────────────────────────────┘ │
                                      └─────────────────┬───────────────────────┘
                                                        │
                                      ┌─────────────────▼───────────────────────┐
                                      │           Alerting System               │
                                      │  ┌─────────────────────────────────────┐ │
                                      │  │ • Slack Webhooks                    │ │
                                      │  │ • SMTP Email Notifications          │ │
                                      │  │ • Build Failure Triggers            │ │
                                      │  │ • Status Change Alerts              │ │
                                      │  └─────────────────────────────────────┘ │
                                      └─────────────────────────────────────────┘
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

### 2.3 Service Dependencies

```
Service Dependencies:
├── Frontend (React) ──── depends_on ──── Backend (Node.js)
├── Backend (Node.js) ──── depends_on ──── Database (PostgreSQL)
└── Database (PostgreSQL) ──── standalone

Network Communication:
├── Frontend ↔ Backend: HTTP/HTTPS (Port 4000)
├── Backend ↔ Database: PostgreSQL (Port 5432)
└── Backend ↔ GitHub: HTTPS (GitHub API)
```

---

## 3. Component Architecture

### 3.1 Backend Components

#### 3.1.1 Express Server (`src/index.js`)
```javascript
// Core Responsibilities
- HTTP server setup and middleware configuration
- CORS handling for frontend communication
- Database initialization
- Polling service startup
- Health check endpoint

// Technical Implementation
- Express.js framework with ES modules
- Morgan HTTP request logging
- Environment-based configuration
- Graceful error handling and shutdown
```

#### 3.1.2 API Router (`src/routes.js`)
```javascript
// RESTful Endpoints
GET /api/health          // System health check
GET /api/repos           // List tracked repositories
GET /api/metrics?repo=X  // Repository metrics
GET /api/runs?repo=X     // Recent workflow runs
