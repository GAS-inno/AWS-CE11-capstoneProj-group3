#!/bin/bash

# Sky High Booker - New Repository Setup Script
# This script customizes the project for a new repository/team

set -e

echo "🚀 Sky High Booker - New Repository Setup"
echo "========================================"

# Get project details
echo "Please provide the following information for your deployment:"
echo ""

# Get name prefix (should be unique to avoid conflicts)
read -p "Enter your unique name prefix (e.g., team1-, myorg-): " NAME_PREFIX
if [ -z "$NAME_PREFIX" ]; then
    NAME_PREFIX="skyhigh-"
    echo "Using default prefix: $NAME_PREFIX"
fi

# Get AWS region (optional)
read -p "Enter AWS region [us-east-1]: " AWS_REGION
if [ -z "$AWS_REGION" ]; then
    AWS_REGION="us-east-1"
fi

# Get custom domain (optional)
read -p "Enter custom domain name (leave blank to use ALB only): " CUSTOM_DOMAIN

echo ""
echo "Configuration Summary:"
echo "====================="
echo "Name Prefix: $NAME_PREFIX"
echo "AWS Region: $AWS_REGION"
echo "Custom Domain: ${CUSTOM_DOMAIN:-'Not configured (will use ALB DNS)'}"
echo ""

read -p "Continue with this configuration? (y/N): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Setup cancelled"
    exit 0
fi

# Update Terraform variables
echo "📝 Updating Terraform configuration..."

# Update name prefix
sed -i "s/default.*=.*\"ce11g3-\"/default = \"${NAME_PREFIX}\"/" terraform/variable.tf

# Update AWS region if different
if [ "$AWS_REGION" != "us-east-1" ]; then
    sed -i "s/default.*=.*\"us-east-1\"/default = \"${AWS_REGION}\"/" terraform/variable.tf
fi

# Update Route 53 configuration if custom domain provided
if [ -n "$CUSTOM_DOMAIN" ]; then
    echo "⚠️  Note: You'll need to update Route 53 configuration manually"
    echo "   Edit terraform/route53.tf to use your domain: $CUSTOM_DOMAIN"
    echo "   Make sure you have a hosted zone for this domain"
else
    # Comment out Route 53 resources if no custom domain
    echo "🔧 Disabling Route 53 configuration (no custom domain)..."
    
    # Create a simple script to comment out Route 53 resources
    cat > disable_route53.tf <<EOF
# Route 53 configuration disabled - using ALB DNS only
# To enable custom domain:
# 1. Create Route 53 hosted zone for your domain
# 2. Uncomment and update route53.tf
# 3. Run terraform apply
EOF
    
    # Move route53.tf to backup
    if [ -f "terraform/route53.tf" ]; then
        mv terraform/route53.tf terraform/route53.tf.disabled
        mv disable_route53.tf terraform/
    fi
fi

# Update backend configuration for unique state file
echo "💾 Updating Terraform backend configuration..."
BACKEND_KEY="${NAME_PREFIX}terraform.tfstate"
sed -i "s/key.*=.*\"ce11g3.tfstate\"/key = \"${BACKEND_KEY}\"/" terraform/provider.tf

echo ""
echo "✅ Repository setup complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Commit and push your changes:"
echo "   git add ."
echo "   git commit -m 'Initial Sky High Booker setup'"
echo "   git push origin main"
echo ""
echo "2. Make sure AWS CLI is configured:"
echo "   aws configure"
echo ""
echo "3. Deploy the application:"
echo "   ./scripts/deploy.sh"
echo ""
echo "🎯 Your deployment will use:"
echo "   - Name prefix: $NAME_PREFIX"
echo "   - AWS region: $AWS_REGION"
echo "   - Backend state: s3://sctp-ce11-tfstate/${BACKEND_KEY}"
if [ -n "$CUSTOM_DOMAIN" ]; then
    echo "   - Custom domain: $CUSTOM_DOMAIN (requires manual Route 53 setup)"
else
    echo "   - Access via: ALB DNS name (will be provided after deployment)"
fi
echo ""
echo "🚀 Ready to deploy Sky High Booker!"