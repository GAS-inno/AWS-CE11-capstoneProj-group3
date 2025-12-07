# EKS Setup Guide

## Overview

This project now supports **both ECS and EKS** deployments. EKS is disabled by default to avoid the $73/month control plane cost.

## Architecture

- **ECS**: Simpler, cheaper, AWS-native container orchestration ✅ (Currently Active)
- **EKS**: Kubernetes-based, more powerful, cloud-agnostic ⚠️ (Optional)

Both can run simultaneously on the same VPC and share the same ECR repository.

## Enabling EKS

### Step 1: Enable in Terraform

Edit `terraform/variable.tf` or pass via command line:

```bash
cd terraform
terraform plan -var="enable_eks=true" -var="environment=dev"
terraform apply -var="enable_eks=true" -var="environment=dev"
```

Or add to `terraform.tfvars`:
```hcl
enable_eks = true
```

### Step 2: Wait for Cluster Creation

EKS cluster creation takes approximately **15-20 minutes**.

### Step 3: Configure kubectl

After Terraform completes, configure kubectl to connect to your cluster:

```bash
# Get cluster name from Terraform output
aws eks update-kubeconfig --region us-east-1 --name sky-high-booker-dev-eks-cluster

# Verify connection
kubectl get nodes
```

### Step 4: Deploy Application to EKS

```bash
# Set environment variables
export ENVIRONMENT=dev
export ECR_REPOSITORY_URL=$(terraform output -raw ecr_repository_url)
export COGNITO_USER_POOL_ID=$(terraform output -raw cognito_user_pool_id)
export COGNITO_CLIENT_ID=$(terraform output -raw cognito_client_id)
export API_GATEWAY_URL=$(terraform output -raw api_gateway_url)

# Apply Kubernetes manifests with environment substitution
envsubst < k8s/deployment.yaml | kubectl apply -f -

# Check deployment status
kubectl get pods
kubectl get services
```

### Step 5: Get LoadBalancer URL

```bash
# Wait for LoadBalancer to be provisioned (takes 2-3 minutes)
kubectl get service sky-high-booker-service --watch

# Get the external URL
kubectl get service sky-high-booker-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## EKS vs ECS: When to Use What

### Use ECS (Current Default) When:
- ✅ You want simpler management
- ✅ Cost is a concern (no control plane fees)
- ✅ AWS-native integration is sufficient
- ✅ Team is more familiar with AWS services

### Use EKS When:
- ✅ You need advanced Kubernetes features (StatefulSets, DaemonSets, etc.)
- ✅ Planning multi-cloud or cloud-agnostic deployment
- ✅ Want to use Kubernetes ecosystem (Helm, Operators, etc.)
- ✅ Team has Kubernetes expertise
- ✅ Need fine-grained control over pod scheduling

## Cost Comparison

### ECS:
- Control Plane: **$0/month** (free)
- Task compute: ~$15-30/month (t3.medium Fargate)
- **Total: ~$15-30/month**

### EKS:
- Control Plane: **$73/month** (fixed cost)
- Node compute: ~$30-50/month (2x t3.medium nodes)
- **Total: ~$103-123/month**

## Running Both Simultaneously

You can run both ECS and EKS at the same time:

1. **ECS** serves production traffic (main/prod environment)
2. **EKS** for testing Kubernetes features (dev environment)
3. Both use the same:
   - VPC and subnets
   - ECR repository
   - DynamoDB tables
   - Cognito user pools
   - API Gateway

## Switching Between ECS and EKS

### To Use EKS for Dev Environment:

```bash
# Enable EKS
terraform apply -var="enable_eks=true" -var="environment=dev"

# Deploy to EKS
kubectl config use-context arn:aws:eks:us-east-1:ACCOUNT_ID:cluster/sky-high-booker-dev-eks-cluster
envsubst < k8s/deployment.yaml | kubectl apply -f -

# Get EKS URL
kubectl get service sky-high-booker-service
```

### To Use ECS for Prod Environment:

```bash
# ECS already running (default)
# Check status
aws ecs list-services --cluster ce11g3-ecs-cluster
```

## Useful kubectl Commands

```bash
# Check cluster info
kubectl cluster-info

# List all resources
kubectl get all

# View logs
kubectl logs -f deployment/sky-high-booker

# Scale deployment
kubectl scale deployment sky-high-booker --replicas=3

# Rollback deployment
kubectl rollout undo deployment/sky-high-booker

# Delete resources
kubectl delete -f k8s/deployment.yaml
```

## Cleanup

### To Remove EKS (Save Costs):

```bash
# Delete Kubernetes resources first
kubectl delete -f k8s/deployment.yaml

# Then destroy EKS via Terraform
terraform apply -var="enable_eks=false" -var="environment=dev"
```

This will keep your ECS setup running while removing the EKS cluster.

## Troubleshooting

### Pods Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>
```

### Can't Pull ECR Image

```bash
# Ensure nodes have ECR read permissions (already configured in Terraform)
kubectl get nodes
kubectl describe node <node-name> | grep iam
```

### LoadBalancer Pending

```bash
# Check service events
kubectl describe service sky-high-booker-service

# Ensure security groups allow traffic
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=*eks-node-sg*"
```

## Next Steps

1. **Try EKS** in dev environment: `terraform apply -var="enable_eks=true"`
2. **Deploy app to Kubernetes**: Use the kubectl commands above
3. **Compare**: Test both ECS and EKS to see which fits better
4. **Decide**: Keep one or both based on your needs

## Recommendation

**For this project**: Stick with **ECS** unless you specifically need Kubernetes features. ECS is:
- Simpler to manage
- More cost-effective
- Sufficient for your use case
- Already working perfectly

**Try EKS** if you want to learn Kubernetes or plan to scale to more complex microservices.
