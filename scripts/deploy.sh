#!/bin/bash

# Sky High Booker - Dynamic Deployment Script
# This script handles the complete deployment process with dynamic API Gateway URLs

set -e

echo "🚀 Sky High Booker - Dynamic Deployment Script"
echo "=============================================="

# Get current directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_DIR="$PROJECT_DIR/terraform"

echo "📂 Project Directory: $PROJECT_DIR"

# Step 1: Get current infrastructure values from Terraform
echo "📋 Step 1: Getting current infrastructure values..."
cd "$TERRAFORM_DIR"

# Check if Terraform state exists
if ! terraform show > /dev/null 2>&1; then
    echo "❌ Error: Terraform state not found. Please run 'terraform apply' first."
    exit 1
fi

# Get dynamic values from Terraform outputs
API_GATEWAY_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
ECR_REPOSITORY_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
USER_POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null || echo "")
USER_POOL_CLIENT_ID=$(terraform output -raw cognito_user_pool_client_id 2>/dev/null || echo "")
ALB_URL=$(terraform output -raw alb_dns_name 2>/dev/null || echo "")

echo "🔗 API Gateway URL: $API_GATEWAY_URL"
echo "🏗️  ECR Repository: $ECR_REPOSITORY_URL"
echo "🔐 User Pool ID: $USER_POOL_ID"
echo "👤 User Pool Client: $USER_POOL_CLIENT_ID"
echo "⚖️  Load Balancer: $ALB_URL"

# Verify we have all required values
if [[ -z "$API_GATEWAY_URL" || -z "$ECR_REPOSITORY_URL" ]]; then
    echo "❌ Error: Could not retrieve required infrastructure values from Terraform."
    echo "   Make sure your Terraform infrastructure is deployed and outputs are defined."
    exit 1
fi

# Step 2: Build Docker image with placeholders
echo ""
echo "🔨 Step 2: Building Docker image with dynamic placeholders..."
cd "$PROJECT_DIR"

docker build -t sky-high-booker:latest .

if [ $? -ne 0 ]; then
    echo "❌ Error: Docker build failed"
    exit 1
fi

echo "✅ Docker image built successfully"

# Step 3: Tag and push to ECR
echo ""
echo "📦 Step 3: Pushing to ECR repository..."

# Get ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "$ECR_REPOSITORY_URL"

if [ $? -ne 0 ]; then
    echo "❌ Error: ECR login failed"
    exit 1
fi

# Tag and push
docker tag sky-high-booker:latest "$ECR_REPOSITORY_URL:latest"
docker push "$ECR_REPOSITORY_URL:latest"

if [ $? -ne 0 ]; then
    echo "❌ Error: Docker push failed"
    exit 1
fi

echo "✅ Docker image pushed to ECR successfully"

# Step 4: Force ECS service to redeploy
echo ""
echo "🔄 Step 4: Updating ECS service..."

# Get ECS cluster and service names (using known values for now)
ECS_CLUSTER="sky-high-booker-dev-ecs-cluster"
ECS_SERVICE="sky-high-booker"

echo "🏗️  ECS Cluster: $ECS_CLUSTER"
echo "⚙️  ECS Service: $ECS_SERVICE"

aws ecs update-service --cluster "$ECS_CLUSTER" --service "$ECS_SERVICE" --force-new-deployment > /dev/null

if [ $? -ne 0 ]; then
    echo "❌ Error: ECS service update failed"
    exit 1
fi

echo "✅ ECS service deployment initiated"

# Step 5: Wait for deployment and show status
echo ""
echo "⏳ Step 5: Monitoring deployment status..."

echo "Waiting for deployment to complete..."
for i in {1..30}; do
    DEPLOYMENT_STATUS=$(aws ecs describe-services --cluster "$ECS_CLUSTER" --services "$ECS_SERVICE" --query 'services[0].deployments[0].rolloutState' --output text 2>/dev/null || echo "UNKNOWN")
    
    if [ "$DEPLOYMENT_STATUS" = "COMPLETED" ]; then
        echo "✅ Deployment completed successfully!"
        break
    elif [ "$DEPLOYMENT_STATUS" = "FAILED" ]; then
        echo "❌ Deployment failed!"
        exit 1
    else
        echo "  Status: $DEPLOYMENT_STATUS (attempt $i/30)"
        sleep 10
    fi
done

# Step 6: Test the deployment
echo ""
echo "🧪 Step 6: Testing deployment..."

if [ -n "$ALB_URL" ]; then
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$ALB_URL" 2>/dev/null || echo "000")
    
    if [ "$HTTP_STATUS" = "200" ]; then
        echo "✅ Application is responding correctly (HTTP $HTTP_STATUS)"
    else
        echo "⚠️  Application may not be ready yet (HTTP $HTTP_STATUS)"
    fi
else
    echo "⚠️  Load balancer URL not available for testing"
fi

# Summary
echo ""
echo "🎉 Deployment Summary"
echo "===================="
echo "🔗 API Gateway: $API_GATEWAY_URL"
echo "⚖️  Load Balancer: http://$ALB_URL"
echo "🏗️  ECR Repository: $ECR_REPOSITORY_URL"
echo ""
echo "🌟 The application will automatically use the current API Gateway URL"
echo "    thanks to the runtime environment variable injection system!"
echo ""
echo "ℹ️  Note: The environment variables are injected at container startup:"
echo "   - VITE_AWS_API_GATEWAY_URL=$API_GATEWAY_URL"
echo "   - VITE_AWS_USER_POOL_ID=$USER_POOL_ID" 
echo "   - VITE_AWS_USER_POOL_CLIENT_ID=$USER_POOL_CLIENT_ID"
echo ""
echo "🚀 Deployment complete! Your booking system is ready."