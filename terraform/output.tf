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
# Static Website Infrastructure Outputs  
# ==============================================

output "s3_bucket_name" {
  description = "S3 bucket name for static website hosting"
  value       = aws_s3_bucket.website.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.website.arn
}

output "s3_bucket_website_endpoint" {
  description = "S3 bucket website endpoint"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "cloudfront_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.website.arn
}

output "cloudfront_url" {
  description = "CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.website.domain_name}"
}

# ==============================================
# Application Access Outputs
# ==============================================

output "application_url" {
  description = "Sky High Booker application URL"
  value       = "https://${local.full_domain_name}"
}

output "website_endpoint" {
  description = "Primary website endpoint"
  value       = "https://${local.full_domain_name}"
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

output "deployment_commands" {
  description = "Commands to deploy the application to S3"
  value = [
    "# Build the application:",
    "npm ci",
    "npm run build",
    "",
    "# Upload to S3:",
    "aws s3 sync ./dist s3://${aws_s3_bucket.website.id}/ --delete",
    "",
    "# Invalidate CloudFront cache:",
    "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.website.id} --paths '/*'"
  ]
}

output "quick_deploy_script" {
  description = "Quick deployment script path"
  value       = "Deploy frontend: npm run build then upload to S3"
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
  value       = local.full_domain_name
}

output "app_domain_url" {
  description = "Full HTTPS URL for the application"
  value       = "https://${local.full_domain_name}"
}

output "ssl_certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = aws_acm_certificate.website.arn
}