# Deployment Scripts

This directory contains all deployment and utility scripts for the Sky High Booker application.

## 📁 Directory Structure

```
scripts/
├── docker/              # Docker-related configuration files
│   ├── nginx.conf       # Nginx configuration for production
│   └── env-config.sh    # Runtime environment variable setup
├── deploy-ecs.sh        # ECS Fargate deployment script  
├── deploy.sh            # S3 static website deployment script (legacy)
└── dev.sh              # Local development setup script
```

## 🚀 Deployment Scripts

### **ECS Deployment** (`deploy-ecs.sh`)
**Primary deployment method for containerized application**

```bash
# Deploy to ECS Fargate
./scripts/deploy-ecs.sh

# Or make executable and run
chmod +x scripts/deploy-ecs.sh
scripts/deploy-ecs.sh
```

**What it does:**
- Builds the React application
- Creates Docker image
- Pushes to ECR repository
- Updates ECS service
- Monitors deployment status

**Prerequisites:**
- AWS CLI configured
- Docker installed
- ECS infrastructure deployed via Terraform

### **S3 Static Deployment** (`deploy.sh`) - *Legacy*
**Alternative deployment method for static hosting**

```bash
# Deploy to S3 static website
./scripts/deploy.sh
```

**What it does:**
- Builds the React application
- Syncs files to S3 bucket
- Sets up S3 website configuration

**Note:** This is legacy deployment. Use ECS deployment for production.

### **Development Setup** (`dev.sh`)
**Local development environment setup**

```bash
# Start development environment
./scripts/dev.sh
```

**What it does:**
- Installs dependencies
- Starts development server
- Opens browser to application

## 🐳 Docker Configuration

### **Nginx Configuration** (`docker/nginx.conf`)
Production-ready Nginx configuration for serving the React application:
- Gzip compression enabled
- Security headers configured
- Single Page Application routing support
- Static asset caching
- Health check endpoint

### **Environment Configuration** (`docker/env-config.sh`)
Runtime environment variable injection script:
- Replaces placeholder values in built application
- Supports dynamic configuration without rebuild
- Handles Supabase and other external service URLs

## 📋 Usage Examples

### **Local Development**
```bash
# Quick start
scripts/dev.sh

# Manual setup
npm install
npm run dev
```

### **Production Deployment**
```bash
# Deploy to ECS (recommended)
scripts/deploy-ecs.sh

# Deploy to S3 (legacy)
scripts/deploy.sh
```

### **Docker Build & Test**
```bash
# Build Docker image locally
docker build -t sky-high-booker .

# Test Docker container
docker run -p 3000:80 sky-high-booker
```

## 🔧 Script Customization

### **Environment Variables**
Scripts support these environment variables:

```bash
# AWS Configuration
AWS_REGION=us-east-1
AWS_PROFILE=default

# Application Configuration  
ECR_REPOSITORY=ce11g3-sky-high-booker
ECS_CLUSTER=ce11g3-sky-high-booker-cluster
ECS_SERVICE=ce11g3-sky-high-booker-cluster-sky-high-booker

# Supabase Configuration
VITE_SUPABASE_URL=your-supabase-url
VITE_SUPABASE_ANON_KEY=your-supabase-key
```

### **Script Modification**
To customize deployment behavior:
1. Copy the script to a new name (e.g., `deploy-staging.sh`)
2. Modify environment variables
3. Update resource names for target environment
4. Test thoroughly before use

## 🐛 Troubleshooting

### **Common Issues:**

**Script not executable:**
```bash
chmod +x scripts/*.sh
```

**AWS credentials not configured:**
```bash
aws configure
# or
export AWS_PROFILE=your-profile
```

**Docker build fails:**
```bash
# Clear Docker cache
docker system prune -a

# Rebuild image
docker build --no-cache -t sky-high-booker .
```

**ECS deployment stuck:**
```bash
# Check ECS service status
aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE

# Check CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/ecs/"
```

## 📚 Related Documentation

- [Infrastructure Setup](../docs/infrastructure/README.md)
- [Development Guide](../docs/development/setup.md)
- [Deployment Guide](../docs/deployment/README.md)
- [GitHub Actions](../docs/github-actions.md)