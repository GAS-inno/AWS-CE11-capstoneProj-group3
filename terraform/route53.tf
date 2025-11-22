# Route 53 Configuration for Sky High Booker
# Creates a custom domain for the application

# Data source for the existing hosted zone
data "aws_route53_zone" "sctp_zone" {
  name = "sctp-sandbox.com"
}

# Route 53 A record pointing to the Application Load Balancer
resource "aws_route53_record" "app_domain" {
  zone_id = data.aws_route53_zone.sctp_zone.zone_id
  name    = "sky-high-booker"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# SSL Certificate for HTTPS (optional but recommended)
resource "aws_acm_certificate" "app_cert" {
  domain_name       = "sky-high-booker.sctp-sandbox.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

# Certificate validation records
resource "aws_route53_record" "app_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.app_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.sctp_zone.zone_id
}

# Wait for certificate validation
resource "aws_acm_certificate_validation" "app_cert" {
  certificate_arn         = aws_acm_certificate.app_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.app_cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}