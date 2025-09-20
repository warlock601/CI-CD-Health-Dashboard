**Prompt 1**:
```
Given the code for a CICD health dashboard, deploy it to AWS Cloud using terraform IaC.
Create an EC2 instance in Networking basics (VPC + Security Group/Firewall), a managed Database
such as RDS postgres code or whatever is required as per the tech stack. Then Use Terraform to install Docker + deploy
your containerized app and App should be accessible via a public URL/IP. Provide all the terraform code
in a modularized way like ec2, vpc (include subnets etc inside this only), rds etc.

```

**Analysis Performed**:
1. Examined the existing codebase structure
2. Identified application dependencies (PostgreSQL, Node.js, React)
3. Analyzed Docker configuration
4. Understood the application architecture and requirements

**Key Findings**:
- Backend uses PostgreSQL database with connection pooling
- Frontend is a React SPA built with Vite
- Application requires GitHub API access for CI/CD monitoring
- Docker Compose setup for local development
- Environment variables for configuration

---
