# Terraform Workspace Configuration Fix

## Problem
When using Terraform workspaces (`dev` and `default`/`prod`), resources must have unique names in AWS. 
Previously, resources didn't include the environment variable in their names, causing conflicts.

## Solution Applied

Updated all resource names to include `${var.environment}` suffix to ensure dev and prod resources are separate:

### Resources Updated:

1. **IAM Roles & Policies:**
   - ✅ `ce11g3-ecs-execution-role` → `ce11g3-ecs-execution-role-${var.environment}`
   - ✅ `ce11g3-ecs-task-role` → `ce11g3-ecs-task-role-${var.environment}`  
   - ✅ `sky-high-booker-cognito-authenticated` → `sky-high-booker-cognito-authenticated-${var.environment}`

2. **DynamoDB Tables:**
   - ✅ `sky-high-booker-bookings` → `sky-high-booker-bookings-${var.environment}`

3. **ECR Repository:**
   - ✅ `ce11g3-sky-high-booker` → `ce11g3-sky-high-booker-${var.environment}`

4. **ECS Resources (Already using `local.prefix`):**
   - ✅ Already includes environment via `local.prefix = "${var.project_name}-${var.environment}"`
   - Examples: `sky-high-booker-dev-alb`, `sky-high-booker-dev-ecs-cluster`

## Next Steps

### Option 1: Start Fresh (Recommended for Clean State)

1. **Switch to dev workspace:**
   ```bash
   cd terraform
   terraform workspace select dev || terraform workspace new dev
   ```

2. **Destroy old resources (if you want to start clean):**
   ```bash
   # Only if you want to rebuild everything
   terraform destroy -var="environment=dev"
   ```

3. **Apply with new naming:**
   ```bash
   terraform plan -var="environment=dev"
   terraform apply -var="environment=dev"
   ```

### Option 2: Keep Existing Resources

If you want to keep existing resources and just fix the state:

1. **For existing prod/default resources:**
   - They will keep working with the default workspace
   - No changes needed

2. **For dev environment:**
   - Create new dev-specific resources with the updated names
   - The existing resources (without -dev suffix) can remain for prod

## Environment Differences

### Dev Environment (`dev` workspace):
- Resources end with `-dev` suffix
- Example: `ce11g3-ecs-execution-role-dev`
- Docker image tags: `dev`, `dev-{commit-sha}`

### Production Environment (`default` workspace):
- Resources end with `-prod` suffix (when environment=prod)
- Example: `ce11g3-ecs-execution-role-prod`
- Docker image tags: `prod`, `prod-{commit-sha}`

## CI/CD Workflow

The GitHub Actions workflow already handles this correctly:

```yaml
env:
  ENVIRONMENT: ${{ github.ref == 'refs/heads/main' && 'prod' || 'dev' }}
```

- Push to `dev` branch → deploys with `environment=dev`
- Push to `main` branch → deploys with `environment=prod`

## Verification

After applying:

```bash
# Check dev resources
terraform workspace select dev
terraform output

# Check prod resources  
terraform workspace select default
terraform output
```

## Important Notes

- ⚠️ **Existing resources without environment suffix will NOT be automatically renamed**
- ⚠️ **You may need to manually clean up old resources or import them**
- ✅ **All new deployments will use environment-specific names**
- ✅ **CD workflow automatically uses correct environment variable**
