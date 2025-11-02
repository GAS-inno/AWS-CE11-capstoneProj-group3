# DynamoDB Tables for Sky High Booker Application
# Replacing RDS PostgreSQL with serverless DynamoDB

# ==============================================
# State Locking Table (keep existing)
# ==============================================

resource "aws_dynamodb_table" "terraform_lock" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = "All"
  }
}

# ==============================================
# Application Data Tables
# ==============================================

# Flights Table
resource "aws_dynamodb_table" "flights" {
  name         = "${var.project_name}-flights"
  billing_mode = "PAY_PER_REQUEST" # Serverless billing
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S" # String
  }

  # Global Secondary Index for searching by route
  attribute {
    name = "route"
    type = "S"
  }

  attribute {
    name = "departure_date"
    type = "S"
  }

  global_secondary_index {
    name            = "RouteIndex"
    hash_key        = "route"
    range_key       = "departure_date"
    projection_type = "ALL"
  }

  # Global Secondary Index for searching by airline
  attribute {
    name = "airline"
    type = "S"
  }

  global_secondary_index {
    name            = "AirlineIndex"
    hash_key        = "airline"
    range_key       = "departure_date"
    projection_type = "ALL"
  }

  tags = local.tags
}

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

# Payments Table
resource "aws_dynamodb_table" "payments" {
  name         = "${var.project_name}-payments"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Global Secondary Index for booking payments
  attribute {
    name = "booking_id"
    type = "S"
  }

  attribute {
    name = "payment_date"
    type = "S"
  }

  global_secondary_index {
    name            = "BookingPaymentsIndex"
    hash_key        = "booking_id"
    range_key       = "payment_date"
    projection_type = "ALL"
  }

  # Global Secondary Index for user payments
  attribute {
    name = "user_id"
    type = "S"
  }

  global_secondary_index {
    name            = "UserPaymentsIndex"
    hash_key        = "user_id"
    range_key       = "payment_date"
    projection_type = "ALL"
  }

  tags = local.tags
}