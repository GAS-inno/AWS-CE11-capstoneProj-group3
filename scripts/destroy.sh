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
log_warning "- CloudFront distribution"
log_warning "- S3 buckets (with data loss)"
log_warning "- Route 53 records and SSL certificates"
log_warning "- API Gateway and Lambda functions"
log_warning "- DynamoDB tables (with data loss)"
log_warning "- Cognito user pools"
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

# Step 1: Destroy CloudFront and S3 resources (may take time)
log_info "Step 1: Destroying CloudFront distribution..."
terraform destroy -target=aws_cloudfront_distribution.website \
                  -target=aws_cloudfront_origin_access_identity.website \
                  -auto-approve || true

log_info "Step 2: Destroying Route 53 and SSL resources..."
terraform destroy -target=aws_route53_record.app_domain \
                  -target=aws_acm_certificate_validation.website \
                  -target=aws_route53_record.cert_validation \
                  -target=aws_acm_certificate.website \
                  -auto-approve || true

log_info "Step 3: Destroying S3 bucket..."
terraform destroy -target=aws_s3_bucket_policy.website \
                  -target=aws_s3_bucket_website_configuration.website \
                  -target=aws_s3_bucket_cors_configuration.website \
                  -target=aws_s3_bucket.website \
                  -auto-approve || true

log_info "Step 4: Destroying API Gateway and Lambda..."
terraform destroy -target=aws_api_gateway_deployment.booking_api \
                  -target=aws_api_gateway_stage.prod \
                  -target=aws_lambda_function.create_booking \
                  -target=aws_lambda_function.get_bookings \
                  -target=aws_lambda_function.get_booking_by_id \
                  -target=aws_lambda_function.get_occupied_seats \
                  -target=aws_api_gateway_rest_api.booking_api \
                  -auto-approve || true

log_info "Step 5: Destroying remaining resources..."
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
log_info "- CloudWatch log groups (will auto-expire)"
log_info "- Route 53 hosted zone (if not managed by Terraform)"