#!/bin/bash

# Sky High Booker - Deployment Script
# This script builds the React application and deploys it to AWS

set -e  # Exit on any error

echo "🚀 Starting Sky High Booker deployment..."

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Please run this script from the project root."
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Build the React application
echo "🔨 Building React application..."
npm run build

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Error: Terraform is not installed. Please install Terraform first."
    exit 1
fi

# Check if AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    echo "❌ Error: AWS CLI is not installed. Please install and configure AWS CLI first."
    exit 1
fi

# Navigate to terraform directory
cd terraform

# Initialize Terraform (if not already done)
if [ ! -d ".terraform" ]; then
    echo "🔧 Initializing Terraform..."
    terraform init
fi

# Plan the deployment
echo "📋 Planning Terraform deployment..."
terraform plan

# Ask for confirmation
read -p "🤔 Do you want to apply these changes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Apply the changes
    echo "🚀 Deploying infrastructure and application..."
    terraform apply -auto-approve
    
    # Get the website URL
    WEBSITE_URL=$(terraform output -raw website_url 2>/dev/null || echo "Check AWS Console for the website URL")
    
    echo ""
    echo "✅ Deployment completed successfully!"
    echo "🌐 Website URL: $WEBSITE_URL"
    echo ""
    echo "📝 Next steps:"
    echo "1. Configure your Supabase credentials in the AWS environment"
    echo "2. Set up your domain DNS if using a custom domain"
    echo "3. Test the application functionality"
    echo ""
else
    echo "❌ Deployment cancelled."
fi

cd ..