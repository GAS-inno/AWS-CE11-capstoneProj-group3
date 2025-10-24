variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

locals {
  policy_name = "saw-policy-${var.environment}"
}

resource "aws_iam_policy" "ec2_secrets_policy" {
  name        = local.policy_name
  description = "ec2_secrets_policy IAM policy for ${var.environment} environment"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [ "secretsmanager:GetSecretValue"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

