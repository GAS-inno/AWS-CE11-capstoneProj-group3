# Feature/ysim Branch Auto-Deployment Guide

## Overview
The GitHub Actions workflow has been configured to automatically deploy infrastructure and application when pushing to the `feature/ysim` branch.

## What Happens When You Push to feature/ysim

### 1. **Terraform Infrastructure Deployment**
When you push to `feature/ysim`, the workflow will automatically:

```yaml
Trigger: Push to feature/ysim branch (if terraform/** files change)
```

#### Infrastructure Created:
- ✅ **VPC & Networking**: VPC, subnets, internet gateway, route tables
- ✅ **ECR Repository**: Container registry for Docker images
- ✅ **ECS Cluster**: Fargate cluster for running containers
- ✅ **ECS Service**: Service definition with task definition
- ✅ **Application Load Balancer**: ALB with target groups
- ✅ **Security Groups**: For ECS tasks and ALB
- ✅ **IAM Roles**: ECS task execution and task roles
- ✅ **DynamoDB Tables**: Bookings, flights, payments, user-profiles
- ✅ **Cognito**: User pool and client for authentication
- ✅ **API Gateway**: REST API for backend services
- ✅ **Lambda Functions**: Booking management functions
- ✅ **S3 Bucket**: For application file storage
- ✅ **Route 53 & ACM**: Domain and SSL certificate

### 2. **Docker Image Build & Push**
The workflow automatically:
1. Installs Lambda dependencies
2. Builds Docker image from your Dockerfile
3. Tags image with `latest` and commit SHA
4. Pushes to ECR repository

```bash
# Images pushed:
- {account_id}.dkr.ecr.us-east-1.amazonaws.com/ce11g3-sky-high-booker:latest
- {account_id}.dkr.ecr.us-east-1.amazonaws.com/ce11g3-sky-high-booker:{commit_sha}
```

### 3. **ECS Service Deployment**
After pushing to ECR:
1. Forces new ECS service deployment
2. Waits for service stability
3. Confirms successful deployment

### 4. **Deployment Summary**
GitHub Actions will generate a summary showing:
- All resources created/updated
- Docker deployment status
- Application URLs
- Environment variables
- Next steps

## How to Deploy

### Initial Setup (One-time)
Ensure you have GitHub Secrets configured:
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

### Deploy Steps
1. Make your changes to the code
2. Commit your changes:
   ```bash
   git add .
   git commit -m "Your commit message"
   ```
3. Push to feature/ysim:
   ```bash
   git push origin feature/ysim
   ```
4. Monitor deployment in GitHub Actions tab

## Workflow Triggers

The workflow runs when:
- ✅ Push to `feature/ysim` branch (auto-deploy)
- ✅ Push to `main` branch (auto-deploy)
- ✅ Pull request to `main` (validation only, no deployment)
- ✅ Manual trigger via workflow_dispatch

## Workflow File Location
`.github/workflows/terraform.yml`

## Expected Deployment Time
- Terraform Apply: ~5-10 minutes
- Docker Build & Push: ~3-5 minutes
- ECS Service Update: ~2-3 minutes
- **Total**: ~10-18 minutes

## Accessing Your Application

After successful deployment, you'll receive:

### URLs
- **Application**: `http://{alb-dns-name}` or `https://sky-high-booker.sctp-sandbox.com`
- **API Gateway**: `https://{api-id}.execute-api.us-east-1.amazonaws.com/prod`

### Environment Variables
The workflow output will include all environment variables needed for local development:
```bash
VITE_AWS_REGION=us-east-1
VITE_AWS_USER_POOL_ID={pool-id}
VITE_AWS_USER_POOL_CLIENT_ID={client-id}
VITE_AWS_API_GATEWAY_URL={api-url}
VITE_AWS_S3_BUCKET={bucket-name}
```

## Troubleshooting

### If Deployment Fails

1. **Check GitHub Actions Logs**
   - Go to Actions tab
   - Click on the failed workflow run
   - Review logs for each step

2. **Common Issues**
   - **AWS Credentials**: Verify secrets are set correctly
   - **Terraform State**: Check S3 backend is accessible
   - **Docker Build**: Ensure Dockerfile is valid
   - **ECS Service**: Check CloudWatch logs for container issues

3. **Manual Rollback**
   ```bash
   # If needed, you can manually trigger destroy
   # Go to Actions > Terraform Infrastructure > Run workflow
   # Select: destroy
   ```

### View ECS Logs
```bash
aws logs tail /ecs/ce11g3 --follow --region us-east-1
```

### Check ECS Service Status
```bash
aws ecs describe-services \
  --cluster ce11g3-ecs-cluster \
  --services sky-high-booker \
  --region us-east-1
```

## Monitoring

After deployment, monitor:
- **ECS Console**: Check service health and task status
- **CloudWatch**: View application logs
- **ALB Target Health**: Ensure targets are healthy
- **API Gateway**: Monitor API requests

## Cost Considerations

Resources deployed (estimated monthly costs):
- ECS Fargate (1 task): ~$15-30/month
- ALB: ~$16-25/month
- NAT Gateway: $0 (using public subnets)
- DynamoDB: Pay per request (minimal)
- Lambda: Pay per invocation (minimal)
- ECR: $0.10 per GB/month
- **Estimated Total**: ~$35-60/month

## Next Steps After Deployment

1. ✅ Access application URL
2. ✅ Test authentication with Cognito
3. ✅ Verify API Gateway endpoints
4. ✅ Check database connections
5. ✅ Monitor CloudWatch logs
6. ✅ Set up monitoring and alerts

## Cleanup

To destroy all resources:
1. Go to Actions > Terraform Infrastructure
2. Click "Run workflow"
3. Select branch: `feature/ysim`
4. Select action: `destroy`
5. Click "Run workflow"

---

**Note**: This workflow uses auto-approve for Terraform apply. Review the plan output in GitHub Actions logs before each deployment.
