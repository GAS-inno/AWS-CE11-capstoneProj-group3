# Scripts Directory

This directory contains deployment and utility scripts for Sky High Booker.

## 📁 Directory Structure

```
scripts/
├── deploy-s3.sh         # S3 static website deployment script
├── setup.sh             # Initial infrastructure setup
├── dev.sh               # Development environment script
├── destroy.sh           # Infrastructure teardown script
├── add-sample-data.sh   # Add sample data to DynamoDB
└── new-repo-setup.sh    # New repository setup script
```

## 🚀 Deployment Scripts

### **S3 Deployment** (deploy-s3.sh)
**Primary deployment method for static website**

```bash
# Deploy to S3 + CloudFront
./scripts/deploy-s3.sh
```

**What it does:**
- Deploys infrastructure with Terraform
- Builds the React application
- Uploads files to S3 with proper cache headers
- Invalidates CloudFront cache
- Tests the deployment

**Prerequisites:**
- AWS CLI configured
- Node.js and npm installed
- Terraform deployed

## 🛠️ Utility Scripts

### **Setup Script** (setup.sh)
Initial infrastructure setup for new developers.

```bash
./scripts/setup.sh
```

### **Development Script** (dev.sh)
Run development environment locally.

```bash
./scripts/dev.sh
```

### **Sample Data** (add-sample-data.sh)
Add sample flight data to DynamoDB.

```bash
./scripts/add-sample-data.sh
```

### **Destroy Script** (destroy.sh)
Clean up all infrastructure resources.

```bash
./scripts/destroy.sh
```

## 📝 Common Tasks

### Deploy to Production
```bash
# Deploy everything
./scripts/deploy-s3.sh
```

### Update Application Only
```bash
# Build
npm run build

# Upload to S3
S3_BUCKET=$(cd terraform && terraform output -raw s3_bucket_name)
aws s3 sync ./dist "s3://$S3_BUCKET/" --delete

# Invalidate CloudFront
CF_DIST_ID=$(cd terraform && terraform output -raw cloudfront_distribution_id)
aws cloudfront create-invalidation --distribution-id "$CF_DIST_ID" --paths "/*"
```

### Clean Up
```bash
# Destroy all infrastructure
./scripts/destroy.sh
```
