# Modern Terraform Outputs
# Aligned with terraform-aws-modules pattern

# ==============================================
# Backend Infrastructure Outputs
# ==============================================

# S3 Backend State Bucket Info
output "s3_backend_bucket" {
  description = "S3 bucket used for Terraform state"
  value       = "sctp-ce11-tfstate"
}

output "s3_backend_key" {
  description = "S3 key path for Terraform state"
  value       = "sky-high-booker/terraform.tfstate"
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = try(aws_dynamodb_table.terraform_lock.name, "not_created")
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for state locking"
  value       = try(aws_dynamodb_table.terraform_lock.arn, "not_created")
}

# ==============================================
# Network Infrastructure Outputs
# ==============================================

# VPC & Network Outputs (using default VPC)
output "vpc_id" {
  description = "ID of the default VPC"
  value       = "Using default VPC - see ECS outputs for actual VPC ID"
}

output "vpc_cidr" {
  description = "CIDR block of the default VPC"
  value       = "Default VPC - see ECS outputs for actual CIDR"
}

output "public_subnet_ids" {
  description = "Default subnets used by ECS"
  value       = "Default subnets - see ECS outputs for actual subnet IDs"
}

output "private_subnet_ids" {
  description = "Private subnets (not used in simplified config)"
  value       = []
}

# ==============================================
# Container Infrastructure Outputs  
# ==============================================

output "ecr_repository_url" {
  description = "ECR repository URL for Sky High Booker"
  value       = aws_ecr_repository.sky_high_booker.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.sky_high_booker.arn
}

output "ecs_cluster_id" {
  description = "ECS cluster ID"
  value       = module.ecs.cluster_id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = module.ecs.cluster_arn
}

output "ecs_service_id" {
  description = "ECS service ID"
  value       = try(module.ecs.services["sky-high-booker"].id, "service_not_created")
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = try(module.ecs.services["sky-high-booker"].name, "service_not_created")
}

# ==============================================
# Load Balancer Outputs (Conditional)
# ==============================================

output "alb_dns_name" {
  description = "Application Load Balancer DNS name (from ECS module)"
  value       = try(module.ecs.load_balancer_dns_name, "alb_not_created")
}

output "alb_arn" {
  description = "Application Load Balancer ARN (from ECS module)"
  value       = try(module.ecs.load_balancer_arn, "alb_not_created")
}

output "alb_zone_id" {
  description = "Application Load Balancer hosted zone ID (from ECS module)"
  value       = try(module.ecs.load_balancer_zone_id, "alb_not_created")
}

output "target_group_arn" {
  description = "Target group ARN for ECS service (from ECS module)"
  value       = try(module.ecs.target_group_arns[0], "target_group_not_created")
}

# ==============================================
# Security Groups Outputs
# ==============================================

output "ecs_security_group_id" {
  description = "Security group ID for ECS tasks (from ECS module)"
  value       = try(module.ecs.service_security_group_id, "sg_not_created")
}

output "alb_security_group_id" {
  description = "Security group ID for ALB (from ECS module)"
  value       = try(module.ecs.load_balancer_security_group_id, "sg_not_created")
}

# ==============================================
# Application Access Outputs
# ==============================================

output "application_url" {
  description = "Sky High Booker application URL"
  value       = try("http://${module.ecs.load_balancer_dns_name}", "Application URL not available")
}

output "health_check_url" {
  description = "Application health check endpoint"
  value       = try("http://${module.ecs.load_balancer_dns_name}/health", "Health check URL not available")
}

# ==============================================
# Environment Information
# ==============================================

output "aws_region" {
  description = "AWS region used for deployment"
  value       = data.aws_region.current.name
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "name_prefix" {
  description = "Name prefix used for resources"
  value       = var.name_prefix
}

# ==============================================
# Quick Deploy Commands
# ==============================================

output "docker_push_commands" {
  description = "Commands to build and push Docker image to ECR"
  value = [
    "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${aws_ecr_repository.sky_high_booker.repository_url}",
    "docker build -t sky-high-booker .",
    "docker tag sky-high-booker:latest ${aws_ecr_repository.sky_high_booker.repository_url}:latest",
    "docker push ${aws_ecr_repository.sky_high_booker.repository_url}:latest"
  ]
}

output "ecs_deployment_info" {
  description = "ECS deployment information"
  value = {
    cluster_name    = module.ecs.cluster_name
    service_name    = try(module.ecs.services["sky-high-booker"].name, "service_not_created")
    task_definition = try(module.ecs.services["sky-high-booker"].task_definition, "task_not_created")
    desired_count   = var.ecs_desired_count
    cpu             = var.ecs_task_cpu
    memory          = var.ecs_task_memory
  }
}

# ==============================================
# AWS Services Outputs for Application
# ==============================================

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID for authentication"
  value       = aws_cognito_user_pool.user_pool.id
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID for authentication"
  value       = aws_cognito_user_pool_client.user_pool_client.id
}

output "api_gateway_url" {
  description = "API Gateway URL for backend API"
  value       = "https://${aws_api_gateway_rest_api.booking_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/prod"
}

output "app_s3_bucket_name" {
  description = "S3 bucket name for application file storage"
  value       = aws_s3_bucket.app_storage.id
}

output "dynamodb_tables" {
  description = "DynamoDB table names"
  value = {
    flights   = aws_dynamodb_table.flights.name
    bookings  = aws_dynamodb_table.bookings.name
    payments  = aws_dynamodb_table.payments.name
  }
}

output "aws_environment_variables" {
  description = "Environment variables for AWS services"
  value = {
    VITE_AWS_REGION                = data.aws_region.current.name
    VITE_AWS_USER_POOL_ID         = aws_cognito_user_pool.user_pool.id
    VITE_AWS_USER_POOL_CLIENT_ID  = aws_cognito_user_pool_client.user_pool_client.id
    VITE_AWS_API_GATEWAY_URL      = "https://${aws_api_gateway_rest_api.booking_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/prod"
    VITE_AWS_S3_BUCKET           = aws_s3_bucket.app_storage.id
  }
}

output "cognito_identity_pool_id" {
  description = "ID of the Cognito Identity Pool"
  value       = try(aws_cognito_identity_pool.identity_pool.id, "identity_pool_not_created")
}

output "dynamodb_region" {
  description = "AWS region for DynamoDB tables"
  value       = data.aws_region.current.name
}