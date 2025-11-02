# Simplified Main Configuration 
# Based on jaezeu/ecs-deployment reference

locals {
  prefix = "sky-high-booker-dev"  # Simplified prefix like the reference

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