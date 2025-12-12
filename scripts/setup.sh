#!/bin/bash

# Sky High Booker - Automated Setup Script
# This script handles all dependencies for new developers

set -e

echo "🚀 Setting up Sky High Booker infrastructure..."

# Check prerequisites
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI is required but not installed. Aborting." >&2; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform is required but not installed. Aborting." >&2; exit 1; }
command -v node >/dev/null 2>&1 || { echo "❌ Node.js is required but not installed. Aborting." >&2; exit 1; }

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "📋 Using AWS Account: $AWS_ACCOUNT_ID"

# Step 1: Install Lambda dependencies
echo "📦 Installing Lambda dependencies..."
cd lambda/bookings
npm install --production
cd ../../

# Step 2: Initialize Terraform
echo "🔧 Initializing Terraform..."
cd terraform
terraform init

# Step 3: Deploy infrastructure
echo "🏗️ Deploying infrastructure..."
terraform apply -auto-approve

# Step 4: Display outputs
echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "  1. Build the application: npm run build"
echo "  2. Deploy to S3: ./scripts/deploy-s3.sh"
echo ""
terraform output
