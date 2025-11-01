#!/bin/bash

# Sky High Booker - ECR/ECS Deployment Script
# This script builds the Docker image, pushes it to ECR, and updates the ECS service

set -e  # Exit on any error

echo "🚀 Starting Sky High Booker ECR/ECS deployment..."

# Configuration
AWS_REGION="us-east-1"
ECR_REPOSITORY_NAME="ce11g3-sky-high-booker"
ECS_CLUSTER_NAME="ce11g3-sky-high-booker-cluster"
ECS_SERVICE_NAME="ce11g3-sky-high-booker-service"
IMAGE_TAG=${1:-latest}

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Please run this script from the project root."
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker first."
    exit 1
fi

# Check if AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    echo "❌ Error: AWS CLI is not installed. Please install and configure AWS CLI first."
    exit 1
fi

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "❌ Error: Failed to get AWS Account ID. Please check your AWS credentials."
    exit 1
fi

# Construct ECR repository URI
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY_NAME}"

echo "📋 Configuration:"
echo "  - AWS Account ID: $AWS_ACCOUNT_ID"
echo "  - AWS Region: $AWS_REGION"
echo "  - ECR Repository: $ECR_URI"
echo "  - Image Tag: $IMAGE_TAG"
echo "  - ECS Cluster: $ECS_CLUSTER_NAME"
echo "  - ECS Service: $ECS_SERVICE_NAME"
echo ""

# Check if ECR repository exists
echo "🔍 Checking if ECR repository exists..."
if ! aws ecr describe-repositories --repository-names $ECR_REPOSITORY_NAME --region $AWS_REGION >/dev/null 2>&1; then
    echo "❌ Error: ECR repository '$ECR_REPOSITORY_NAME' not found."
    echo "Please run 'terraform apply' first to create the infrastructure."
    exit 1
fi

# Login to ECR
echo "🔑 Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URI

# Build the Docker image
echo "🔨 Building Docker image..."
docker build -t $ECR_REPOSITORY_NAME:$IMAGE_TAG .

# Tag the image for ECR
echo "🏷️  Tagging image for ECR..."
docker tag $ECR_REPOSITORY_NAME:$IMAGE_TAG $ECR_URI:$IMAGE_TAG

# Push the image to ECR
echo "📤 Pushing image to ECR..."
docker push $ECR_URI:$IMAGE_TAG

# Check if ECS cluster exists
echo "🔍 Checking ECS cluster..."
if ! aws ecs describe-clusters --clusters $ECS_CLUSTER_NAME --region $AWS_REGION >/dev/null 2>&1; then
    echo "❌ Error: ECS cluster '$ECS_CLUSTER_NAME' not found."
    echo "Please run 'terraform apply' first to create the infrastructure."
    exit 1
fi

# Update ECS service to use the new image
echo "🔄 Updating ECS service..."
TASK_DEFINITION_ARN=$(aws ecs describe-services \
    --cluster $ECS_CLUSTER_NAME \
    --services $ECS_SERVICE_NAME \
    --region $AWS_REGION \
    --query 'services[0].taskDefinition' \
    --output text)

if [ "$TASK_DEFINITION_ARN" = "None" ] || [ -z "$TASK_DEFINITION_ARN" ]; then
    echo "❌ Error: ECS service '$ECS_SERVICE_NAME' not found."
    echo "Please run 'terraform apply' first to create the infrastructure."
    exit 1
fi

# Get the current task definition
echo "📋 Getting current task definition..."
aws ecs describe-task-definition \
    --task-definition $TASK_DEFINITION_ARN \
    --region $AWS_REGION \
    --query 'taskDefinition' > task-definition.json

# Update the image URI in the task definition
echo "🔧 Updating task definition with new image..."
jq --arg IMAGE_URI "$ECR_URI:$IMAGE_TAG" \
    'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .placementConstraints, .compatibilities, .registeredAt, .registeredBy) | 
     .containerDefinitions[0].image = $IMAGE_URI' \
    task-definition.json > updated-task-definition.json

# Register the new task definition
echo "📝 Registering new task definition..."
NEW_TASK_DEFINITION_ARN=$(aws ecs register-task-definition \
    --cli-input-json file://updated-task-definition.json \
    --region $AWS_REGION \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

# Update the ECS service to use the new task definition
echo "🔄 Updating ECS service with new task definition..."
aws ecs update-service \
    --cluster $ECS_CLUSTER_NAME \
    --service $ECS_SERVICE_NAME \
    --task-definition $NEW_TASK_DEFINITION_ARN \
    --region $AWS_REGION \
    --query 'service.serviceName' \
    --output text

# Wait for service to stabilize
echo "⏳ Waiting for service to stabilize (this may take a few minutes)..."
aws ecs wait services-stable \
    --cluster $ECS_CLUSTER_NAME \
    --services $ECS_SERVICE_NAME \
    --region $AWS_REGION

# Get the ALB DNS name
echo "🌐 Getting application URL..."
ALB_DNS_NAME=$(aws elbv2 describe-load-balancers \
    --region $AWS_REGION \
    --query "LoadBalancers[?contains(LoadBalancerName, 'ce11g3-sky-high-booker-alb')].DNSName" \
    --output text)

# Cleanup temporary files
rm -f task-definition.json updated-task-definition.json

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "📊 Deployment Summary:"
echo "  - Docker Image: $ECR_URI:$IMAGE_TAG"
echo "  - Task Definition: $NEW_TASK_DEFINITION_ARN"
echo "  - ECS Service: $ECS_SERVICE_NAME"
if [ -n "$ALB_DNS_NAME" ]; then
    echo "  - Application URL: http://$ALB_DNS_NAME"
else
    echo "  - Application URL: Check AWS Console for Load Balancer DNS name"
fi
echo ""
echo "🎯 Next steps:"
echo "1. Wait a few minutes for the new tasks to start"
echo "2. Visit the application URL to test"
echo "3. Check CloudWatch logs if there are any issues"
echo "4. Monitor the application performance in ECS console"
echo ""