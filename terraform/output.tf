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
  value       = "ce11g3.tfstate"
}

# ==============================================
# Network Infrastructure Outputs
# ==============================================

# VPC & Network Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = try(aws_vpc.main.id, "vpc_not_created")
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = try(aws_vpc.main.cidr_block, "cidr_not_available")
}

output "public_subnet_ids" {
  description = "Public subnets used by ECS"
  value       = try(aws_subnet.public[*].id, [])
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
  value       = var.enable_ecs ? aws_ecs_cluster.main[0].id : "ecs_not_enabled"
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = var.enable_ecs ? aws_ecs_cluster.main[0].name : "ecs_not_enabled"
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = var.enable_ecs ? aws_ecs_cluster.main[0].arn : "ecs_not_enabled"
}

output "ecs_service_id" {
  description = "ECS service ID"
  value       = var.enable_ecs ? try(aws_ecs_service.app[0].id, "service_not_created") : "ecs_not_enabled"
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = var.enable_ecs ? try(aws_ecs_service.app[0].name, "sky-high-booker") : "ecs_not_enabled"
}

# ==============================================
# Load Balancer Outputs (Conditional)
# ==============================================

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = var.enable_ecs ? try(aws_lb.main[0].dns_name, "alb_not_created") : "ecs_not_enabled"
}

output "alb_arn" {
  description = "Application Load Balancer ARN"
  value       = var.enable_ecs ? try(aws_lb.main[0].arn, "alb_not_created") : "ecs_not_enabled"
}

output "alb_zone_id" {
  description = "Application Load Balancer hosted zone ID"
  value       = var.enable_ecs ? try(aws_lb.main[0].zone_id, "alb_not_created") : "ecs_not_enabled"
}

output "target_group_arn" {
  description = "Target group ARN for ECS service"
  value       = var.enable_ecs ? try(aws_lb_target_group.ecs[0].arn, "target_group_not_created") : "ecs_not_enabled"
}

# ==============================================
# Security Groups Outputs
# ==============================================

output "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = try(aws_security_group.ecs_tasks.id, "sg_not_created")
}

output "alb_security_group_id" {
  description = "Security group ID for ALB"
  value       = try(aws_security_group.alb.id, "sg_not_created")
}

# ==============================================
# Application Access Outputs
# ==============================================

output "application_url" {
  description = "Sky High Booker application URL"
  value       = var.enable_ecs ? try("http://${aws_lb.main[0].dns_name}", "Application URL not available") : "ecs_not_enabled"
}

output "health_check_url" {
  description = "Application health check endpoint"
  value       = var.enable_ecs ? try("http://${aws_lb.main[0].dns_name}/", "Health check URL not available") : "ecs_not_enabled"
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
  value = var.enable_ecs ? {
    cluster_name    = aws_ecs_cluster.main[0].name
    service_name    = try(aws_ecs_service.app[0].name, "sky-high-booker")
    task_definition = try(aws_ecs_task_definition.app[0].arn, "task_not_created")
    desired_count   = try(aws_ecs_service.app[0].desired_count, 1)
    cpu             = "512"
    memory          = "1024"
  } : {
    cluster_name    = "ecs_not_enabled"
    service_name    = "ecs_not_enabled"
    task_definition = "ecs_not_enabled"
    desired_count   = 0
    cpu             = "0"
    memory          = "0"
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

output "dynamodb_tables" {
  description = "DynamoDB table names"
  value = {
    bookings = aws_dynamodb_table.bookings.name
  }
}

output "aws_environment_variables" {
  description = "Environment variables for AWS services"
  value = {
    VITE_AWS_REGION              = data.aws_region.current.name
    VITE_AWS_USER_POOL_ID        = aws_cognito_user_pool.user_pool.id
    VITE_AWS_USER_POOL_CLIENT_ID = aws_cognito_user_pool_client.user_pool_client.id
    VITE_AWS_API_GATEWAY_URL     = "https://${aws_api_gateway_rest_api.booking_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/prod"
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

# ==============================================
# Route 53 & Domain Outputs
# ==============================================

output "app_domain_name" {
  description = "Custom domain name for the application"
  value       = "sky-high-booker.sctp-sandbox.com"
}

output "app_domain_url" {
  description = "Full HTTPS URL for the application"
  value       = "https://sky-high-booker.sctp-sandbox.com"
}

output "ssl_certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = try(aws_acm_certificate.app_cert.arn, "certificate_not_created")
}