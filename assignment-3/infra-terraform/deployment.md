# CI/CD Health Dashboard - AWS Deployment Guide

This guide provides step-by-step instructions for deploying the CI/CD Health Dashboard to AWS using Terraform infrastructure as code.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [AWS Setup](#aws-setup)
3. [Configuration](#configuration)
4. [Deployment Options](#deployment-options)
5. [Manual Deployment Steps](#manual-deployment-steps)
6. [Automated Deployment](#automated-deployment)
7. [Post-Deployment Configuration](#post-deployment-configuration)
8. [Monitoring and Maintenance](#monitoring-and-maintenance)
9. [Troubleshooting](#troubleshooting)
10. [Cleanup](#cleanup)

## Prerequisites

### Required Software

- **Terraform** (>= 1.0): [Download and Install](https://developer.hashicorp.com/terraform/downloads)
- **AWS CLI** (>= 2.0): [Download and Install](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **Docker** (>= 20.0): [Download and Install](https://docs.docker.com/get-docker/)
- **Git**: [Download and Install](https://git-scm.com/downloads)

### Required Accounts and Credentials

- AWS Account with appropriate permissions
- GitHub Personal Access Token
- SSH Key Pair (will be created automatically)

### AWS Permissions Required

Your AWS user/role needs the following permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "rds:*",
                "elasticloadbalancing:*",
                "iam:*",
                "route53:*",
                "acm:*",
                "s3:*",
                "logs:*",
                "cloudwatch:*"
            ],
            "Resource": "*"
        }
    ]
}
```

## AWS Setup

### 1. Configure AWS CLI

```bash
aws configure
```

Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (recommended: `us-west-2`)
- Default output format (recommended: `json`)

### 2. Verify AWS Configuration

```bash
aws sts get-caller-identity
```

This should return your AWS account information.

## Configuration

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd CI-CD-Health-Dashboard/terraform
```

### 2. Create Environment File

Copy the example environment file and configure it:

```bash
cp env.example .env
```

Edit `.env` with your configuration:

```bash
# Database Configuration
DATABASE_ENDPOINT=your-rds-endpoint.amazonaws.com
DATABASE_NAME=actions
DATABASE_USERNAME=actions
DATABASE_PASSWORD=your-secure-password

# GitHub Configuration
GITHUB_TOKEN=ghp_your_github_token_here
GITHUB_REPOS=owner/repo1,owner/repo2
POLL_INTERVAL_SECONDS=60

# Alert Configuration (Optional)
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/your/slack/webhook
ALERT_EMAIL_TO=alerts@yourcompany.com

# SMTP Configuration (Optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=true
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# Frontend Configuration
VITE_API_URL=http://your-alb-dns-name.amazonaws.com
FRONTEND_ORIGIN=http://your-alb-dns-name.amazonaws.com
```

### 3. Create Terraform Variables File (Optional)

Create `terraform.tfvars` to override default variables:

```hcl
aws_region = "us-west-2"
environment = "prod"
project_name = "cicd-dashboard"
instance_type = "t3.medium"
database_password = "your-secure-password"
github_token = "ghp_your_github_token_here"
github_repos = "owner/repo1,owner/repo2"
```

## Deployment Options

### Option 1: Automated Deployment (Recommended)

Use the provided deployment script for a fully automated deployment:

```bash
chmod +x deploy.sh
./deploy.sh
```

The script will:
1. Check dependencies
2. Create AWS key pair
3. Initialize and apply Terraform
4. Build Docker images
5. Deploy the application
6. Display deployment information

### Option 2: Manual Deployment

Follow the manual steps below for more control over the deployment process.

## Manual Deployment Steps

### Step 1: Create SSH Key Pair

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/cicd-dashboard-key.pem -N ""

# Import key pair to AWS
aws ec2 import-key-pair \
    --key-name cicd-dashboard-key \
    --public-key-material fileb://~/.ssh/cicd-dashboard-key.pem.pub

# Set proper permissions
chmod 600 ~/.ssh/cicd-dashboard-key.pem
```

### Step 2: Initialize Terraform

```bash
cd terraform
terraform init
```

### Step 3: Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the plan to ensure all resources will be created as expected.

### Step 4: Apply Infrastructure

```bash
terraform apply tfplan
```

This will create:
- VPC with public and private subnets
- Internet Gateway and NAT Gateways
- RDS PostgreSQL database
- EC2 instance with security groups
- Application Load Balancer
- All necessary networking components

### Step 5: Build Docker Images

```bash
# Build backend image
cd ../backend
docker build -t cicd-dashboard-api:latest .
cd ../terraform

# Build frontend image
cd ../frontend
docker build -t cicd-dashboard-web:latest .
cd ../terraform
```

### Step 6: Deploy Application to EC2

```bash
# Get EC2 instance details
INSTANCE_IP=$(terraform output -raw ec2_public_ip)
ALB_DNS=$(terraform output -raw alb_dns_name)

# Copy application files
scp -i ~/.ssh/cicd-dashboard-key.pem -o StrictHostKeyChecking=no -r ../backend ../frontend ec2-user@$INSTANCE_IP:/home/ec2-user/cicd-dashboard/

# Copy production docker-compose file
scp -i ~/.ssh/cicd-dashboard-key.pem -o StrictHostKeyChecking=no docker-compose.prod.yml ec2-user@$INSTANCE_IP:/home/ec2-user/cicd-dashboard/docker-compose.yml

# Copy environment file
scp -i ~/.ssh/cicd-dashboard-key.pem -o StrictHostKeyChecking=no .env ec2-user@$INSTANCE_IP:/home/ec2-user/cicd-dashboard/

# Deploy application
ssh -i ~/.ssh/cicd-dashboard-key.pem -o StrictHostKeyChecking=no ec2-user@$INSTANCE_IP << 'EOF'
    cd /home/ec2-user/cicd-dashboard
    docker-compose down || true
    docker-compose build
    docker-compose up -d
    sleep 30
    curl -f http://localhost:80 || echo "Health check failed"
EOF
```

## Automated Deployment

### Using the Deployment Script

The `deploy.sh` script automates the entire deployment process:

```bash
chmod +x deploy.sh
./deploy.sh
```

### Script Features

- Dependency checking
- AWS credential verification
- Automatic key pair creation
- Terraform initialization and application
- Docker image building
- Application deployment
- Health checks
- Deployment information display

## Post-Deployment Configuration

### 1. Verify Deployment

Check the deployment outputs:

```bash
terraform output
```

### 2. Access the Application

Get the application URL:

```bash
terraform output application_url
```

### 3. Configure GitHub Integration

1. Go to GitHub Settings > Developer settings > Personal access tokens
2. Generate a new token with `repo` and `workflow` permissions
3. Update the `.env` file on the EC2 instance with the token
4. Restart the application:

```bash
ssh -i ~/.ssh/cicd-dashboard-key.pem ec2-user@$(terraform output -raw ec2_public_ip) << 'EOF'
    cd /home/ec2-user/cicd-dashboard
    docker-compose restart api
EOF
```

### 4. Configure Repository Monitoring

Update the `GITHUB_REPOS` environment variable with your repositories:

```bash
ssh -i ~/.ssh/cicd-dashboard-key.pem ec2-user@$(terraform output -raw ec2_public_ip) << 'EOF'
    cd /home/ec2-user/cicd-dashboard
    # Edit .env file to add your repositories
    nano .env
    docker-compose restart api
EOF
```

### 5. Set Up Monitoring and Alerts (Optional)

#### CloudWatch Logs

The application logs are automatically sent to CloudWatch. You can view them in the AWS Console.

#### Slack Notifications

1. Create a Slack webhook URL
2. Update the `SLACK_WEBHOOK_URL` in the `.env` file
3. Restart the API service

#### Email Notifications

1. Configure SMTP settings in the `.env` file
2. Restart the API service

## Monitoring and Maintenance

### Application Health Checks

```bash
# Check application status
curl -f http://$(terraform output -raw alb_dns_name)

# Check individual services
ssh -i ~/.ssh/cicd-dashboard-key.pem ec2-user@$(terraform output -raw ec2_public_ip) << 'EOF'
    docker-compose ps
    docker-compose logs --tail=50
EOF
```

### Database Maintenance

```bash
# Connect to RDS instance
psql -h $(terraform output -raw rds_endpoint) -U actions -d actions

# Check database size
SELECT pg_size_pretty(pg_database_size('actions'));
```

### Backup and Recovery

#### Database Backups

RDS automatically creates daily backups. Manual backup:

```bash
aws rds create-db-snapshot \
    --db-instance-identifier $(terraform output -raw rds_endpoint | cut -d'.' -f1) \
    --db-snapshot-identifier cicd-dashboard-backup-$(date +%Y%m%d)
```

#### Application Data Backup

```bash
ssh -i ~/.ssh/cicd-dashboard-key.pem ec2-user@$(terraform output -raw ec2_public_ip) << 'EOF'
    cd /home/ec2-user/cicd-dashboard
    docker-compose exec db pg_dump -U actions actions > backup_$(date +%Y%m%d).sql
EOF
```

### Scaling

#### Vertical Scaling

Update the EC2 instance type in `terraform.tfvars`:

```hcl
instance_type = "t3.large"  # or larger
```

Then apply:

```bash
terraform plan -var-file=terraform.tfvars
terraform apply
```

#### Horizontal Scaling

For horizontal scaling, consider:
1. Using ECS with Application Load Balancer
2. Implementing auto-scaling groups
3. Using RDS read replicas

### Updates and Maintenance

#### Application Updates

```bash
# Pull latest changes
git pull origin main

# Rebuild and redeploy
./deploy.sh
```

#### Infrastructure Updates

```bash
# Update Terraform configuration
terraform plan
terraform apply
```

## Troubleshooting

### Common Issues

#### 1. Terraform Apply Fails

**Issue**: Terraform fails to apply due to resource conflicts.

**Solution**:
```bash
# Check existing resources
aws ec2 describe-instances --filters "Name=tag:Project,Values=cicd-dashboard"
aws rds describe-db-instances --db-instance-identifier cicd-dashboard-prod-postgres

# Clean up if needed
terraform destroy
```

#### 2. EC2 Instance Not Accessible

**Issue**: Cannot SSH to EC2 instance.

**Solution**:
```bash
# Check security group rules
aws ec2 describe-security-groups --group-names cicd-dashboard-prod-ec2-sg

# Check instance status
aws ec2 describe-instances --instance-ids $(terraform output -raw ec2_instance_id)
```

#### 3. Application Not Starting

**Issue**: Docker containers fail to start.

**Solution**:
```bash
# Check logs
ssh -i ~/.ssh/cicd-dashboard-key.pem ec2-user@$(terraform output -raw ec2_public_ip) << 'EOF'
    cd /home/ec2-user/cicd-dashboard
    docker-compose logs
    docker-compose ps
EOF
```

#### 4. Database Connection Issues

**Issue**: Application cannot connect to RDS.

**Solution**:
```bash
# Check RDS status
aws rds describe-db-instances --db-instance-identifier cicd-dashboard-prod-postgres

# Check security groups
aws ec2 describe-security-groups --group-names cicd-dashboard-prod-rds-sg
```

#### 5. Load Balancer Health Check Failures

**Issue**: ALB health checks fail.

**Solution**:
```bash
# Check target group health
aws elbv2 describe-target-health --target-group-arn $(terraform output -raw target_group_arn)

# Check EC2 instance
curl -f http://$(terraform output -raw ec2_public_ip)
```

### Log Analysis

#### Application Logs

```bash
# View application logs
ssh -i ~/.ssh/cicd-dashboard-key.pem ec2-user@$(terraform output -raw ec2_public_ip) << 'EOF'
    cd /home/ec2-user/cicd-dashboard
    docker-compose logs api
    docker-compose logs web
    docker-compose logs db
EOF
```

#### System Logs

```bash
# View system logs
ssh -i ~/.ssh/cicd-dashboard-key.pem ec2-user@$(terraform output -raw ec2_public_ip) << 'EOF'
    sudo journalctl -u cicd-dashboard.service -f
    sudo journalctl -u docker.service -f
EOF
```

#### CloudWatch Logs

Access CloudWatch logs in the AWS Console:
1. Go to CloudWatch > Log groups
2. Find logs for your application
3. View and filter logs

### Performance Optimization

#### Database Optimization

```sql
-- Check slow queries
SELECT query, mean_exec_time, calls 
FROM pg_stat_statements 
ORDER BY mean_exec_time DESC 
LIMIT 10;

-- Check index usage
SELECT schemaname, tablename, indexname, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes;
```

#### Application Optimization

```bash
# Monitor resource usage
ssh -i ~/.ssh/cicd-dashboard-key.pem ec2-user@$(terraform output -raw ec2_public_ip) << 'EOF'
    htop
    iotop
    docker stats
EOF
```

## Cleanup

### Destroy Infrastructure

To completely remove all AWS resources:

```bash
# Destroy Terraform-managed resources
terraform destroy

# Remove SSH key pair
aws ec2 delete-key-pair --key-name cicd-dashboard-key

# Remove local files
rm -f ~/.ssh/cicd-dashboard-key.pem*
rm -f terraform.tfstate*
rm -f tfplan
```

### Partial Cleanup

To remove specific components:

```bash
# Remove only EC2 instance
terraform destroy -target=module.ec2

# Remove only RDS
terraform destroy -target=module.rds

# Remove only ALB
terraform destroy -target=module.alb
```

## Security Considerations

### Network Security

- VPC with private subnets for database
- Security groups with minimal required access
- NAT gateways for outbound internet access
- No direct internet access to database

### Application Security

- Environment variables for sensitive data
- Regular security updates
- Monitoring and alerting
- Backup and disaster recovery

### Access Control

- IAM roles with minimal permissions
- SSH key-based authentication
- Regular key rotation
- Multi-factor authentication for AWS Console

## Cost Optimization

### Estimated Monthly Costs (us-west-2)

- **EC2 t3.medium**: ~$30
- **RDS db.t3.micro**: ~$15
- **ALB**: ~$20
- **NAT Gateway**: ~$45
- **Data Transfer**: ~$10
- **Total**: ~$120/month

### Cost Optimization Tips

1. Use smaller instance types for development
2. Schedule RDS instances to stop during non-business hours
3. Use Spot instances for non-critical workloads
4. Monitor and optimize data transfer
5. Use S3 for static assets
6. Implement auto-scaling for variable workloads

## Support and Documentation

### Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

### Getting Help

1. Check the troubleshooting section above
2. Review AWS CloudWatch logs
3. Check application logs on EC2 instance
4. Verify all environment variables are set correctly
5. Ensure all required AWS permissions are granted

---

**Note**: This deployment creates AWS resources that will incur costs. Monitor your AWS billing dashboard and implement appropriate cost controls.
