# Dynamic API Gateway URL System

## Overview

The Sky High Booker application now supports **dynamic API Gateway URLs** that automatically update when AWS resources are recreated. This solves the problem of hardcoded URLs becoming invalid when infrastructure is destroyed and recreated daily.

## How It Works

### 1. **Placeholder System**
The frontend code now uses placeholders instead of hardcoded URLs:

```typescript
// Before (hardcoded)
const API_URL = 'https://yfylycs655.execute-api.us-east-1.amazonaws.com/prod';

// After (dynamic placeholder)
const API_URL = import.meta.env.VITE_AWS_API_GATEWAY_URL || 'VITE_AWS_API_GATEWAY_URL_PLACEHOLDER';
```

### 2. **Runtime Environment Injection**
At container startup, the `env-config.sh` script replaces placeholders with actual values:

```bash
# In Docker container at startup
sed -i "s|VITE_AWS_API_GATEWAY_URL_PLACEHOLDER|${VITE_AWS_API_GATEWAY_URL}|g" "$file"
```

### 3. **Terraform Environment Variables**
The ECS task definition automatically provides current values:

```hcl
environment = [
  {
    name  = "VITE_AWS_API_GATEWAY_URL"
    value = "https://${aws_api_gateway_rest_api.booking_api.id}.execute-api.us-east-1.amazonaws.com/prod"
  }
]
```

## Files Updated

### Frontend Files (Placeholders Added)
- `src/pages/Confirmation.tsx` - Booking creation
- `src/pages/MyBookings.tsx` - Booking retrieval  
- `src/pages/SeatSelection.tsx` - Seat availability
- `src/lib/aws-config.ts` - AWS Amplify configuration

### Infrastructure Files
- `terraform/ecs_simplified.tf` - ECS environment variables (already configured)
- `scripts/docker/env-config.sh` - Runtime replacement script (already exists)

### Deployment Automation
- `scripts/deploy.sh` - **New dynamic deployment script**

## Usage

### Quick Deployment
After infrastructure recreation, simply run:

```bash
# From project root
./scripts/deploy.sh
```

This script will:
1. ✅ Get current API Gateway URL from Terraform
2. ✅ Build Docker image with placeholders  
3. ✅ Push to correct ECR repository
4. ✅ Force ECS service redeployment
5. ✅ Monitor deployment status
6. ✅ Test the deployed application

### Manual Steps (if needed)
```bash
# 1. Get current values
cd terraform
terraform output api_gateway_url
terraform output ecr_repository_url

# 2. Build and deploy
cd ..
docker build -t sky-high-booker:latest .
docker tag sky-high-booker:latest <ECR_URL>:latest
docker push <ECR_URL>:latest

# 3. Update ECS service
aws ecs update-service --cluster <CLUSTER> --service <SERVICE> --force-new-deployment
```

## Benefits

### ✅ **Automatic URL Updates**
- No more manual URL changes when infrastructure is recreated
- Environment variables injected at container runtime
- Single source of truth from Terraform outputs

### ✅ **Zero Configuration**
- Developers just run `./scripts/deploy.sh`
- Script automatically detects current infrastructure values
- No need to update multiple files manually

### ✅ **Production Ready**
- Works with daily infrastructure cleanup/recreation
- Handles ECR repository changes automatically  
- Supports different environments (dev/staging/prod)

## Environment Variables Injected

The following environment variables are automatically injected at runtime:

```bash
VITE_AWS_API_GATEWAY_URL=https://<api-id>.execute-api.us-east-1.amazonaws.com/prod
VITE_AWS_USER_POOL_ID=us-east-1_<pool-id>
VITE_AWS_USER_POOL_CLIENT_ID=<client-id>
VITE_AWS_REGION=us-east-1
VITE_AWS_S3_BUCKET=<bucket-name>
```

## Troubleshooting

### Issue: "Error: Could not retrieve required infrastructure values"
**Solution:** Ensure Terraform infrastructure is deployed:
```bash
cd terraform
terraform apply
```

### Issue: "ECR login failed"  
**Solution:** Check AWS credentials and permissions:
```bash
aws sts get-caller-identity
aws configure list
```

### Issue: "ECS service update failed"
**Solution:** Verify ECS cluster and service names:
```bash
aws ecs list-clusters
aws ecs list-services --cluster <cluster-name>
```

## Migration Notes

### Before (Static URLs)
- URLs hardcoded in multiple files
- Manual updates required after infrastructure recreation
- Risk of using stale/incorrect URLs

### After (Dynamic URLs)
- Placeholders in code, real URLs injected at runtime
- Fully automated deployment process
- Always uses current infrastructure values

This system ensures the application will continue working seamlessly even when AWS resources are recreated daily, making the development and deployment process much more robust.