# Route 53 Configuration for Sky High Booker
# Creates environment-specific custom domains for the CloudFront distribution

# Data source for the existing hosted zone
data "aws_route53_zone" "selected" {
  name = var.base_domain
}

# Local variable for environment-specific domain
locals {
  full_domain_name = var.environment == "prod" ? "${var.domain_prefix}.${var.base_domain}" : "${var.domain_prefix}-${var.environment}.${var.base_domain}"
}

# Route 53 A record pointing to the CloudFront Distribution
resource "aws_route53_record" "app_domain" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = local.full_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}