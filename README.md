# CI/CD Pipeline Health Dashboard 
A simple, containerized dashboard to monitor GitHub Actions pipeline health across repositories. It collects workflow run metadata, computes success/failure rates and average build times, displays latest build status, and can send alerts to Slack and/or Email on failures.

## 🚀 Features

- ✅ **Real-time data collection** from GitHub Actions via GitHub API
- ✅ **Live metrics dashboard** with success/failure rates and build times
- ✅ **Automated polling** for continuous pipeline monitoring
- ✅ **Alerting system** with Slack webhooks and SMTP email notifications
- ✅ **Modern React UI** with responsive design and real-time updates
- ✅ **Fully containerized** with Docker for consistent deployment
- ✅ **Production-ready** with health checks, database persistence, and proper documentation

## Prerequisites
- Docker Desktop installed
- A GitHub Personal Access Token with `repo` and `actions:read` scopes

## Development Setup:

### Using Docker Compose:
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
- To Start
```bash
docker compose up --build
```
- Open the apps </br>
Frontend: http://localhost:5173   </br>
API health: http://localhost:4000/api/health   </br>
Postgres: http://localhost:5432 

- To stop:
```bash
docker compose down
```
### Without Docker:
```bash
# Clone repository
git clone <repository-url>

# Install dependencies
cd backend && npm install
cd ../frontend && npm install

# Run development servers
cd backend && npm start
cd ../frontend && npm run dev
```

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

### Component Details

#### Backend (Node.js + Express)
- **Technology**: Node.js, Express, Octokit (GitHub API), PostgreSQL
- **Responsibilities**:
  - GitHub Actions workflow data collection via API
  - Metrics calculation (success rates, build times)
  - Database operations and data persistence
  - Alerting system (Slack/email notifications)
- **Key Endpoints**:
  - `GET /api/health` - Health check endpoint
  - `GET /api/repos` - Repository list
  - `GET /api/metrics/:repo` - Repository metrics
  - `GET /api/runs/:repo` - Build runs data

#### Frontend (React)
- **Technology**: React 18, Vite, modern CSS
- **Responsibilities**:
  - Dashboard visualization and metrics display
  - Repository selection and data filtering
  - Real-time updates via polling
  - Responsive user interface
- **Key Features**:
  - Live metrics cards (success rate, failure rate, avg build time)
  - Repository selector dropdown
  - Recent runs table with status indicators
  - Auto-refresh every 30 seconds

#### Database (PostgreSQL)
- **Schema**: Optimized for CI/CD pipeline data storage
- **Tables**: Workflow runs, repositories, metrics
- **Features**: Persistent storage with Docker volumes

#### Containerization
- **Multi-service Docker Compose** setup
- **Volume persistence** for database data
- **Health checks** and service dependencies
- **Environment-based configuration**

## 🔧 Configuration Options

### GitHub Integration
- **Token**: Personal Access Token with required scopes
- **Repositories**: Comma-separated list of `owner/repo` format
- **Polling**: Configurable interval (default: 60 seconds)

### Alerting Configuration
- **Slack**: Webhook URL for instant notifications
- **Email**: SMTP configuration for email alerts
- **Triggers**: Build failures and status changes

### Performance Tuning
- **Poll Interval**: Adjust based on GitHub API rate limits
- **Database**: PostgreSQL connection pooling
- **Frontend**: 30-second auto-refresh cycle


## 🚨 Alerting System

### Slack Integration
- Instant notifications on build failures
- Configurable webhook URL
- Rich message formatting

### Email Notifications
- SMTP server configuration
- Customizable recipient lists
- Build failure details included

## 🔍 Monitoring & Health Checks

### Health Endpoints
- **Backend**: `GET /api/health`
- **Database**: Connection status monitoring
- **Container**: Docker health checks

### Logging
- **Backend**: Morgan HTTP request logging
- **Application**: Console logging for debugging
- **Container**: Docker logs for troubleshooting

## 🧪 Testing & Validation

### Manual Testing
```bash
# Test API health
curl http://localhost:4000/api/health

# Test frontend access
curl http://localhost:5173

# Test database connection
docker-compose exec db psql -U actions -d actions -c "SELECT 1;"
```

### Data Verification
- Check GitHub API rate limits
- Verify repository access permissions
- Test alerting system functionality

## 🔧 Troubleshooting

### Common Issues

#### Container Startup Problems
```bash
# Check container status
docker-compose ps

# View container logs
docker-compose logs api
docker-compose logs web
docker-compose logs db
```

#### Database Connection Issues
```bash
# Test database connectivity
docker-compose exec db psql -U actions -d actions

# Check database logs
docker-compose logs db
```

#### GitHub API Issues
- Verify token permissions
- Check rate limit status
- Validate repository names

### Debug Commands
```bash
# Restart specific service
docker-compose restart api

# Rebuild containers
docker-compose up --build

# Clean up and restart
docker-compose down -v
docker-compose up --build
```

## 📈 Future Enhancements

### Planned Features
- **Multi-provider Support**: Jenkins, GitLab CI, Azure DevOps
- **Advanced Metrics**: Trend analysis, performance insights
- **Custom Dashboards**: User-configurable views
- **API Extensions**: Webhook support, external integrations

### Scalability Improvements
- **Microservices**: Service decomposition
- **Message Queues**: Asynchronous processing
- **Caching**: Redis integration for performance
- **Monitoring**: Prometheus metrics, Grafana dashboards
