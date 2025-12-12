# Lambda Functions for Bookings API

# Ensure lambda-packages directory exists
resource "null_resource" "create_lambda_packages_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/../lambda-packages"
  }
}

# Data source to create deployment package
data "archive_file" "lambda_booking_package" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/bookings"
  output_path = "${path.module}/../lambda-packages/bookings.zip"

  depends_on = [null_resource.create_lambda_packages_dir]
}

# Lambda Function: Create Booking
resource "aws_lambda_function" "create_booking" {
  #Check: CKV_AWS_117: "Ensure that AWS Lambda function is configured inside a VPC"
  #Check: CKV_AWS_116: "Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)"
  #Check: CKV_AWS_173: "Check encryption settings for Lambda environmental variable"
  #Check: CKV_AWS_50: "X-Ray tracing is enabled for Lambda"
  #Check: CKV_AWS_115: "Ensure that AWS Lambda function is configured for function-level concurrent execution limit"
  #Check: CKV_AWS_272: "Ensure AWS Lambda function is configured to validate code-signing"
  filename         = data.archive_file.lambda_booking_package.output_path
  function_name    = "${local.prefix}-createBooking"
  role             = aws_iam_role.lambda_booking_role.arn
  handler          = "createBooking.handler"
  source_code_hash = data.archive_file.lambda_booking_package.output_base64sha256
  runtime          = "nodejs18.x"
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      BOOKINGS_TABLE = aws_dynamodb_table.bookings.name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.create_booking_logs,
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_dynamodb
  ]

  tags = local.tags
}

# Lambda Function: Get Bookings (by user)
resource "aws_lambda_function" "get_bookings" {
  #Check: CKV_AWS_117: "Ensure that AWS Lambda function is configured inside a VPC"
  #Check: CKV_AWS_116: "Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)"
  #Check: CKV_AWS_50: "X-Ray tracing is enabled for Lambda"
  #Check: CKV_AWS_173: "Check encryption settings for Lambda environmental variable"
  #Check: CKV_AWS_115: "Ensure that AWS Lambda function is configured for function-level concurrent execution limit"
  #Check: CKV_272: "Ensure AWS Lambda function is configured to validate code-signing"
  filename         = data.archive_file.lambda_booking_package.output_path
  function_name    = "${local.prefix}-getBookings"
  role             = aws_iam_role.lambda_booking_role.arn
  handler          = "getBookings.handler"
  source_code_hash = data.archive_file.lambda_booking_package.output_base64sha256
  runtime          = "nodejs18.x"
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      BOOKINGS_TABLE = aws_dynamodb_table.bookings.name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.get_bookings_logs,
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_dynamodb
  ]

  tags = local.tags
}

# Lambda Function: Get Booking by ID
resource "aws_lambda_function" "get_booking_by_id" {
  #Check: CKV_AWS_117: "Ensure that AWS Lambda function is configured inside a VPC"
  #Check: CKV_AWS_116: "Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)"
  #Check: CKV_AWS_50: "X-Ray tracing is enabled for Lambda"
  #Check: CKV_AWS_173: "Check encryption settings for Lambda environmental variable"
  #Check: CKV_AWS_115: "Ensure that AWS Lambda function is configured for function-level concurrent execution limit"
  #Check: CKV_272: "Ensure AWS Lambda function is configured to validate code-signing"

  filename         = data.archive_file.lambda_booking_package.output_path
  function_name    = "${local.prefix}-getBookingById"
  role             = aws_iam_role.lambda_booking_role.arn
  handler          = "getBookingById.handler"
  source_code_hash = data.archive_file.lambda_booking_package.output_base64sha256
  runtime          = "nodejs18.x"
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      BOOKINGS_TABLE = aws_dynamodb_table.bookings.name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.get_booking_by_id_logs,
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_dynamodb
  ]

  tags = local.tags
}

# Lambda Function: Get Occupied Seats
resource "aws_lambda_function" "get_occupied_seats" {
  #Check: CKV_AWS_115: "Ensure that AWS Lambda function is configured for function-level concurrent execution limit"
  #Check: CKV_AWS_117: "Ensure that AWS Lambda function is configured inside a VPC"
  #Check: CKV_AWS_116: "Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)"
  #Check: CKV_AWS_50: "X-Ray tracing is enabled for Lambda"
  #Check: CKV_AWS_173: "Check encryption settings for Lambda environmental variable"
  #Check: CKV_AWS_115: "Ensure that AWS Lambda function is configured for function-level concurrent execution limit"
  #Check: CKV_272: "Ensure AWS Lambda function is configured to validate code-signing"
  filename         = data.archive_file.lambda_booking_package.output_path
  function_name    = "${local.prefix}-getOccupiedSeats"
  role             = aws_iam_role.lambda_booking_role.arn
  handler          = "getOccupiedSeats.handler"
  source_code_hash = data.archive_file.lambda_booking_package.output_base64sha256
  runtime          = "nodejs18.x"
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      BOOKINGS_TABLE = aws_dynamodb_table.bookings.name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.get_occupied_seats_logs,
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_dynamodb
  ]

  tags = local.tags
}

# Lambda Permissions for API Gateway
resource "aws_lambda_permission" "create_booking_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_booking.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.booking_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "get_bookings_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_bookings.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.booking_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "get_booking_by_id_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_booking_by_id.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.booking_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "get_occupied_seats_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_occupied_seats.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.booking_api.execution_arn}/*/*"
}
