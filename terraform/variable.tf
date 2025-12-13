variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  type        = string
  description = "name of app"
  default     = "ce11g3-"
}

# DynamoDB variables (tables are created with project_name prefix)
# No additional configuration needed - DynamoDB is serverless

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "sky-high-booker"
}

variable "domain_name" {
  description = "Custom domain name for the application (e.g., sky-high-booker.sctp-sandbox.com)"
  type        = string
  default     = "sky-high-booker.sctp-sandbox.com"
}

variable "discord_webhook_url" {
  description = "Discord webhook URL for SNS notifications"
  type        = string
  sensitive   = true
  default     = ""
}

