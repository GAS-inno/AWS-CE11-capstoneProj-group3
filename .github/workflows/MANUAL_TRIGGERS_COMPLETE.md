# Manual Trigger Capabilities for All Workflows

## ✅ **All Workflows Now Support Manual Triggering!**

Every workflow in your repository now includes `workflow_dispatch` triggers, allowing you to run any pipeline manually from the GitHub Actions interface.

## 🚀 **Workflow Manual Trigger Overview**

### **1. CI - Build and Test** (`ci.yml`) - 🆕 Enhanced
**Manual Trigger Options:**
- **Force Run All Jobs** (`run_all_jobs`): Bypass change detection, run all tests
- **Skip Security Scan** (`skip_security_scan`): Skip security scanning for faster builds

**Use Cases:**
- Full CI validation before important releases
- Quick builds without security scans during development
- Testing CI pipeline changes

### **2. Build and Deploy to ECS** (`deploy.yml`) - ✅ Already Updated
**Manual Trigger Options:**
- **Environment Selection**: Choose dev, staging, or prod
- **Skip Tests**: Emergency deployment option

**Use Cases:**
- Deploy specific branches to any environment
- Emergency hotfix deployments
- Scheduled production releases

### **3. Multi-Environment Deployment** (`deploy-multi-env.yml`) - ✅ Already Available
**Manual Trigger Options:**
- **Environment Selection**: dev, staging, prod
- **Version/Tag Selection**: Deploy specific versions

**Use Cases:**
- Environment promotion workflows
- Rollback to previous versions
- Controlled production deployments

### **4. Terraform Infrastructure** (`terraform.yml`) - ✅ Already Available
**Manual Trigger Options:**
- **Action Selection**: plan, apply, destroy
- **Environment Selection**: dev, staging, prod

**Use Cases:**
- Infrastructure updates and changes
- Environment provisioning
- Infrastructure cleanup

### **5. Legacy CD Pipeline** (`cd.yaml`) - ✅ Already Available (Deprecated)
**Manual Trigger Options:**
- **Confirmation Required**: Must type "confirm" to use

**Use Cases:**
- Backward compatibility only
- Migration testing

## 📋 **How to Trigger Workflows Manually**

### **Step-by-Step Instructions:**

1. **Navigate to Actions Tab**
   - Go to your GitHub repository
   - Click on the **"Actions"** tab

2. **Select Workflow**
   - Choose the workflow you want to run from the left sidebar
   - Click on the workflow name

3. **Run Workflow**
   - Click the **"Run workflow"** button
   - Select the branch (if applicable)
   - Configure the input options
   - Click **"Run workflow"** to start

4. **Monitor Execution**
   - Watch the workflow progress in real-time
   - Check logs and results
   - Review any outputs or notifications

## 🎯 **Workflow Trigger Matrix**

| Workflow | Auto Triggers | Manual Trigger | Key Options |
|----------|--------------|----------------|-------------|
| **CI** | Push, PR | ✅ Yes | Force all jobs, Skip security |
| **Deploy** | Push to main | ✅ Yes | Environment, Skip tests |
| **Multi-Env Deploy** | None | ✅ Yes | Environment, Version |
| **Terraform** | None | ✅ Yes | Action, Environment |
| **Legacy CD** | None | ✅ Yes | Confirmation required |

## 🛠️ **Enhanced CI Workflow Features**

### **Smart Change Detection Override:**
```yaml
# Manual trigger can force all jobs to run
run_all_jobs: true  # Ignores file changes, runs everything
```

### **Flexible Security Scanning:**
```yaml
# Skip security scans for faster development cycles
skip_security_scan: true  # Bypasses npm audit and Snyk
```

### **Automatic vs Manual Behavior:**
- **Automatic (Push/PR)**: Respects change detection, runs only relevant jobs
- **Manual**: Can override change detection, full control over execution

## 🔄 **Common Manual Trigger Scenarios**

### **Development Workflows:**
```
1. Feature Testing:
   - Trigger CI manually on feature branch
   - Use "force run all jobs" for comprehensive testing

2. Quick Validation:
   - Skip security scan for faster feedback
   - Focus on core functionality tests
```

### **Deployment Workflows:**
```
1. Environment Promotion:
   - Deploy from staging to production
   - Use Multi-Environment Deploy workflow

2. Emergency Fixes:
   - Use Deploy workflow with "skip tests"
   - Deploy directly to affected environment

3. Rollbacks:
   - Use Multi-Environment Deploy with specific version
   - Rollback to last known good version
```

### **Infrastructure Management:**
```
1. Infrastructure Updates:
   - Run Terraform workflow with "plan" action
   - Review changes, then run "apply" action

2. Environment Cleanup:
   - Use Terraform "destroy" for temporary environments
   - Clean up unused resources
```

## ⚡ **Quick Reference Commands**

### **Fastest CI Run:**
- Workflow: `CI - Build and Test`
- Options: `skip_security_scan: true`
- Result: Core tests only, fastest feedback

### **Full Validation:**
- Workflow: `CI - Build and Test`  
- Options: `run_all_jobs: true`
- Result: Complete test suite regardless of changes

### **Emergency Deploy:**
- Workflow: `Build and Deploy to ECS`
- Options: `skip_tests: true`, `environment: prod`
- Result: Immediate production deployment

### **Safe Production Deploy:**
- Workflow: `Multi-Environment Deployment`
- Options: `environment: prod`, `version: v1.2.3`
- Result: Controlled production deployment with specific version

## 🔒 **Security & Safety Features**

### **All Manual Triggers Include:**
- ✅ **Input Validation**: All parameters are validated
- ✅ **Audit Trail**: Who triggered what, when
- ✅ **Warning Messages**: Alerts for production/emergency actions
- ✅ **Detailed Logging**: Complete execution history
- ✅ **Rollback Capability**: Can revert changes if needed

### **Production Safeguards:**
- ⚠️ Special warnings for production deployments
- 🔍 Enhanced logging and monitoring
- 👤 Clear identification of deployment trigger
- 📋 Comprehensive deployment summaries

## 🎉 **Benefits of Manual Triggering**

1. **Flexibility**: Run any workflow on any branch, any time
2. **Control**: Override automatic behavior when needed
3. **Emergency Response**: Rapid deployment capabilities for critical fixes
4. **Testing**: Validate workflow changes without code commits
5. **Debugging**: Isolate and test specific pipeline components
6. **Compliance**: Controlled deployments with audit trails

Your GitHub Actions workflows are now fully equipped for both automated CI/CD and on-demand manual operations! 🚀