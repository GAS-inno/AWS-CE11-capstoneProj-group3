# Sky High Booker - Setup Guide for New Developers

## 🚨 **Important: Dependency Setup Required**

This repository has infrastructure dependencies that must be resolved before running `terraform apply`.

### **Prerequisites:**
1. AWS CLI configured with appropriate permissions
2. Docker installed and running
3. Terraform installed
4. Node.js 18+ (for Lambda functions)

### **Initial Setup Steps:**

#### **Step 1: Create Lambda Packages Directory**
```bash
mkdir -p lambda-packages
```

#### **Step 2: Install Lambda Dependencies**
```bash
cd lambda/bookings
npm install
cd ../../
```

#### **Step 3: Initial Infrastructure Deployment**
```bash
cd terraform
terraform init
terraform apply -target=aws_ecr_repository.sky_high_booker -auto-approve
terraform apply -target=aws_dynamodb_table.bookings -target=aws_dynamodb_table.flights -auto-approve
```

#### **Step 4: Build and Push Initial Docker Image**
```bash
# Get ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build and push image
docker build -t sky-high-booker .
docker tag sky-high-booker:latest <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/ce11g3-sky-high-booker:latest
docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/ce11g3-sky-high-booker:latest
```

#### **Step 5: Deploy Complete Infrastructure**
```bash
terraform apply -auto-approve
```

### **Known Dependencies:**
- **ECR Repository** must exist before ECS deployment
- **Docker image** must be pushed to ECR before ECS tasks can start
- **Lambda packages** directory must exist
- **DynamoDB tables** should be created before Lambda functions

### **Troubleshooting:**
If you encounter "image not found" errors:
1. Check ECR repository exists: `aws ecr describe-repositories --region us-east-1`
2. Verify image is pushed: `aws ecr list-images --repository-name ce11g3-sky-high-booker --region us-east-1`
3. Ensure ECS service is using correct image URI

### **Production Deployment:**
For production deployments, consider:
1. Using specific image tags instead of `:latest`
2. Implementing proper CI/CD pipeline
3. Using Terraform modules with proper dependency management
4. Adding health checks and monitoring