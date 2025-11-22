#!/bin/bash

# Sky High Booker - Infrastructure Cleanup Script
# This script safely destroys all infrastructure in the correct order

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

echo "🧹 Sky High Booker - Infrastructure Cleanup"
echo "==========================================="

# Get current directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_DIR="$PROJECT_DIR/terraform"

log_info "Project Directory: $PROJECT_DIR"

# Confirmation
echo ""
log_warning "⚠️  WARNING: This will destroy ALL infrastructure!"
log_warning "This includes:"
log_warning "- ECS services and tasks"
log_warning "- Load balancers and target groups"
log_warning "- Route 53 records and SSL certificates"
log_warning "- API Gateway and Lambda functions"
log_warning "- DynamoDB tables (with data loss)"
log_warning "- S3 buckets (with data loss)"
log_warning "- VPC and networking resources"
echo ""
read -p "Are you sure you want to continue? Type 'yes' to confirm: " confirmation

if [ "$confirmation" != "yes" ]; then
    log_info "Destruction cancelled"
    exit 0
fi

cd "$TERRAFORM_DIR"

# Check if Terraform state exists
if ! terraform show > /dev/null 2>&1; then
    log_warning "No Terraform state found. Nothing to destroy."
    exit 0
fi

log_info "Starting infrastructure destruction..."

# Step 1: Scale down ECS service to 0 to stop tasks gracefully
log_info "Step 1: Scaling down ECS service..."
ECS_CLUSTER=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "")
ECS_SERVICE=$(terraform output -raw ecs_service_name 2>/dev/null || echo "")

if [ -n "$ECS_CLUSTER" ] && [ -n "$ECS_SERVICE" ]; then
    aws ecs update-service --cluster "$ECS_CLUSTER" --service "$ECS_SERVICE" --desired-count 0 > /dev/null 2>&1 || true
    log_success "ECS service scaled down"
else
    log_info "ECS service info not found, skipping scale down"
fi

# Step 2: Wait a moment for tasks to stop
log_info "Waiting for ECS tasks to stop..."
sleep 30

# Step 3: Destroy infrastructure in reverse order
log_info "Step 3: Destroying ECS services and tasks..."
terraform destroy -target=module.ecs.module.service -auto-approve || true

log_info "Step 4: Destroying load balancer resources..."
terraform destroy -target=aws_lb_listener.web_https \
                  -target=aws_lb_listener.web \
                  -target=aws_lb.main \
                  -target=aws_lb_target_group.ecs \
                  -auto-approve || true

log_info "Step 5: Destroying Route 53 and SSL resources..."
terraform destroy -target=aws_route53_record.app_domain \
                  -target=aws_acm_certificate_validation.app_cert \
                  -target=aws_route53_record.app_cert_validation \
                  -target=aws_acm_certificate.app_cert \
                  -auto-approve || true

log_info "Step 6: Destroying API Gateway and Lambda..."
terraform destroy -target=aws_api_gateway_deployment.booking_api \
                  -target=aws_api_gateway_stage.prod \
                  -target=aws_lambda_function.create_booking \
                  -target=aws_lambda_function.get_bookings \
                  -target=aws_lambda_function.get_booking_by_id \
                  -target=aws_lambda_function.get_occupied_seats \
                  -target=aws_api_gateway_rest_api.booking_api \
                  -auto-approve || true

log_info "Step 7: Destroying remaining resources..."
terraform destroy -auto-approve

log_success "Infrastructure destruction completed!"

# Step 4: Clean up local state if requested
echo ""
read -p "Do you want to remove local Terraform state files? (y/N): " cleanup_state
if [ "$cleanup_state" = "y" ] || [ "$cleanup_state" = "Y" ]; then
    rm -f terraform.tfstate*
    rm -f tfplan
    rm -rf .terraform/
    log_success "Local Terraform state cleaned up"
fi

echo ""
log_success "🎉 Cleanup complete!"
log_info "All Sky High Booker infrastructure has been destroyed."
echo ""
log_info "Note: The following may still exist and need manual cleanup:"
log_info "- ECR repositories with Docker images"
log_info "- CloudWatch log groups (will auto-expire)"
log_info "- Route 53 hosted zone (if not managed by Terraform)"