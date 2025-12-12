# Route 53 Configuration for Sky High Booker
# Creates a custom domain for the CloudFront distribution

# Data source for the existing hosted zone
data "aws_route53_zone" "selected" {
  count = var.domain_name != "" ? 1 : 0
  name  = "sctp-sandbox.com"
}

# Route 53 A record pointing to the CloudFront Distribution
resource "aws_route53_record" "app_domain" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = data.aws_route53_zone.selected[0].zone_id
  name    = "sky-high-booker"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}