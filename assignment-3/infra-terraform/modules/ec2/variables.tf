variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Name of the AWS key pair"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name"
  type        = string
}

# Database configuration
variable "database_endpoint" {
  description = "Database endpoint"
  type        = string
}

variable "database_name" {
  description = "Database name"
  type        = string
}

variable "database_username" {
  description = "Database username"
  type        = string
}

variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# Application configuration
variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "github_repos" {
  description = "Comma-separated list of GitHub repositories to monitor"
  type        = string
}

variable "poll_interval" {
  description = "Poll interval in seconds"
  type        = number
}

# Alert configuration
variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  sensitive   = true
}

variable "alert_email_to" {
  description = "Email address for alerts"
  type        = string
}

variable "smtp_host" {
  description = "SMTP host for email alerts"
  type        = string
}

variable "smtp_port" {
  description = "SMTP port for email alerts"
  type        = number
}

variable "smtp_secure" {
  description = "Use secure SMTP connection"
  type        = bool
}

variable "smtp_user" {
  description = "SMTP username"
  type        = string
}

variable "smtp_pass" {
  description = "SMTP password"
  type        = string
  sensitive   = true
}
