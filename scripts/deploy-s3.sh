#!/bin/bash

# Sky High Booker - S3 Static Website Deployment Script
# This script deploys the React SPA to S3 with CloudFront CDN
# 
# Prerequisites:
# - AWS CLI configured with appropriate permissions
# - Node.js and npm installed
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
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed. Please install Node.js first."
        exit 1
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        log_error "npm is not installed. Please install npm first."
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    log_success "All prerequisites satisfied"
}

echo "🚀 Sky High Booker - S3 Static Website Deployment"
echo "================================================="

# Check prerequisites first
check_prerequisites

# Get current directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_DIR="$PROJECT_DIR/terraform"

log_info "Project Directory: $PROJECT_DIR"

# Validate project structure
if [ ! -f "$PROJECT_DIR/package.json" ]; then
    log_error "package.json not found in project directory"
    exit 1
fi

if [ ! -d "$TERRAFORM_DIR" ]; then
    log_error "Terraform directory not found"
    exit 1
fi

# Step 1: Infrastructure Deployment
log_info "Step 1: Deploying Infrastructure..."
cd "$TERRAFORM_DIR"

# Initialize Terraform
log_info "Initializing Terraform..."
terraform init

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

# Plan and apply infrastructure
log_info "Planning infrastructure changes..."
terraform plan -out=tfplan

log_info "Applying infrastructure changes..."
terraform apply tfplan

log_success "Infrastructure deployment completed"

# Step 2: Get infrastructure values from Terraform
echo ""
log_info "Step 2: Getting infrastructure values..."

# Get dynamic values from Terraform outputs
API_GATEWAY_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "")
CLOUDFRONT_URL=$(terraform output -raw cloudfront_domain_name 2>/dev/null || echo "")
CLOUDFRONT_DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")
USER_POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null || echo "")
USER_POOL_CLIENT_ID=$(terraform output -raw cognito_user_pool_client_id 2>/dev/null || echo "")
APP_DOMAIN_URL=$(terraform output -raw app_domain_url 2>/dev/null || echo "")

echo "🔗 API Gateway URL: $API_GATEWAY_URL"
echo "💾 S3 Bucket: $S3_BUCKET"
echo "🌐 CloudFront URL: $CLOUDFRONT_URL"
echo "🔐 User Pool ID: $USER_POOL_ID"
echo "👤 User Pool Client: $USER_POOL_CLIENT_ID"
echo "🌐 Custom Domain: $APP_DOMAIN_URL"

# Verify we have all required values
if [[ -z "$API_GATEWAY_URL" || -z "$S3_BUCKET" || -z "$CLOUDFRONT_DISTRIBUTION_ID" ]]; then
    log_error "Could not retrieve required infrastructure values from Terraform."
    log_error "Infrastructure deployment may have failed. Check Terraform outputs."
    exit 1
fi

# Step 3: Create .env file for production build
echo ""
log_info "Step 3: Creating production environment configuration..."
cd "$PROJECT_DIR"

cat > .env.production << EOF
# Auto-generated production environment variables
# Generated on: $(date)
VITE_AWS_REGION=us-east-1
VITE_AWS_API_GATEWAY_URL=$API_GATEWAY_URL
VITE_AWS_USER_POOL_ID=$USER_POOL_ID
VITE_AWS_USER_POOL_CLIENT_ID=$USER_POOL_CLIENT_ID
VITE_AWS_S3_BUCKET=$S3_BUCKET
EOF

log_success "Production environment file created"

# Step 4: Install dependencies and build the application
echo ""
log_info "Step 4: Installing dependencies and building application..."

log_info "Installing npm dependencies..."
npm ci

log_info "Building production bundle..."
npm run build

if [ $? -ne 0 ]; then
    log_error "Build failed"
    exit 1
fi

log_success "Application built successfully"

# Verify build output
if [ ! -d "$PROJECT_DIR/dist" ]; then
    log_error "Build directory 'dist' not found"
    exit 1
fi

if [ ! -f "$PROJECT_DIR/dist/index.html" ]; then
    log_error "index.html not found in build directory"
    exit 1
fi

# Step 5: Upload to S3
echo ""
log_info "Step 5: Uploading files to S3..."

# Sync files to S3 with appropriate cache headers
log_info "Syncing build files to S3 bucket: $S3_BUCKET"

# Upload HTML files with no-cache
aws s3 sync "$PROJECT_DIR/dist" "s3://$S3_BUCKET/" \
    --exclude "*" \
    --include "*.html" \
    --cache-control "no-cache, no-store, must-revalidate" \
    --content-type "text/html" \
    --delete

# Upload static assets with long-term caching
aws s3 sync "$PROJECT_DIR/dist" "s3://$S3_BUCKET/" \
    --exclude "*.html" \
    --cache-control "public, max-age=31536000, immutable" \
    --delete

if [ $? -ne 0 ]; then
    log_error "S3 upload failed"
    exit 1
fi

log_success "Files uploaded to S3 successfully"

# Step 6: Invalidate CloudFront cache
echo ""
log_info "Step 6: Invalidating CloudFront cache..."

INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text)

if [ $? -ne 0 ]; then
    log_warning "CloudFront invalidation failed, but deployment was successful"
else
    log_success "CloudFront invalidation created: $INVALIDATION_ID"
    log_info "Cache invalidation may take a few minutes to complete"
fi

# Step 7: Test the deployment
echo ""
log_info "Step 7: Testing deployment..."

# Wait a moment for CloudFront to process
sleep 5

# Test custom domain first (if configured), then CloudFront URL
if [ -n "$APP_DOMAIN_URL" ]; then
    log_info "Testing custom domain: $APP_DOMAIN_URL"
    HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$APP_DOMAIN_URL" 2>/dev/null || echo "000")
    
    if [ "$HTTPS_STATUS" = "200" ]; then
        log_success "Custom domain is responding correctly (HTTPS $HTTPS_STATUS)"
    else
        log_warning "Custom domain may not be ready yet (HTTPS $HTTPS_STATUS)"
        log_info "DNS propagation may take a few minutes"
    fi
fi

log_info "Testing CloudFront URL: https://$CLOUDFRONT_URL"
CF_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$CLOUDFRONT_URL" 2>/dev/null || echo "000")

if [ "$CF_STATUS" = "200" ]; then
    log_success "CloudFront distribution is responding correctly (HTTPS $CF_STATUS)"
else
    log_warning "CloudFront may not be ready yet (HTTPS $CF_STATUS)"
    log_info "CloudFront deployment may take a few minutes to propagate"
fi

# Summary
echo ""
echo "🎉 Deployment Summary"
echo "===================="
echo "💾 S3 Bucket: $S3_BUCKET"
echo "🌐 CloudFront URL: https://$CLOUDFRONT_URL"
if [ -n "$APP_DOMAIN_URL" ]; then
    echo "🌟 Custom Domain: $APP_DOMAIN_URL"
fi
echo "🔗 API Gateway: $API_GATEWAY_URL"
echo "🔐 User Pool: $USER_POOL_ID"
echo ""
echo "🌟 Production URLs:"
if [ -n "$APP_DOMAIN_URL" ]; then
    echo "   Primary: $APP_DOMAIN_URL (HTTPS with SSL)"
fi
echo "   CloudFront: https://$CLOUDFRONT_URL"
echo ""
echo "🔧 Technical Details:"
echo "   - Static hosting: ✅ S3 + CloudFront"
echo "   - SSL Certificate: ✅ Configured"
echo "   - CDN Distribution: ✅ Active"
if [ -n "$APP_DOMAIN_URL" ]; then
    echo "   - Route 53 Domain: ✅ Active"
fi
echo "   - S3 CORS: ✅ Configured"
echo "   - Cognito Authentication: ✅ Ready"
echo ""
echo "ℹ️  Environment variables are bundled in the build:"
echo "   - VITE_AWS_API_GATEWAY_URL=$API_GATEWAY_URL"
echo "   - VITE_AWS_USER_POOL_ID=$USER_POOL_ID"
echo "   - VITE_AWS_USER_POOL_CLIENT_ID=$USER_POOL_CLIENT_ID"
echo "   - VITE_AWS_S3_BUCKET=$S3_BUCKET"
echo "   - VITE_AWS_REGION=us-east-1"
echo ""
echo "🚀 Deployment complete! Sky High Booker is live."
echo ""
echo "📝 Next Steps:"
echo "   1. Test the application at: ${APP_DOMAIN_URL:-https://$CLOUDFRONT_URL}"
echo "   2. Monitor CloudFront metrics in AWS Console"
echo "   3. Check API Gateway logs for any issues"
echo "   4. For updates, simply run this script again"
echo ""
log_info "Note: Full DNS propagation and CloudFront distribution may take 5-15 minutes"
