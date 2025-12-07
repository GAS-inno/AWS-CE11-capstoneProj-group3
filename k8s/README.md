# EKS Setup Guide

## Overview

This project now uses **EKS (Kubernetes) as the primary deployment method**, with ECS as an optional backup. 

## Architecture

- **EKS**: Kubernetes-based, powerful orchestration ✅ (Primary/Default)
- **ECS**: Simpler, AWS-native container service ⚠️ (Backup/Optional)

Both can run simultaneously on the same VPC and share the same ECR repository.

## Enabling EKS

### EKS is Enabled by Default

EKS will be created automatically when you run:

```bash
cd terraform
terraform plan -var="environment=dev"
terraform apply -var="environment=dev"
```

To disable EKS (if you want to use only ECS):
```bash
terraform apply -var="enable_eks=false" -var="environment=dev"
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

### Use EKS (Current Default) When:
- ✅ You need advanced Kubernetes features (StatefulSets, DaemonSets, etc.)
- ✅ Planning multi-cloud or cloud-agnostic deployment
- ✅ Want to use Kubernetes ecosystem (Helm, Operators, etc.)
- ✅ Team has Kubernetes expertise
- ✅ Need fine-grained control over pod scheduling
- ✅ Want industry-standard container orchestration

### Use ECS (Backup) When:
- ✅ You want simpler management
- ✅ Cost is a top concern (no control plane fees with ECS)
- ✅ AWS-native integration is sufficient
- ✅ Team is more familiar with AWS services only

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

You can run both EKS and ECS at the same time:

1. **EKS** serves production traffic (primary, always on)
2. **ECS** as backup or for specific workloads
3. Both use the same:
   - VPC and subnets
   - ECR repository
   - DynamoDB tables
   - Cognito user pools
   - API Gateway

To enable both:
```bash
terraform apply -var="enable_eks=true" -var="enable_ecs=true" -var="environment=dev"
```

## Switching Between EKS and ECS

### Using EKS (Default):

```bash
# EKS is already enabled by default
terraform apply -var="environment=dev"

# Deploy to EKS
kubectl config use-context arn:aws:eks:us-east-1:ACCOUNT_ID:cluster/sky-high-booker-dev-eks-cluster
envsubst < k8s/deployment.yaml | kubectl apply -f -

# Get EKS URL
kubectl get service sky-high-booker-service
```

### To Use ECS as Backup:

```bash
# Enable ECS alongside EKS
terraform apply -var="enable_ecs=true" -var="environment=dev"

# Check ECS status
aws ecs list-services --cluster sky-high-booker-dev-ecs-cluster
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

### To Remove EKS (If Needed):

```bash
# Delete Kubernetes resources first
kubectl delete -f k8s/deployment.yaml

# Then disable EKS via Terraform
terraform apply -var="enable_eks=false" -var="environment=dev"
```

### To Remove ECS (Backup):

```bash
# Disable ECS via Terraform
terraform apply -var="enable_ecs=false" -var="environment=dev"
```

This will keep your EKS setup running (primary) while removing the ECS backup.

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

1. **Deploy with EKS** (default): `terraform apply -var="environment=dev"`
2. **Configure kubectl**: Use the commands above to connect
3. **Deploy app to Kubernetes**: Use the kubectl commands above
4. **Optional: Enable ECS backup**: Add `-var="enable_ecs=true"` if needed

## Recommendation

**EKS is now your primary deployment method!** It provides:
- Industry-standard Kubernetes orchestration
- Flexibility and portability
- Rich ecosystem of tools
- Advanced scheduling and scaling capabilities

**ECS remains available as a backup** if you need a simpler fallback option or want to compare both approaches.
