# This file creates the S3 bucket and DynamoDB table for Terraform state
# Run this FIRST before applying the main infrastructure
# After creation, uncomment the backend configuration in main.tf


# main.tf can stay empty for now
# Terraform automatically loads vpc.tf, ec2.tf, security_group.tf, variables.tf, outputs.tf


# terraform {
#   required_version = ">= 1.0"
  
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 5.0"
#     }
#   }
# }

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

