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

variable "domain_prefix" {
  description = "Domain prefix for environment-specific URLs"
  type        = string
  default     = "sky-high-booker"
}

variable "base_domain" {
  description = "Base domain for Route53 (e.g., sctp-sandbox.com)"
  type        = string
  default     = "sctp-sandbox.com"
}
