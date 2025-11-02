# Simple API Gateway Configuration
resource "aws_api_gateway_rest_api" "booking_api" {
  name        = "${local.prefix}-api"
  description = "Booking API for Sky High Booker application"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  
  tags = local.tags
}