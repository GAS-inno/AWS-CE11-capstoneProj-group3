# API Gateway Configuration with Lambda Integration
resource "aws_api_gateway_rest_api" "booking_api" {
  # Check: CKV_AWS_237: "Ensure Create before destroy for API Gateway"
  name        = "${local.prefix}-api"
  description = "Booking API for Sky High Booker application"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

# /bookings resource
resource "aws_api_gateway_resource" "bookings" {
  # Check: CKV_AWS_237: "Ensure Create before destroy for API Gateway"

  rest_api_id = aws_api_gateway_rest_api.booking_api.id
  parent_id   = aws_api_gateway_rest_api.booking_api.root_resource_id
  path_part   = "bookings"
}

# /bookings/{id} resource
resource "aws_api_gateway_resource" "booking_by_id" {
  rest_api_id = aws_api_gateway_rest_api.booking_api.id
  parent_id   = aws_api_gateway_resource.bookings.id
  path_part   = "{id}"
}

# /bookings/occupied-seats resource
resource "aws_api_gateway_resource" "occupied_seats" {
  rest_api_id = aws_api_gateway_rest_api.booking_api.id
  parent_id   = aws_api_gateway_resource.bookings.id
  path_part   = "occupied-seats"
}

# POST /bookings - Create Booking
resource "aws_api_gateway_method" "create_booking" {
  # Check: CKV_AWS_59: "Ensure there is no open access to back-end resources through API"
  # Check: CKV2_AWS_53: "Ensure AWS API gateway request is validated"
  # Check: CKV_AWS_59: "Ensure there is no open access to back-end resources through API"
  rest_api_id      = aws_api_gateway_rest_api.booking_api.id
  resource_id      = aws_api_gateway_resource.bookings.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method_response" "create_booking_200" {
  rest_api_id = aws_api_gateway_rest_api.booking_api.id
  resource_id = aws_api_gateway_resource.bookings.id
  http_method = aws_api_gateway_method.create_booking.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration" "create_booking" {
  rest_api_id             = aws_api_gateway_rest_api.booking_api.id
  resource_id             = aws_api_gateway_resource.bookings.id
  http_method             = aws_api_gateway_method.create_booking.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.create_booking.invoke_arn
}

# GET /bookings - List Bookings
resource "aws_api_gateway_method" "get_bookings" {
  # Check: CKV2_AWS_53: "Ensure AWS API gateway request is validated"
  rest_api_id      = aws_api_gateway_rest_api.booking_api.id
  resource_id      = aws_api_gateway_resource.bookings.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true

}

resource "aws_api_gateway_method_response" "get_bookings_200" {
  rest_api_id = aws_api_gateway_rest_api.booking_api.id
  resource_id = aws_api_gateway_resource.bookings.id
  http_method = aws_api_gateway_method.get_bookings.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration" "get_bookings" {
  rest_api_id             = aws_api_gateway_rest_api.booking_api.id
  resource_id             = aws_api_gateway_resource.bookings.id
  http_method             = aws_api_gateway_method.get_bookings.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_bookings.invoke_arn
}

# GET /bookings/{id} - Get Booking by ID
resource "aws_api_gateway_method" "get_booking_by_id" {
  # Check: CKV_AWS_59: "Ensure there is no open access to back-end resources through API"
  # Check: CKV2_AWS_53: "Ensure AWS API gateway request is validated"
  # Check: CKV_AWS_59: "Ensure there is no open access to back-end resources through API"
  rest_api_id      = aws_api_gateway_rest_api.booking_api.id
  resource_id      = aws_api_gateway_resource.booking_by_id.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method_response" "get_booking_by_id_200" {
  rest_api_id = aws_api_gateway_rest_api.booking_api.id
  resource_id = aws_api_gateway_resource.booking_by_id.id
  http_method = aws_api_gateway_method.get_booking_by_id.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration" "get_booking_by_id" {
  rest_api_id             = aws_api_gateway_rest_api.booking_api.id
  resource_id             = aws_api_gateway_resource.booking_by_id.id
  http_method             = aws_api_gateway_method.get_booking_by_id.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_booking_by_id.invoke_arn
}

# GET /bookings/occupied-seats - Get Occupied Seats
resource "aws_api_gateway_method" "get_occupied_seats" {
  # Check: CKV_AWS_59: "Ensure there is no open access to back-end resources through API"
  # Check: CKV2_AWS_53: "Ensure AWS API gateway request is validated"
  # Check: CKV_AWS_59: "Ensure there is no open access to back-end resources through API"
  rest_api_id      = aws_api_gateway_rest_api.booking_api.id
  resource_id      = aws_api_gateway_resource.occupied_seats.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method_response" "get_occupied_seats_200" {
  rest_api_id = aws_api_gateway_rest_api.booking_api.id
  resource_id = aws_api_gateway_resource.occupied_seats.id
  http_method = aws_api_gateway_method.get_occupied_seats.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration" "get_occupied_seats" {
  rest_api_id             = aws_api_gateway_rest_api.booking_api.id
  resource_id             = aws_api_gateway_resource.occupied_seats.id
  http_method             = aws_api_gateway_method.get_occupied_seats.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_occupied_seats.invoke_arn
}

# CORS - OPTIONS methods
resource "aws_api_gateway_method" "options_bookings" {
  # Check: CKV2_AWS_53: "Ensure AWS API gateway request is validated"
  rest_api_id      = aws_api_gateway_rest_api.booking_api.id
  resource_id      = aws_api_gateway_resource.bookings.id
  http_method      = "OPTIONS"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "options_bookings" {
  rest_api_id = aws_api_gateway_rest_api.booking_api.id
  resource_id = aws_api_gateway_resource.bookings.id
  http_method = aws_api_gateway_method.options_bookings.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_bookings_200" {
  rest_api_id = aws_api_gateway_rest_api.booking_api.id
  resource_id = aws_api_gateway_resource.bookings.id
  http_method = aws_api_gateway_method.options_bookings.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_bookings" {
  rest_api_id = aws_api_gateway_rest_api.booking_api.id
  resource_id = aws_api_gateway_resource.bookings.id
  http_method = aws_api_gateway_method.options_bookings.http_method
  status_code = aws_api_gateway_method_response.options_bookings_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# OPTIONS /bookings/occupied-seats - CORS
resource "aws_api_gateway_method" "options_occupied_seats" {
  # Check: CKV2_AWS_53: "Ensure AWS API gateway request is validated"
  rest_api_id      = aws_api_gateway_rest_api.booking_api.id
  resource_id      = aws_api_gateway_resource.occupied_seats.id
  http_method      = "OPTIONS"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "options_occupied_seats" {
  rest_api_id = aws_api_gateway_rest_api.booking_api.id
  resource_id = aws_api_gateway_resource.occupied_seats.id
  http_method = aws_api_gateway_method.options_occupied_seats.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_occupied_seats_200" {
  rest_api_id = aws_api_gateway_rest_api.booking_api.id
  resource_id = aws_api_gateway_resource.occupied_seats.id
  http_method = aws_api_gateway_method.options_occupied_seats.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_occupied_seats" {
  rest_api_id = aws_api_gateway_rest_api.booking_api.id
  resource_id = aws_api_gateway_resource.occupied_seats.id
  http_method = aws_api_gateway_method.options_occupied_seats.http_method
  status_code = aws_api_gateway_method_response.options_occupied_seats_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "booking_api" {
  rest_api_id = aws_api_gateway_rest_api.booking_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.bookings.id,
      aws_api_gateway_resource.booking_by_id.id,
      aws_api_gateway_resource.occupied_seats.id,
      aws_api_gateway_method.create_booking.id,
      aws_api_gateway_method.get_bookings.id,
      aws_api_gateway_method.get_booking_by_id.id,
      aws_api_gateway_method.get_occupied_seats.id,
      aws_api_gateway_integration.create_booking.id,
      aws_api_gateway_integration.get_bookings.id,
      aws_api_gateway_integration.get_booking_by_id.id,
      aws_api_gateway_integration.get_occupied_seats.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.create_booking,
    aws_api_gateway_integration.get_bookings,
    aws_api_gateway_integration.get_booking_by_id,
    aws_api_gateway_integration.get_occupied_seats,
    aws_api_gateway_integration.options_bookings
  ]
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${local.prefix}-api"
  retention_in_days = 7

  tags = local.tags
}

# API Gateway Stage
resource "aws_api_gateway_stage" "prod" {
  # Check: CKV2_AWS_29: "Ensure public API gateway are protected by WAF"
  # Check: CKV2_AWS_4: "Ensure API Gateway stage have logging level defined as appropriate"
  # Check: CKV2_AWS_51: "Ensure AWS API Gateway endpoints uses client certificate authentication"
  # Check: CKV_AWS_76: "Ensure API Gateway has Access Logging enabled"
  deployment_id        = aws_api_gateway_deployment.booking_api.id
  rest_api_id          = aws_api_gateway_rest_api.booking_api.id
  stage_name           = "prod"
  xray_tracing_enabled = true

  tags = local.tags

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format          = "$context.requestId $context.extendedRequestId $context.identity.sourceIp $context.requestTime $context.routeKey $context.status $context.error.message"
  }
  cache_cluster_enabled = false

}


