# Modern Terraform Outputs
# Aligned with terraform-aws-modules pattern

# ==============================================
# Backend Infrastructure Outputs
# ==============================================

output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = try(aws_s3_bucket.terraform_state.id, "not_created")
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = try(aws_s3_bucket.terraform_state.arn, "not_created")
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

output "vpc_id" {
  description = "VPC ID being used"
  value       = var.use_default_vpc ? try(data.aws_vpc.selected[0].id, "default_vpc_not_found") : try(aws_vpc.main.id, "custom_vpc_not_created")
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = var.use_default_vpc ? try(data.aws_vpc.selected[0].cidr_block, "default_vpc_not_found") : var.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = data.aws_subnets.public.ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs (if created)"
  value       = var.use_default_vpc ? [] : try(data.aws_subnets.private[0].ids, [])
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
  description = "Application Load Balancer DNS name"
  value       = var.create_alb ? module.alb[0].dns_name : "alb_not_created"
}

output "alb_arn" {
  description = "Application Load Balancer ARN"
  value       = var.create_alb ? module.alb[0].arn : "alb_not_created"
}

output "alb_zone_id" {
  description = "Application Load Balancer hosted zone ID"
  value       = var.create_alb ? module.alb[0].zone_id : "alb_not_created"
}

output "target_group_arn" {
  description = "Target group ARN for ECS service"
  value       = var.create_alb ? module.alb[0].target_groups["ecs-service"].arn : "alb_not_created"
}

# ==============================================
# Security Groups Outputs
# ==============================================

output "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = module.ecs_security_group.security_group_id
}

output "alb_security_group_id" {
  description = "Security group ID for ALB"
  value       = var.create_alb ? module.alb_security_group[0].security_group_id : "alb_not_created"
}

# ==============================================
# Application Access Outputs
# ==============================================

output "application_url" {
  description = "Sky High Booker application URL"
  value = var.create_alb ? "http://${module.alb[0].dns_name}" : "Direct ECS access - no ALB configured"
}

output "health_check_url" {
  description = "Application health check endpoint"
  value = var.create_alb ? "http://${module.alb[0].dns_name}/health" : "Health check via ECS tasks directly"
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
    cluster_name       = module.ecs.cluster_name
    service_name       = try(module.ecs.services["sky-high-booker"].name, "service_not_created")
    task_definition    = try(module.ecs.services["sky-high-booker"].task_definition, "task_not_created")
    desired_count      = var.ecs_desired_count
    cpu                = var.ecs_task_cpu
    memory             = var.ecs_task_memory
  }
}