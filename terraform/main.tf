terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  availability_zones   = data.aws_availability_zones.available.names
  environment          = var.environment
  project_name         = var.project_name
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  database_name         = var.database_name
  database_username     = var.database_username
  database_password     = var.database_password
  environment           = var.environment
  project_name          = var.project_name
}

# Application Load Balancer Module
module "alb" {
  source = "./modules/alb"

  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  target_group_port   = 80
  environment         = var.environment
  project_name        = var.project_name
}

# EC2 Module
module "ec2" {
  source = "./modules/ec2"

  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  ami_id              = data.aws_ami.amazon_linux.id
  instance_type       = var.instance_type
  key_name            = var.key_name
  environment         = var.environment
  project_name        = var.project_name
  alb_security_group_id = module.alb.security_group_id
  alb_dns_name        = module.alb.alb_dns_name
  
  # Database connection
  database_endpoint   = module.rds.endpoint
  database_name       = var.database_name
  database_username   = var.database_username
  database_password   = var.database_password
  
  # Application configuration
  github_token        = var.github_token
  github_repos        = var.github_repos
  poll_interval       = var.poll_interval
  
  # Alert configuration
  slack_webhook_url   = var.slack_webhook_url
  alert_email_to      = var.alert_email_to
  smtp_host           = var.smtp_host
  smtp_port           = var.smtp_port
  smtp_secure         = var.smtp_secure
  smtp_user           = var.smtp_user
  smtp_pass           = var.smtp_pass
}

# ALB Target Group Attachment
resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = module.alb.target_group_arn
  target_id        = module.ec2.instance_id
  port             = 80
}
