variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cicd-dashboard"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of the AWS key pair"
  type        = string
  default     = "cicd-dashboard-key"
}

# Database variables
variable "database_name" {
  description = "Database name"
  type        = string
  default     = "actions"
}

variable "database_username" {
  description = "Database username"
  type        = string
  default     = "actions"
}

variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "your-secure-password-here"
}

# GitHub configuration
variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "github_repos" {
  description = "Comma-separated list of GitHub repositories to monitor"
  type        = string
  default     = "owner/repo1,owner/repo2"
}

variable "poll_interval" {
  description = "Poll interval in seconds"
  type        = number
  default     = 60
}

# Alert configuration
variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  sensitive   = true
  default     = ""
}

variable "alert_email_to" {
  description = "Email address for alerts"
  type        = string
  default     = ""
}

variable "smtp_host" {
  description = "SMTP host for email alerts"
  type        = string
  default     = ""
}

variable "smtp_port" {
  description = "SMTP port for email alerts"
  type        = number
  default     = 587
}

variable "smtp_secure" {
  description = "Use secure SMTP connection"
  type        = bool
  default     = false
}

variable "smtp_user" {
  description = "SMTP username"
  type        = string
  default     = ""
}

variable "smtp_pass" {
  description = "SMTP password"
  type        = string
  sensitive   = true
  default     = ""
}
