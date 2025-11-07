# Sky High Booker - Deployment Guide

## 🚀 One-Click Complete Deployment

This deployment script handles everything from infrastructure creation to application deployment automatically.

### Prerequisites

Before running the deployment script, ensure you have:

1. **AWS CLI** installed and configured
   ```bash
   aws configure
   # Enter your AWS Access Key ID, Secret Access Key, region (us-east-1), and output format (json)
   ```

2. **Docker** installed and running
   ```bash
   docker --version
   docker info  # Should show Docker daemon info
   ```

3. **Terraform** installed
   ```bash
   terraform --version
   ```

4. **Sufficient AWS Permissions** for:
   - VPC, EC2, and networking resources
   - ECS, ECR, and load balancing
   - Lambda, API Gateway
   - DynamoDB, S3
   - Route 53, ACM (SSL certificates)
   - IAM roles and policies
   - Cognito user pools

### 🎯 Complete Deployment

To deploy everything from scratch:

```bash
cd AWS-CE11-capstoneProj-group3
./scripts/deploy.sh
```

This single script will:

1. ✅ **Check Prerequisites** - Validate AWS CLI, Docker, Terraform
2. 🏗️ **Deploy Infrastructure** - Create all AWS resources in correct order
3. 📋 **Get Configuration** - Extract dynamic values (API Gateway URLs, etc.)
4. 🔨 **Build Application** - Create Docker image with dynamic configuration
5. 📦 **Push to ECR** - Upload container to AWS container registry
6. 🔄 **Deploy ECS Service** - Launch application containers
7. ⏳ **Monitor Deployment** - Wait for containers to be healthy
8. 🧪 **Test Application** - Verify endpoints are responding
9. 📊 **Show Summary** - Display all URLs and configuration

### 📋 Deployment Stages

The script deploys infrastructure in stages to handle dependencies:

#### Stage 1: Core Infrastructure
- VPC, subnets, internet gateway
- IAM roles and policies
- S3 bucket for application storage
- DynamoDB table for bookings
- Cognito user pools for authentication
- ECR repositories for container images

#### Stage 2: API Services
- API Gateway REST API
- Lambda functions (CRUD operations)

#### Stage 3: API Integration
- API Gateway routes and integrations
- Lambda permissions and triggers
- API deployment and staging

#### Stage 4: Domain & SSL
- Route 53 DNS records
- ACM SSL certificate
- Certificate validation

#### Stage 5: Load Balancing
- Application Load Balancer
- Target groups
- HTTP and HTTPS listeners
- ECS cluster creation

#### Stage 6: Application Deployment
- ECS task definitions
- ECS services with auto-scaling
- Final configuration

### 🌐 Access Your Application

After successful deployment, access your application at:

- **Production URL**: `https://sky-high-booker.sctp-sandbox.com`
- **Load Balancer**: `http://[alb-dns-name]` (redirects to HTTPS)

### 🔧 Dynamic Configuration

The application uses runtime environment variable injection:

- `VITE_AWS_API_GATEWAY_URL` - Automatically set to current API Gateway
- `VITE_AWS_USER_POOL_ID` - Cognito User Pool ID
- `VITE_AWS_USER_POOL_CLIENT_ID` - Cognito App Client ID
- `VITE_AWS_S3_BUCKET` - S3 bucket name
- `VITE_AWS_REGION` - AWS region (us-east-1)

This means the application automatically adapts to infrastructure changes without rebuilding.

### 📊 Monitoring Deployment

The script provides real-time status updates:

```
🚀 Sky High Booker - Complete Deployment Script
===============================================
ℹ️  Checking prerequisites...
✅ All prerequisites satisfied
🏗️  Step 1: Deploying Infrastructure...
📦 Stage 1: Core infrastructure (VPC, IAM, S3, etc.)...
🌐 Stage 2: API Gateway and Lambda functions...
🔗 Stage 3: API Gateway integration...
🌍 Stage 4: Route 53 and SSL Certificate...
⚖️  Stage 5: Load Balancer and ECS...
🚀 Stage 6: Final deployment...
✅ Infrastructure deployment completed!
```

### 🔄 Re-deployment

To update the application after code changes:

```bash
./scripts/deploy.sh
```

The script intelligently detects existing infrastructure and:
- Updates infrastructure if needed
- Rebuilds and pushes new Docker image
- Forces ECS service to deploy new containers
- Maintains zero-downtime deployment

### 🧹 Infrastructure Cleanup

To completely remove all infrastructure:

```bash
./scripts/destroy.sh
```

⚠️ **WARNING**: This will destroy ALL resources including data in DynamoDB and S3!

### 🛠️ Manual Operations

#### View Infrastructure Status
```bash
cd terraform
terraform show
terraform output
```

#### Check ECS Service Status
```bash
aws ecs describe-services --cluster sky-high-booker-dev-ecs-cluster --services sky-high-booker
```

#### View Application Logs
```bash
aws logs tail /aws/ecs/sky-high-booker/sky-high-booker-container --follow
```

#### Test API Endpoints
```bash
curl https://[api-gateway-url]/prod/bookings
```

### 🐛 Troubleshooting

#### Common Issues:

1. **"Error: Terraform state not found"**
   - Run the full deployment script - it handles initialization

2. **"Docker build failed"**
   - Ensure Docker is running
   - Check Dockerfile syntax and dependencies

3. **"ECR login failed"**
   - Verify AWS credentials have ECR permissions
   - Check AWS region is set to us-east-1

4. **"ECS service deployment failed"**
   - Check ECS task logs in AWS Console
   - Verify container image was pushed successfully

5. **"Certificate validation timeout"**
   - DNS propagation can take up to 5 minutes
   - Check Route 53 hosted zone permissions

#### Getting Help:

1. Check CloudWatch logs for detailed error messages
2. Review Terraform plan output for resource conflicts
3. Verify AWS service quotas and limits
4. Ensure all prerequisites are properly installed

### 🎯 Production Considerations

For production use, consider:

- Set up CloudWatch monitoring and alarms
- Configure backup strategies for DynamoDB and S3
- Implement CI/CD pipelines for automated deployments
- Review and tighten IAM permissions
- Set up WAF for additional security
- Configure auto-scaling policies based on load

### 📁 Project Structure

```
AWS-CE11-capstoneProj-group3/
├── scripts/
│   ├── deploy.sh      # Complete deployment script
│   ├── destroy.sh     # Infrastructure cleanup script
│   └── setup.sh       # Initial setup utilities
├── terraform/         # Infrastructure as Code
├── static-website/    # Frontend React application
└── Dockerfile        # Container configuration
```