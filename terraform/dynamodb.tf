# DynamoDB Tables for Sky High Booker Application
# Replacing RDS PostgreSQL with serverless DynamoDB

# ==============================================
# Application Data Tables
# ==============================================

# Bookings Table
resource "aws_dynamodb_table" "bookings" {
  name         = "${var.project_name}-bookings"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Global Secondary Index for user bookings
  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "booking_date"
    type = "S"
  }

  global_secondary_index {
    name            = "UserBookingsIndex"
    hash_key        = "user_id"
    range_key       = "booking_date"
    projection_type = "ALL"
  }

  # Global Secondary Index for flight bookings
  attribute {
    name = "flight_id"
    type = "S"
  }

  global_secondary_index {
    name            = "FlightBookingsIndex"
    hash_key        = "flight_id"
    range_key       = "booking_date"
    projection_type = "ALL"
  }

  tags = local.tags
}