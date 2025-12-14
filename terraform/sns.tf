# SNS Topic for Booking Notifications
resource "aws_sns_topic" "booking_notifications" {
  name = "${local.prefix}-booking-notifications"

  tags = local.tags
}

# Allow SNS to invoke the Discord forwarder Lambda
resource "aws_lambda_permission" "sns_invoke_discord_forwarder" {
  count         = var.discord_webhook_url != "" ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.discord_forwarder[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.booking_notifications.arn
}

# SNS subscription to Lambda (auto-confirmed). Lambda forwards to Discord.
resource "aws_sns_topic_subscription" "discord_forwarder" {
  count     = var.discord_webhook_url != "" ? 1 : 0
  topic_arn = aws_sns_topic.booking_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.discord_forwarder[0].arn

  depends_on = [aws_lambda_permission.sns_invoke_discord_forwarder]
}

output "sns_topic_arn" {
  value       = aws_sns_topic.booking_notifications.arn
  description = "SNS Topic ARN for booking notifications"
}
