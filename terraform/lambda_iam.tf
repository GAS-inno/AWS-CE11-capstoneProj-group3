# Lambda IAM Role and Policies

# IAM role for Lambda functions
resource "aws_iam_role" "lambda_booking_role" {
  name = "${local.prefix}-lambda-booking-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

# Policy for Lambda to write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_booking_role.name
}

# Custom policy for DynamoDB access
resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "${local.prefix}-lambda-dynamodb-policy"
  description = "Allow Lambda to access DynamoDB tables"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Resource = [
          aws_dynamodb_table.bookings.arn,
          "${aws_dynamodb_table.bookings.arn}/index/*"
        ]
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
  role       = aws_iam_role.lambda_booking_role.name
}

# CloudWatch Log Groups for Lambda functions
resource "aws_cloudwatch_log_group" "create_booking_logs" {
  name              = "/aws/lambda/${local.prefix}-createBooking"
  retention_in_days = 7

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "get_bookings_logs" {
  name              = "/aws/lambda/${local.prefix}-getBookings"
  retention_in_days = 7

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "get_booking_by_id_logs" {
  name              = "/aws/lambda/${local.prefix}-getBookingById"
  retention_in_days = 7

  tags = local.tags
}

resource "aws_cloudwatch_log_group" "get_occupied_seats_logs" {
  name              = "/aws/lambda/${local.prefix}-getOccupiedSeats"
  retention_in_days = 7

  tags = local.tags
}
