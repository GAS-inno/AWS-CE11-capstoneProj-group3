# SNS Topic for Booking Notifications
resource "aws_sns_topic" "booking_notifications" {
  name = "${local.prefix}-booking-notifications"

  tags = local.tags
}

# HTTP subscription to Discord webhook
resource "aws_sns_topic_subscription" "discord_webhook" {
  count                  = var.discord_webhook_url != "" ? 1 : 0
  topic_arn              = aws_sns_topic.booking_notifications.arn
  protocol               = "https"
  endpoint               = var.discord_webhook_url
  endpoint_auto_confirms = true

  depends_on = [aws_sns_topic.booking_notifications]
}

output "sns_topic_arn" {
  value       = aws_sns_topic.booking_notifications.arn
  description = "SNS Topic ARN for booking notifications"
}
