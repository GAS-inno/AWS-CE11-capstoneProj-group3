# GitHub Actions Workflows

This directory contains the CI/CD workflows for the Sky High Booker application, based on the patterns from [jaezeu/ecs-deployment](https://github.com/jaezeu/ecs-deployment).

## 🚀 Workflows Overview

### 1. **CI - Build and Test** (`ci.yml`)
**Triggers:** Push/PR to main, develop, feature branches
- ✅ **Change Detection**: Only runs relevant jobs based on file changes
- 🧪 **Frontend Tests**: Type checking, linting, unit tests (Node 18 & 20)
- 🐳 **Docker Build Test**: Validates container builds and startup
- 🏗️ **Terraform Validation**: Format checking and validation
- 🔒 **Security Scanning**: npm audit and Snyk vulnerability checks
- ⚡ **Quality Gates**: Ensures all checks pass before allowing merges

### 2. **Build and Deploy to ECS** (`deploy.yml`)
**Triggers:** Push to main branch
- 🧪 **Test Phase**: Runs all tests before deployment
- 🏗️ **Build**: Compiles React app and creates production build
- 📦 **Docker Build**: Creates and pushes container to ECR
- 🚀 **ECS Deploy**: Updates ECS service with new container image
- ✅ **Health Checks**: Verifies deployment success

### 3. **Multi-Environment Deployment** (`deploy-multi-env.yml`)
**Triggers:** Manual workflow dispatch
- 🌍 **Environment Selection**: Deploy to dev, staging, or prod
- 📋 **Version Control**: Deploy specific versions or latest
- 🔧 **Environment-specific Builds**: Different configurations per environment
- 🧪 **Smoke Tests**: Post-deployment validation
- 📊 **Deployment Summary**: Detailed status reporting

### 4. **Terraform Infrastructure** (`terraform.yml`)
**Triggers:** Manual workflow dispatch
- 📋 **Action Selection**: Plan, Apply, or Destroy infrastructure
- 🌍 **Environment Management**: Environment-specific deployments
- 📝 **Plan Visualization**: Shows changes in PR comments
- ✅ **Validation**: Format checking and validation
- 🔄 **State Management**: Handles Terraform state properly

### 5. **Legacy CD Pipeline** (`cd.yaml`) - ⚠️ Deprecated
- Preserved for backward compatibility
- Requires explicit confirmation to use
- Recommends migration to new workflows

## 🔧 Setup Requirements

### GitHub Secrets Required:
```bash
AWS_ACCESS_KEY_ID       # AWS Access Key
AWS_SECRET_ACCESS_KEY   # AWS Secret Key
SNYK_TOKEN             # Snyk security scanning (optional)
```

### GitHub Environments:
Create these environments in your repository settings:
- `dev` - Development environment
- `staging` - Staging environment  
- `prod` - Production environment

### Repository Variables:
Configure these in repository settings if needed:
- `AWS_REGION` (default: us-east-1)
- `NODE_VERSION` (default: 18)

## 📋 Package.json Scripts Required

Ensure your `package.json` includes these scripts:
```json
{
  "scripts": {
    "build": "vite build",
    "build:staging": "vite build --mode staging",
    "build:prod": "vite build --mode production",
    "test": "vitest",
    "test:unit": "vitest run",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "type-check": "tsc --noEmit"
  }
}
```

## 🌊 Workflow Patterns

### Standard Development Flow:
1. **Feature Development**: 
   - Create feature branch → `ci.yml` runs tests
   - Create PR → `ci.yml` validates changes
   - Merge to main → `deploy.yml` deploys to dev

2. **Environment Promotion**:
   - Manual trigger `deploy-multi-env.yml` for staging
   - Manual trigger `deploy-multi-env.yml` for production

3. **Infrastructure Changes**:
   - Use `terraform.yml` to plan/apply infrastructure changes
   - Review plans in PR comments before applying

### Emergency Deployments:
- Use `deploy-multi-env.yml` with specific version input
- Deploy to any environment immediately
- Includes automated smoke tests

## 🔄 Migration from Legacy

If upgrading from the old `cd.yaml` workflow:

1. **Review Variables**: Update any hardcoded values
2. **Test New Workflows**: Run `ci.yml` on a feature branch
3. **Deploy Infrastructure**: Use `terraform.yml` for infrastructure
4. **Deploy Application**: Use `deploy.yml` for main deployments
5. **Disable Legacy**: Remove `cd.yaml` when comfortable

## 🚀 Best Practices

### Branch Protection:
```yaml
# Recommended branch protection rules for main:
required_status_checks:
  - "Frontend Tests"
  - "Docker Build Test" 
  - "Terraform Validate"
  - "Security Scanning"
```

### Environment-Specific Configurations:

#### Development:
- Auto-deploy on main branch push
- Full test suite execution
- Security scanning enabled

#### Staging:
- Manual deployment trigger
- Production-like configuration
- Performance testing (if configured)

#### Production:
- Manual deployment with approvals
- Blue-green deployment strategy
- Enhanced monitoring and alerting

## 🔍 Troubleshooting

### Common Issues:

1. **ECR Repository Not Found**:
   ```bash
   # Ensure ECR repository exists
   aws ecr describe-repositories --repository-names ce11g3-sky-high-booker
   ```

2. **ECS Service Not Found**:
   ```bash
   # Deploy infrastructure first
   cd terraform && terraform apply
   ```

3. **Docker Build Fails**:
   ```bash
   # Check Dockerfile and build locally
   npm run build
   docker build -t test-image .
   ```

4. **Terraform Backend Issues**:
   ```bash
   # Ensure S3 bucket exists
   aws s3 ls s3://sctp-ce11-tfstate
   ```

### Monitoring Deployments:
- Check GitHub Actions tab for workflow status
- Monitor ECS service in AWS console
- Use ALB health checks for application status
- Check CloudWatch logs for application errors

## 📚 Additional Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Reference Repository](https://github.com/jaezeu/ecs-deployment)