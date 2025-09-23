#!/bin/bash

# CI/CD Health Dashboard AWS Deployment Script
# This script deploys the infrastructure and application to AWS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    print_success "All dependencies are installed"
}

# Check AWS credentials
check_aws_credentials() {
    print_status "Checking AWS credentials..."
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "AWS credentials are configured"
}

# Create key pair if it doesn't exist
create_key_pair() {
    print_status "Creating AWS key pair..."
    
    KEY_NAME="cicd-dashboard-key"
    
    if aws ec2 describe-key-pairs --key-names "$KEY_NAME" &> /dev/null; then
        print_warning "Key pair $KEY_NAME already exists"
    else
        if [ ! -f ~/.ssh/$KEY_NAME.pem ]; then
            print_status "Generating new SSH key pair..."
            ssh-keygen -t rsa -b 4096 -f ~/.ssh/$KEY_NAME.pem -N ""
        fi
        
        aws ec2 import-key-pair --key-name "$KEY_NAME" --public-key-material fileb://~/.ssh/$KEY_NAME.pem.pub
        print_success "Key pair $KEY_NAME created"
    fi
    
    chmod 600 ~/.ssh/$KEY_NAME.pem
}

# Initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    terraform init
    print_success "Terraform initialized"
}

# Plan Terraform deployment
plan_terraform() {
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    print_success "Terraform plan created"
}

# Apply Terraform deployment
apply_terraform() {
    print_status "Applying Terraform deployment..."
    terraform apply tfplan
    print_success "Terraform deployment completed"
}

# Build and push Docker images
build_images() {
    print_status "Building Docker images..."
    
    # Build backend image
    print_status "Building backend image..."
    cd ../backend
    docker build -t cicd-dashboard-api:latest .
    cd ../terraform
    
    # Build frontend image
    print_status "Building frontend image..."
    cd ../frontend
    docker build -t cicd-dashboard-web:latest .
    cd ../terraform
    
    print_success "Docker images built successfully"
}

# Deploy application to EC2
deploy_application() {
    print_status "Deploying application to EC2..."
    
    # Get EC2 instance details
    INSTANCE_IP=$(terraform output -raw ec2_public_ip)
    ALB_DNS=$(terraform output -raw alb_dns_name)
    
    print_status "EC2 Instance IP: $INSTANCE_IP"
    print_status "ALB DNS Name: $ALB_DNS"
    
    # Wait for instance to be ready
    print_status "Waiting for EC2 instance to be ready..."
    sleep 60
    
    # Copy application files
    print_status "Copying application files to EC2..."
    scp -i ~/.ssh/cicd-dashboard-key.pem -o StrictHostKeyChecking=no -r ../backend ../frontend ec2-user@$INSTANCE_IP:/home/ec2-user/cicd-dashboard/
    
    # Copy production docker-compose file
    scp -i ~/.ssh/cicd-dashboard-key.pem -o StrictHostKeyChecking=no docker-compose.prod.yml ec2-user@$INSTANCE_IP:/home/ec2-user/cicd-dashboard/docker-compose.yml
    
    # Copy environment file
    if [ -f .env ]; then
        scp -i ~/.ssh/cicd-dashboard-key.pem -o StrictHostKeyChecking=no .env ec2-user@$INSTANCE_IP:/home/ec2-user/cicd-dashboard/
    else
        print_warning "No .env file found. Please create one based on env.example"
    fi
    
    # Deploy application
    print_status "Deploying application on EC2..."
    ssh -i ~/.ssh/cicd-dashboard-key.pem -o StrictHostKeyChecking=no ec2-user@$INSTANCE_IP << 'EOF'
        cd /home/ec2-user/cicd-dashboard
        
        # Set environment variables
        export DATABASE_ENDPOINT=$(terraform output -raw rds_endpoint 2>/dev/null || echo "localhost")
        export ALB_DNS_NAME=$(terraform output -raw alb_dns_name 2>/dev/null || echo "localhost")
        
        # Deploy with docker-compose
        docker-compose down || true
        docker-compose build
        docker-compose up -d
        
        # Wait for services to be ready
        sleep 30
        
        # Health check
        if curl -f http://localhost:80 > /dev/null 2>&1; then
            echo "Application deployed successfully!"
        else
            echo "Application deployment failed!"
            exit 1
        fi
EOF
    
    print_success "Application deployed successfully"
}

# Display deployment information
show_deployment_info() {
    print_success "Deployment completed successfully!"
    echo ""
    echo "=============================================="
    echo "DEPLOYMENT INFORMATION"
    echo "=============================================="
    echo ""
    echo "Application URL: $(terraform output -raw application_url)"
    echo "ALB DNS Name: $(terraform output -raw alb_dns_name)"
    echo "EC2 Public IP: $(terraform output -raw ec2_public_ip)"
    echo "RDS Endpoint: $(terraform output -raw rds_endpoint)"
    echo ""
    echo "SSH Command: $(terraform output -raw ssh_command)"
    echo ""
    echo "=============================================="
    echo "NEXT STEPS"
    echo "=============================================="
    echo "1. Configure your GitHub token and repositories in the .env file"
    echo "2. Set up Slack webhook URL for notifications (optional)"
    echo "3. Configure email alerts (optional)"
    echo "4. Access your dashboard at the Application URL above"
    echo ""
}

# Main deployment function
main() {
    print_status "Starting CI/CD Health Dashboard deployment..."
    echo ""
    
    # Check dependencies
    check_dependencies
    check_aws_credentials
    
    # Create key pair
    create_key_pair
    
    # Initialize and deploy Terraform
    init_terraform
    plan_terraform
    
    # Ask for confirmation
    echo ""
    print_warning "This will create AWS resources and may incur costs."
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        apply_terraform
        
        # Build and deploy application
        build_images
        deploy_application
        
        # Show deployment info
        show_deployment_info
    else
        print_status "Deployment cancelled by user"
        exit 0
    fi
}

# Run main function
main "$@"
