# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  //bucket = var.state_bucket_name
  bucket = "${var.name_prefix}s3.sctp-sandbox.com"  # CHANGE THIS to a unique name
  force_destroy = true

  #lifecycle {
   # prevent_destroy = true
  #}

#  tags = {
#    Name        = "CE11 G3 Terraform State Bucket"
#    Environment = "All"
#  }
}


# Upload HTML files from static-website directory
# =============================
locals {
  website_files = fileset("${path.module}/static-website", "**/*")

  # Compute hash of all files to trigger sync when anything changes
  website_hash = md5(join("", [for f in local.website_files : filemd5("${path.module}/static-website/${f}")]))
}

resource "null_resource" "sync_website" {
  triggers = {
    website_hash = local.website_hash
  }

  provisioner "local-exec" {
    command = <<EOT
      aws s3 sync ${path.module}/static-website s3://saw-s3.sctp-sandbox.com \
        --exclude "*.MD" \
        --exclude ".git*" \
        
    EOT
  }
}
# locals {
#   website_files = fileset("${path.module}/static-website", "**/*")

#   filtered_files = [
#     for f in local.website_files : f
#     if length(regexall("^\\.git", f)) == 0 && length(regexall("^\\.", basename(f))) == 0
#   ]
# }


# resource "aws_s3_object" "website_files" {
#   for_each = { for file in local.website_files : file => file }

#   bucket       = aws_s3_bucket.terraform_state.id
#   key          = each.value
#   source       = "${path.module}/static-website/${each.value}"
#   etag         = filemd5("${path.module}/static-website/${each.value}")
#   content_type = lookup(
#     {
#       html = "text/html",
#       css  = "text/css",
#       js   = "application/javascript",
#       png  = "image/png",
#       jpg  = "image/jpeg",
#       jpeg = "image/jpeg",
#       gif  = "image/gif"
#     },
#     regex("^.*\\.([^.]*)$", each.value)[0],
#     "binary/octet-stream"
#   )
#   #acl = "public-read"
# }


# Enable versioning for state files
# resource "aws_s3_bucket_versioning" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id

#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# Enable encryption at rest
# resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }



# Block public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Static Website Hosting S3 Bucket
resource "aws_s3_bucket_policy" "allow_public_access" {
    bucket = aws_s3_bucket.terraform_state.id

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = "*"
          Action = "s3:GetObject"
          Resource = "${aws_s3_bucket.terraform_state.arn}/*"
          Sid = "PublicReadGetObject"
          Principal = "*"
          Effect = "Allow"
          Action = [
            "s3:GetObject"
          ],
          Resource = ["arn:aws:s3:::${var.name_prefix}s3.${data.aws_route53_zone.sctp_zone.name}/*"]

        }
      ]
    })
  }

  resource "aws_s3_bucket_website_configuration" "website" {
    bucket = aws_s3_bucket.terraform_state.id

    index_document {
      suffix = "index.html"
    }

    error_document {
      key = "error.html"
    }
  }


  # Route53 Alias/CustomName Record for S3 Website

  data "aws_route53_zone" "sctp_zone" {
  name = "sctp-sandbox.com"
  }

  resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.sctp_zone.zone_id
  name = "${var.name_prefix}s3" # Bucket prefix before sctp-sandbox.com
  type = "A"
  


  alias {
    name = aws_s3_bucket_website_configuration.website.website_domain
    zone_id = aws_s3_bucket.terraform_state.hosted_zone_id
    evaluate_target_health = true
  }
  }
