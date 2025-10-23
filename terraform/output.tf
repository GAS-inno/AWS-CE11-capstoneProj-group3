# Outputs


# Terraform state S3 bucket details
output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.terraform_lock.arn
}

# VPC ID output
output "vpc_id" {
  value = var.vpc_cidr #aws_vpc.main.id
}
output "public_subnet_id" {
  value = var.public_subnet_1_cidr   
}
output "private_subnet_id" {
  value = var.private_subnet_1_cidr   
}
output "ec2_instance_id" {
  value = aws_instance.web[*].id
}


#bucket website URL
output "bucket_url" {
  value = "http://${aws_s3_bucket.terraform_state.bucket}.s3-website-${var.region}.amazonaws.com/"
}

output "website_url" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
}


# Show the private key file path
output "private_key_path" {
  value = "${path.module}/generated_keys/${var.key_name}"
  description = "Path to the locally generated private SSH key"
}

# Show the key name used in AWS
output "key_name" {
  value = aws_key_pair.generated.key_name
  description = "AWS EC2 key pair name"
}

