# S3 Bucket for Static Website Hosting

# S3 bucket for hosting the static website
resource "aws_s3_bucket" "website" {
  # Checkov notes:
  # CKV2_AWS_62: Ensure S3 buckets should have event notifications enabled
  # CKV2_AWS_61: Ensure that an S3 bucket has a lifecycle configuration
  # CKV_AWS_144: Ensure that S3 bucket has cross-region replication enabled
  # CKV2_AWS_6: Ensure that S3 bucket has a Public Access block

  bucket        = "${var.name_prefix}sky-high-booker-${var.environment}"
  force_destroy = true

  tags = merge(local.tags, {
    Name = "${var.name_prefix}sky-high-booker-website"
  })
}

# S3 bucket logging (logs stored in the same bucket under logs/ prefix)
resource "aws_s3_bucket_logging" "website" {
  bucket = aws_s3_bucket.website.id

  target_bucket = aws_s3_bucket.website.id
  target_prefix = "logs/"
}

# S3 bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "website" {
  # CKV2_AWS_65: Ensure access control lists for S3 buckets are disabled

  bucket = aws_s3_bucket.website.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Block public access (we'll use CloudFront with OAI instead)
resource "aws_s3_bucket_public_access_block" "website" {
  # CKV_AWS_56: Ensure S3 bucket has Block Public Access enabled
  # CKV_AWS_54: Ensure S3 bucket has block public policy enabled

  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for rollback capability
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CORS configuration for API calls from the website
resource "aws_s3_bucket_cors_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Website configuration
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "website" {
  comment = "OAI for ${var.name_prefix}sky-high-booker-${var.environment}"
}

# S3 bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAI"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.website.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.website
  ]
}
