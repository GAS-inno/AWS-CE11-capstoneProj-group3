# ECR Repository for Sky High Booker Application
# Common locals for ECR module
locals {
  ecr_common_tags = {
    Environment = var.environment
    Project     = "SkyHighBooker"
    ManagedBy   = "Terraform"
  }
}

# ECR Repository for the application
resource "aws_ecr_repository" "sky_high_booker" {
  name                 = "${var.name_prefix}sky-high-booker"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(local.ecr_common_tags, {
    Name = "${var.name_prefix}sky-high-booker-repo"
  })
}

# ECR Lifecycle Policy to manage image retention
resource "aws_ecr_lifecycle_policy" "sky_high_booker" {
  repository = aws_ecr_repository.sky_high_booker.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "latest", "main", "prod"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Data sources are defined in main.tf