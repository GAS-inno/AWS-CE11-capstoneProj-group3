# AWS Cognito User Pool for Authentication
resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.project_name}-user-pool"

  # Allow users to sign in with email
  username_attributes = ["email"]
  
  # User attributes
  schema {
    attribute_data_type = "String"
    name               = "email"
    required           = true
    mutable           = true
  }

  schema {
    attribute_data_type = "String"
    name               = "given_name"
    required           = true
    mutable           = true
  }

  schema {
    attribute_data_type = "String"
    name               = "family_name"
    required           = true
    mutable           = true
  }

  # Custom attribute for user role
  schema {
    attribute_data_type = "String"
    name               = "role"
    required           = false
    mutable           = true
  }

  # Password policy
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Email verification
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Sky High Booker - Verify your email"
    email_message        = "Your verification code is {####}"
  }

  # Auto-verify email
  auto_verified_attributes = ["email"]

  tags = local.tags
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "user_pool_client" {
  name         = "${var.project_name}-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id

  # App client settings
  generate_secret = false
  
  # Allow OAuth flows
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows = ["code", "implicit"]
  allowed_oauth_scopes = ["email", "openid", "profile"]
  
  # Callback URLs (update with your domain)
  callback_urls = [
    "http://localhost:5173/auth/callback",
    "https://sky-high-booker.example.com/auth/callback"
  ]
  
  logout_urls = [
    "http://localhost:5173",
    "https://sky-high-booker.example.com"
  ]

  # Explicit auth flows
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  # Token validity
  access_token_validity  = 1   # 1 hour
  id_token_validity     = 1   # 1 hour
  refresh_token_validity = 30  # 30 days

  token_validity_units {
    access_token  = "hours"
    id_token     = "hours"
    refresh_token = "days"
  }
}

# Cognito Identity Pool for AWS resource access
resource "aws_cognito_identity_pool" "identity_pool" {
  identity_pool_name               = "${var.project_name}-identity-pool"
  allow_unauthenticated_identities = false
  allow_classic_flow               = false

  cognito_identity_providers {
    client_id     = aws_cognito_user_pool_client.user_pool_client.id
    provider_name = aws_cognito_user_pool.user_pool.endpoint
  }

  tags = local.tags
}

# IAM role for authenticated users
resource "aws_iam_role" "authenticated_role" {
  name = "${var.project_name}-cognito-authenticated"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.identity_pool.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = local.tags
}

# IAM policy for authenticated users
resource "aws_iam_role_policy" "authenticated_policy" {
  name = "${var.project_name}-authenticated-policy"
  role = aws_iam_role.authenticated_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = "${aws_api_gateway_rest_api.booking_api.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.app_storage.arn}/*"
        ]
      }
    ]
  })
}

# Attach role to identity pool
resource "aws_cognito_identity_pool_roles_attachment" "identity_pool_roles" {
  identity_pool_id = aws_cognito_identity_pool.identity_pool.id

  roles = {
    "authenticated" = aws_iam_role.authenticated_role.arn
  }
}