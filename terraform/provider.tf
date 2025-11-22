# AWS Provider configuration
provider "aws" {
  region = var.aws_region

  # Optional: Add default tags for all resources
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "SkyHighBooker"
      ManagedBy   = "Terraform"
    }
  }
}

# Terraform configuration
terraform {
  required_version = ">= 1.0.0" # Specify a suitable version constraint

  # S3 Backend for state storage
  backend "s3" {
    bucket = "sctp-ce11-tfstate"
    key    = "ce11g3.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Specify a version relevant to your deployment
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}