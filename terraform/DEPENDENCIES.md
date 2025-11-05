# Terraform Dependency Management

This document explains the dependency issues and solutions in this Terraform configuration.

## Current Dependencies

### 1. Lambda Functions ➡️ Lambda Packages Directory
- **Issue**: `data.archive_file.lambda_booking_package` expects `../lambda-packages/` directory
- **Solution**: Added `null_resource` to create directory automatically

### 2. ECS Service ➡️ Docker Image in ECR
- **Issue**: ECS service expects `ce11g3-sky-high-booker:latest` image in ECR
- **Impact**: If image doesn't exist, ECS tasks fail to start
- **Solutions**:
  - Use setup script to push initial image
  - Or deploy ECR first, then push image manually

### 3. Lambda Dependencies ➡️ Node.js Packages
- **Issue**: Lambda code expects `node_modules` in source directory
- **Solution**: Run `npm install` in `lambda/bookings/` before Terraform

## Deployment Order

### For New Repository:
```bash
# 1. Create directories and install dependencies
mkdir -p lambda-packages
cd lambda/bookings && npm install && cd ../..

# 2. Deploy core infrastructure
cd terraform
terraform init
terraform apply -target=aws_ecr_repository.sky_high_booker -auto-approve

# 3. Build and push Docker image
docker build -t sky-high-booker .
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com
docker tag sky-high-booker:latest <account>.dkr.ecr.us-east-1.amazonaws.com/ce11g3-sky-high-booker:latest
docker push <account>.dkr.ecr.us-east-1.amazonaws.com/ce11g3-sky-high-booker:latest

# 4. Deploy everything else
terraform apply -auto-approve
```

### For Existing Infrastructure (with state):
```bash
# With state file, Terraform knows what exists
terraform apply -auto-approve
```

## Improvements Made

1. **Added directory creation**: `null_resource` creates `lambda-packages/` automatically
2. **Setup script**: `scripts/setup.sh` handles all dependencies
3. **Documentation**: Clear instructions in `SETUP.md`
4. **Dependency ordering**: Core resources deployed first

## Recommendations

### For Production:
1. **Use specific image tags** instead of `:latest`
2. **Implement CI/CD pipeline** to handle image builds
3. **Use Terraform modules** with proper dependency management
4. **Add image existence checks** in Terraform
5. **Use multi-stage deployment** (core → image → services)

### For Development:
1. **Use setup script** for initial deployment
2. **Maintain local `.env`** with current environment variables
3. **Regular state backup** to prevent infrastructure loss