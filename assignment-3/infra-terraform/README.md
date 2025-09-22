# CI/CD Health Dashboard - AWS Deployment

This directory contains the complete Terraform infrastructure code for deploying the CI/CD Health Dashboard to AWS.

## 📁 Project Structure

```
terraform/
├── main.tf                     # Main Terraform configuration
├── variables.tf                # Input variables
├── outputs.tf                  # Output values
├── deployment.md               # Comprehensive deployment guide
├── prompts.md                  # AI prompts and development log
├── deploy.sh                   # Automated deployment script
├── docker-compose.prod.yml     # Production Docker Compose file
├── env.example                 # Environment variables template
└── modules/                    # Terraform modules
    ├── vpc/                    # VPC and networking
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── rds/                    # RDS PostgreSQL database
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── ec2/                    # EC2 instance and application
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── user_data.sh
    └── alb/                    # Application Load Balancer
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform (>= 1.0)
- Docker
- SSH key pair

### Automated Deployment
```bash
# 1. Configure your environment
cp env.example .env
# Edit .env with your configuration

# 2. Run automated deployment
chmod +x deploy.sh
./deploy.sh
```

### Manual Deployment
```bash
# 1. Initialize Terraform
terraform init

# 2. Plan deployment
terraform plan

# 3. Apply infrastructure
terraform apply

# 4. Deploy application (see deployment.md for details)
```

## 🏗️ Infrastructure Components

### VPC Module
- **VPC**: `10.0.0.0/16` CIDR block
- **Subnets**: Public and private subnets across multiple AZs
- **Gateways**: Internet Gateway and NAT Gateways
- **Routing**: Proper route tables and associations

### RDS Module
- **Database**: PostgreSQL 15.4
- **Security**: Private subnets with security groups
- **Backup**: Automated backups and point-in-time recovery
- **Monitoring**: Performance insights and CloudWatch integration

### EC2 Module
- **Instance**: Amazon Linux 2 with Docker
- **Security**: SSH and HTTP access via security groups
- **IAM**: Role with minimal required permissions
- **User Data**: Automated Docker installation and app deployment

### ALB Module
- **Load Balancer**: Application Load Balancer in public subnets
- **Health Checks**: HTTP health checks with proper thresholds
- **Listeners**: HTTP (80) and optional HTTPS (443) listeners
- **Target Groups**: EC2 instance registration

## 🔧 Configuration

### Required Variables
- `github_token`: GitHub Personal Access Token
- `github_repos`: Comma-separated list of repositories
- `database_password`: Secure database password

### Optional Variables
- `aws_region`: AWS region (default: us-west-2)
- `instance_type`: EC2 instance type (default: t3.medium)
- `environment`: Environment name (default: prod)

## 📊 Estimated Costs

**Monthly Cost (us-west-2)**: ~$120
- EC2 t3.medium: ~$30
- RDS db.t3.micro: ~$15
- ALB: ~$20
- NAT Gateways: ~$45
- Data Transfer: ~$10

## 🔒 Security Features

- **Network Isolation**: Private subnets for database
- **Security Groups**: Minimal required access
- **Encryption**: At-rest encryption for all storage
- **IAM Roles**: Least privilege access
- **No Direct DB Access**: Database only accessible from EC2

## 📚 Documentation

- **[deployment.md](deployment.md)**: Comprehensive deployment guide
- **[prompts.md](prompts.md)**: AI prompts and development log
- **[env.example](env.example)**: Environment variables template

## 🔍 Monitoring

### Health Checks
- Application Load Balancer health checks
- Docker container status monitoring
- Database connectivity verification

### Logging
- CloudWatch integration
- Docker container logs
- System logs via journalctl

## 🛠️ Maintenance

### Updates
```bash
# Pull latest changes
git pull origin main

# Rebuild and redeploy
./deploy.sh
```

### Scaling
```bash
# Vertical scaling
# Update instance_type in terraform.tfvars
terraform plan -var-file=terraform.tfvars
terraform apply
```

### Backup
```bash
# Database backup
aws rds create-db-snapshot \
  --db-instance-identifier cicd-dashboard-prod-postgres \
  --db-snapshot-identifier backup-$(date +%Y%m%d)
```

## 🧹 Cleanup

```bash
# Destroy all resources
terraform destroy

# Remove SSH key
aws ec2 delete-key-pair --key-name cicd-dashboard-key
```

## 🆘 Troubleshooting

Common issues and solutions are documented in [deployment.md](deployment.md#troubleshooting).

### Quick Debug Commands
```bash
# Check application status
curl -f http://$(terraform output -raw alb_dns_name)

# SSH to EC2 instance
ssh -i ~/.ssh/cicd-dashboard-key.pem ec2-user@$(terraform output -raw ec2_public_ip)

# Check Docker containers
docker-compose ps
docker-compose logs
```

## 🚀 Access Your Application

After deployment, your application will be available at:
```
http://$(terraform output -raw alb_dns_name)
```

## 📞 Support

For issues and questions:
1. Check the troubleshooting section in deployment.md
2. Review application logs on EC2 instance
3. Verify all environment variables are configured
4. Ensure AWS permissions are properly set

---

**Created**: December 2024  
**Version**: 1.0  
**Infrastructure**: Terraform + AWS
