#!/bin/bash

# Sky High Booker - Automated Setup Script
# This script handles all dependencies for new developers

set -e

echo "🚀 Setting up Sky High Booker infrastructure dependencies..."

# Check prerequisites
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI is required but not installed. Aborting." >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed. Aborting." >&2; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform is required but not installed. Aborting." >&2; exit 1; }
command -v node >/dev/null 2>&1 || { echo "❌ Node.js is required but not installed. Aborting." >&2; exit 1; }

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "📋 Using AWS Account: $AWS_ACCOUNT_ID"

# Step 1: Create required directories
echo "📁 Creating lambda-packages directory..."
mkdir -p lambda-packages

# Step 2: Install Lambda dependencies
echo "📦 Installing Lambda dependencies..."
cd lambda/bookings
npm install --production
cd ../../

# Step 3: Initialize Terraform
echo "🔧 Initializing Terraform..."
cd terraform
terraform init

# Step 4: Deploy core infrastructure first
echo "🏗️ Deploying core infrastructure (ECR, DynamoDB)..."
terraform apply -target=aws_ecr_repository.sky_high_booker -target=aws_dynamodb_table.bookings -target=aws_dynamodb_table.flights -target=aws_cognito_user_pool.user_pool -auto-approve

# Step 5: Get ECR repository URL
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/ce11g3-sky-high-booker"
echo "📦 ECR Repository: $ECR_URI"

# Step 6: Check if Docker image exists
echo "🔍 Checking if Docker image exists in ECR..."
IMAGE_EXISTS=$(aws ecr describe-images --repository-name ce11g3-sky-high-booker --region us-east-1 --query 'imageDetails[?contains(imageTags, `latest`)]' --output text 2>/dev/null || echo "")

if [ -z "$IMAGE_EXISTS" ]; then
    echo "🐳 Building and pushing Docker image..."
    cd ..
    
    # Build image
    docker build -t sky-high-booker .
    
    # Login to ECR
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URI
    
    # Tag and push
    docker tag sky-high-booker:latest $ECR_URI:latest
    docker push $ECR_URI:latest
    
    echo "✅ Docker image pushed successfully"
    cd terraform
else
    echo "✅ Docker image already exists in ECR"
fi

# Step 7: Deploy complete infrastructure
echo "🚀 Deploying complete infrastructure..."
terraform apply -auto-approve

# Step 8: Display outputs
echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📋 Important URLs:"
terraform output application_url
terraform output api_gateway_url
echo ""
echo "🔧 Environment Variables for Frontend:"
terraform output -json aws_environment_variables | jq -r 'to_entries[] | "\(.key)=\(.value)"'
echo ""
echo "📖 Next Steps:"
echo "1. Update your .env file with the environment variables above"
echo "2. Deploy your frontend application"
echo "3. Test the application using the ALB URL"