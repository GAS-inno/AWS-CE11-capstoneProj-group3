# Simplified Main Configuration

locals {
  prefix = "${var.project_name}-${var.environment}" # e.g., "sky-high-booker-dev" or "sky-high-booker-prod"

  # Tags for AWS resources
  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Data sources for AWS account and region info
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}