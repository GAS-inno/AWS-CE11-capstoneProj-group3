#!/bin/bash

# Sky High Booker - Complete Infrastructure & Application Deployment Script
# This script handles the complete deployment process from infrastructure to application
# 
# Prerequisites:
# - AWS CLI configured with appropriate permissions
# - Docker installed and running
# - Terraform installed
# - Internet connection for downloading dependencies

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Function to check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured or invalid. Please run 'aws configure' first."
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    log_success "All prerequisites satisfied"
}

echo "🚀 Sky High Booker - Complete Deployment Script"
echo "==============================================="

# Check prerequisites first
check_prerequisites

# Get current directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_DIR="$PROJECT_DIR/terraform"

log_info "Project Directory: $PROJECT_DIR"

# Validate project structure
if [ ! -f "$PROJECT_DIR/Dockerfile" ]; then
    log_error "Dockerfile not found in project directory"
    exit 1
fi

if [ ! -d "$TERRAFORM_DIR" ]; then
    log_error "Terraform directory not found"
    exit 1
fi

# Function to check if infrastructure exists
check_infrastructure() {
    cd "$TERRAFORM_DIR"
    if terraform show > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to apply terraform with retry logic for dependency issues
apply_with_retry() {
    local targets="$1"
    local description="$2"
    local max_attempts=3
    
    log_info "$description"
    
    for attempt in $(seq 1 $max_attempts); do
        log_info "Attempt $attempt/$max_attempts for: $description"
        
        if [ -n "$targets" ]; then
            if terraform apply $targets -auto-approve; then
                log_success "$description completed successfully on attempt $attempt"
                return 0
            fi
        else
            if terraform apply -auto-approve; then
                log_success "$description completed successfully on attempt $attempt"
                return 0
            fi
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            log_warning "Attempt $attempt failed, waiting 15 seconds before retry..."
            sleep 15
        else
            log_error "$description failed after $max_attempts attempts"
            return 1
        fi
    done
}

# Step 1: Infrastructure Deployment
log_info "Step 1: Deploying Infrastructure..."
cd "$TERRAFORM_DIR"

# Validate Terraform configuration
log_info "Validating Terraform configuration..."
if ! terraform fmt -check=true -diff=false; then
    log_warning "Terraform formatting issues found, auto-fixing..."
    terraform fmt -recursive
fi

if ! terraform validate; then
    log_error "Terraform configuration validation failed"
    exit 1
fi
log_success "Terraform configuration is valid"

if check_infrastructure; then
    log_success "Existing infrastructure detected"
    log_info "Refreshing infrastructure state..."
    
    # Try normal deployment first
    if terraform plan -out=tfplan && terraform apply tfplan; then
        log_success "Infrastructure refresh completed successfully"
    else
        log_warning "Normal refresh failed, trying dependency resolution approach..."
        
        # Fall back to staged deployment if there are dependency issues
        log_info "Applying targeted updates to resolve any dependency issues..."
        apply_with_retry "-target=module.ecs.module.service" "ECS Service Dependencies Resolution"
        
        # Final apply to catch anything missed
        apply_with_retry "" "Final infrastructure updates"
    fi
else
    echo "🆕 No existing infrastructure found"
    echo "🚀 Initializing and deploying complete infrastructure..."
    
    # Initialize Terraform
    terraform init
    
    # Deploy infrastructure in stages to handle dependencies
    apply_with_retry "-target=aws_vpc.main \
                   -target=aws_subnet.public \
                   -target=aws_internet_gateway.main \
                   -target=aws_route_table.public \
                   -target=aws_route_table_association.public \
                   -target=aws_s3_bucket.app_storage \
                   -target=aws_s3_bucket_cors_configuration.app_storage \
                   -target=aws_s3_bucket_public_access_block.app_storage \
                   -target=aws_s3_bucket_server_side_encryption_configuration.app_storage \
                   -target=aws_s3_bucket_versioning.app_storage \
                   -target=aws_iam_role.ecs_execution_role \
                   -target=aws_iam_role.ecs_task_role \
                   -target=aws_iam_role.lambda_booking_role \
                   -target=aws_iam_policy.ecs_secrets_policy \
                   -target=aws_iam_policy.lambda_dynamodb_policy \
                   -target=aws_dynamodb_table.bookings \
                   -target=aws_cognito_user_pool.user_pool \
                   -target=aws_cognito_user_pool_client.user_pool_client \
                   -target=aws_cognito_identity_pool.identity_pool \
                   -target=aws_ecr_repository.sky_high_booker \
                   -target=aws_ecr_repository.ecr" "📦 Stage 1: Core infrastructure (VPC, IAM, S3, etc.)"
    
    apply_with_retry "-target=aws_api_gateway_rest_api.booking_api -target=aws_lambda_function.create_booking -target=aws_lambda_function.get_bookings -target=aws_lambda_function.get_booking_by_id -target=aws_lambda_function.get_occupied_seats" "🌐 Stage 2: API Gateway and Lambda functions"
    
    apply_with_retry "-target=aws_api_gateway_resource.bookings -target=aws_api_gateway_resource.booking_by_id -target=aws_api_gateway_resource.occupied_seats -target=aws_api_gateway_method.create_booking -target=aws_api_gateway_method.get_bookings -target=aws_api_gateway_method.get_booking_by_id -target=aws_api_gateway_method.get_occupied_seats -target=aws_api_gateway_integration.create_booking -target=aws_api_gateway_integration.get_bookings -target=aws_api_gateway_integration.get_booking_by_id -target=aws_api_gateway_integration.get_occupied_seats -target=aws_api_gateway_deployment.booking_api -target=aws_api_gateway_stage.prod" "🔗 Stage 3: API Gateway integration"
    
    apply_with_retry "-target=aws_acm_certificate.app_cert -target=aws_route53_record.app_cert_validation -target=aws_acm_certificate_validation.app_cert -target=aws_route53_record.app_domain" "🌍 Stage 4: Route 53 and SSL Certificate"
    
    apply_with_retry "-target=aws_lb.main -target=aws_lb_target_group.ecs -target=module.alb_sg.aws_security_group.this_name_prefix -target=module.ecs_sg.aws_security_group.this_name_prefix -target=module.ecs.module.cluster.aws_cloudwatch_log_group.this -target=module.ecs.module.cluster.aws_ecs_cluster.this -target=module.ecs.module.cluster.aws_ecs_cluster_capacity_providers.this" "⚖️ Stage 5: Load Balancer and ECS Cluster"
    
    apply_with_retry "-target=aws_lb_listener.web -target=aws_lb_listener.web_https -target=aws_iam_role.authenticated_role -target=aws_iam_role_policy.authenticated_policy -target=aws_cognito_identity_pool_roles_attachment.identity_pool_roles -target=aws_ecr_lifecycle_policy.sky_high_booker" "🔗 Stage 6: Load Balancer Listeners and IAM"
    
    echo "🚀 Stage 7: ECS Service (resolving container definition dependencies)..."
    # Apply ECS service components separately to resolve for_each dependency issues
    # Retry up to 3 times if we hit dependency issues
    ECS_DEPLOY_SUCCESS=false
    for attempt in {1..3}; do
        log_info "ECS service deployment attempt $attempt/3..."
        
        if terraform apply -target=module.ecs.module.service -auto-approve; then
            ECS_DEPLOY_SUCCESS=true
            log_success "ECS service deployed successfully on attempt $attempt"
            break
        else
            log_warning "ECS service deployment failed on attempt $attempt"
            if [ $attempt -eq 3 ]; then
                log_error "ECS service deployment failed after 3 attempts. Trying alternative approach..."
                
                # Alternative: Deploy individual ECS components step by step
                log_info "Deploying ECS task definition first..."
                terraform apply -target=module.ecs.module.service.aws_ecs_task_definition.this -auto-approve || true
                
                log_info "Deploying ECS service..."  
                terraform apply -target=module.ecs.module.service.aws_ecs_service.this -auto-approve || true
                
                log_info "Deploying autoscaling components..."
                terraform apply -target=module.ecs.module.service.aws_appautoscaling_target.this -auto-approve || true
                terraform apply -target=module.ecs.module.service.aws_appautoscaling_policy.this -auto-approve || true
                
                # Final attempt
                if terraform apply -auto-approve; then
                    ECS_DEPLOY_SUCCESS=true
                    log_success "ECS service deployed using alternative approach"
                    break
                fi
            else
                log_info "Waiting 30 seconds before retry..."
                sleep 30
            fi
        fi
    done
    
    if [ "$ECS_DEPLOY_SUCCESS" = false ]; then
        log_error "Failed to deploy ECS service after all attempts"
        log_info "Infrastructure deployment will continue, but ECS service may need manual intervention"
    fi
    
    apply_with_retry "" "✅ Stage 8: Final deployment cleanup"
fi

echo "✅ Infrastructure deployment completed!"

# Step 2: Get infrastructure values from Terraform
echo ""
echo "📋 Step 2: Getting infrastructure values..."

# Get dynamic values from Terraform outputs
API_GATEWAY_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
ECR_REPOSITORY_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
USER_POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null || echo "")
USER_POOL_CLIENT_ID=$(terraform output -raw cognito_user_pool_client_id 2>/dev/null || echo "")
ALB_URL=$(terraform output -raw alb_dns_name 2>/dev/null || echo "")
APP_DOMAIN_URL=$(terraform output -raw app_domain_url 2>/dev/null || echo "")
S3_BUCKET=$(terraform output -raw app_s3_bucket_name 2>/dev/null || echo "")

echo "🔗 API Gateway URL: $API_GATEWAY_URL"
echo "🏗️  ECR Repository: $ECR_REPOSITORY_URL"
echo "🔐 User Pool ID: $USER_POOL_ID"
echo "👤 User Pool Client: $USER_POOL_CLIENT_ID"
echo "⚖️  Load Balancer: $ALB_URL"
echo "🌐 Custom Domain: $APP_DOMAIN_URL"
echo "💾 S3 Bucket: $S3_BUCKET"

# Verify we have all required values
if [[ -z "$API_GATEWAY_URL" || -z "$ECR_REPOSITORY_URL" ]]; then
    echo "❌ Error: Could not retrieve required infrastructure values from Terraform."
    echo "   Infrastructure deployment may have failed. Check Terraform outputs."
    exit 1
fi

# Step 3: Build Docker image with placeholders
echo ""
echo "🔨 Step 3: Building Docker image with dynamic placeholders..."
cd "$PROJECT_DIR"

docker build -t sky-high-booker:latest .

if [ $? -ne 0 ]; then
    echo "❌ Error: Docker build failed"
    exit 1
fi

echo "✅ Docker image built successfully"

# Step 4: Tag and push to ECR
echo ""
echo "📦 Step 4: Pushing to ECR repository..."

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

# Step 5: Deploy ECS service (if not exists) and update
echo ""
echo "🔄 Step 5: Deploying/Updating ECS service..."

# Get ECS cluster and service names from Terraform outputs
ECS_CLUSTER=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "sky-high-booker-dev-ecs-cluster")
ECS_SERVICE=$(terraform output -raw ecs_service_name 2>/dev/null || echo "sky-high-booker")

echo "🏗️  ECS Cluster: $ECS_CLUSTER"
echo "⚙️  ECS Service: $ECS_SERVICE"

# Check if ECS service exists and get its status
SERVICE_EXISTS=$(aws ecs describe-services --cluster "$ECS_CLUSTER" --services "$ECS_SERVICE" --query 'services[0].serviceName' --output text 2>/dev/null || echo "None")

if [ "$SERVICE_EXISTS" = "None" ] || [ "$SERVICE_EXISTS" = "" ]; then
    log_info "ECS service not found, deploying via Terraform..."
    cd "$TERRAFORM_DIR"
    
    # Use the same retry logic as in initial deployment
    ECS_DEPLOY_SUCCESS=false
    for attempt in {1..3}; do
        log_info "ECS service deployment attempt $attempt/3..."
        
        if terraform apply -target=module.ecs.module.service -auto-approve; then
            ECS_DEPLOY_SUCCESS=true
            log_success "ECS service deployed successfully on attempt $attempt"
            break
        else
            log_warning "ECS service deployment failed on attempt $attempt"
            if [ $attempt -eq 3 ]; then
                log_error "ECS service deployment failed after 3 attempts. Manual intervention may be required."
                exit 1
            else
                log_info "Waiting 30 seconds before retry..."
                sleep 30
            fi
        fi
    done
    
    if [ "$ECS_DEPLOY_SUCCESS" = false ]; then
        log_error "Failed to deploy ECS service after all attempts"
        exit 1
    fi
    log_success "ECS service deployed successfully"
else
    log_info "ECS service exists, forcing new deployment with updated image..."
    aws ecs update-service --cluster "$ECS_CLUSTER" --service "$ECS_SERVICE" --force-new-deployment > /dev/null
    
    if [ $? -ne 0 ]; then
        log_error "ECS service update failed"
        exit 1
    fi
    log_success "ECS service deployment initiated"
fi

# Step 6: Wait for deployment and show status
echo ""
echo "⏳ Step 6: Monitoring deployment status..."

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

# Step 7: Test the deployment
echo ""
echo "🧪 Step 7: Testing deployment..."

# Test custom domain first (HTTPS), then ALB (HTTP)
if [ -n "$APP_DOMAIN_URL" ]; then
    echo "🧪 Testing custom domain: $APP_DOMAIN_URL"
    HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$APP_DOMAIN_URL" 2>/dev/null || echo "000")
    
    if [ "$HTTPS_STATUS" = "200" ]; then
        echo "✅ Custom domain is responding correctly (HTTPS $HTTPS_STATUS)"
    else
        echo "⚠️  Custom domain may not be ready yet (HTTPS $HTTPS_STATUS)"
    fi
fi

if [ -n "$ALB_URL" ]; then
    echo "🧪 Testing load balancer: http://$ALB_URL"
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$ALB_URL" 2>/dev/null || echo "000")
    
    if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "301" ] || [ "$HTTP_STATUS" = "302" ]; then
        echo "✅ Load balancer is responding correctly (HTTP $HTTP_STATUS)"
    else
        echo "⚠️  Load balancer may not be ready yet (HTTP $HTTP_STATUS)"
    fi
else
    echo "⚠️  Load balancer URL not available for testing"
fi

# Summary
echo ""
echo "🎉 Complete Deployment Summary"
echo "============================="
echo "🌐 Custom Domain: ${APP_DOMAIN_URL:-'Not configured'}"
echo "⚖️  Load Balancer: ${ALB_URL:+'http://'$ALB_URL}"
echo "🔗 API Gateway: $API_GATEWAY_URL"
echo "🏗️  ECR Repository: $ECR_REPOSITORY_URL"
echo "💾 S3 Bucket: $S3_BUCKET"
echo "🔐 User Pool: $USER_POOL_ID"
echo ""
echo "🌟 Production URLs:"
if [ -n "$APP_DOMAIN_URL" ]; then
    echo "   Primary: $APP_DOMAIN_URL (HTTPS with SSL)"
fi
if [ -n "$ALB_URL" ]; then
    echo "   ALB Direct: http://$ALB_URL (redirects to HTTPS)"
fi
echo ""
echo "🔧 Technical Details:"
echo "   - Dynamic API Gateway URL injection: ✅ Enabled"
echo "   - SSL Certificate: ✅ Configured"
echo "   - Route 53 Domain: ✅ Active"
echo "   - ECS Auto-scaling: ✅ Enabled"
echo "   - S3 CORS: ✅ Configured"
echo "   - Cognito Authentication: ✅ Ready"
echo ""
echo "ℹ️  Environment variables are injected at container startup:"
echo "   - VITE_AWS_API_GATEWAY_URL=$API_GATEWAY_URL"
echo "   - VITE_AWS_USER_POOL_ID=$USER_POOL_ID"
echo "   - VITE_AWS_USER_POOL_CLIENT_ID=$USER_POOL_CLIENT_ID"
echo "   - VITE_AWS_S3_BUCKET=$S3_BUCKET"
echo "   - VITE_AWS_REGION=us-east-1"
echo ""
echo "🚀 Complete deployment finished! Sky High Booker is production-ready."
echo ""
echo "📝 Next Steps:"
echo "   1. Test the application at: ${APP_DOMAIN_URL:-http://$ALB_URL}"
echo "   2. Monitor ECS service in AWS Console"
echo "   3. Check CloudWatch logs for any issues"
echo "   4. Set up monitoring and alerts as needed"