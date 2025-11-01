# Infrastructure Documentation

This document explains the AWS infrastructure architecture for Sky High Booker, implemented using Terraform with modern AWS modules.

## 🏗️ Architecture Overview

Sky High Booker uses a **serverless container architecture** built on AWS ECS Fargate, providing:
- **High availability** across multiple Availability Zones
- **Auto-scaling** based on CPU and memory utilization
- **Load balancing** with health checks
- **Secure networking** with VPC and security groups
- **Container registry** with lifecycle policies

## 📊 Infrastructure Components

### **High-Level Architecture**
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   CloudFront    │────│  Application     │────│     Supabase    │
│   (Optional)    │    │  Load Balancer   │    │   (External)    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │   Target Group   │
                       │  (Health Check)  │
                       └──────────────────┘
                                │
                                ▼
                    ┌─────────────────────────┐
                    │      ECS Fargate        │
                    │   ┌─────────────────┐   │
                    │   │  React App      │   │
                    │   │  (Container)    │   │
                    │   └─────────────────┘   │
                    └─────────────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │  ECR Repository  │
                       │ (Docker Images)  │
                       └──────────────────┘
```

## 🔧 Terraform Configuration

### **File Structure**
```
terraform/
├── backend.tf           # Remote state configuration
├── provider.tf          # AWS provider setup  
├── main.tf             # Core infrastructure modules
├── variable.tf         # Input variables
├── output.tf           # Output values
└── terraform.tfvars   # Variable values (not in repo)
```

### **Key Resources**

#### **1. ECS Fargate Cluster (`main.tf`)**
```hcl
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.9.0"

  cluster_name = var.cluster_name

  # Fargate capacity providers
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  # ECS Service
  services = {
    sky-high-booker = {
      # Task definition
      cpu    = 512
      memory = 1024
      
      # Container configuration
      container_definitions = {
        sky-high-booker = {
          image                    = "${aws_ecr_repository.app_repository.repository_url}:latest"
          port_mappings = [{
            name          = "sky-high-booker"
            containerPort = 80
            protocol      = "tcp"
          }]
        }
      }

      # Service configuration
      desired_count = 2
      
      # Load balancer integration
      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups["ex-service"].arn
          container_name   = "sky-high-booker"
          container_port   = 80
        }
      }

      # Auto-scaling
      enable_autoscaling       = true
      autoscaling_min_capacity = 1
      autoscaling_max_capacity = 5
    }
  }
}
```

#### **2. Application Load Balancer**
```hcl
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name               = "${var.app_name}-alb"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [module.alb_security_group.security_group_id]

  # Target groups
  target_groups = {
    ex-service = {
      name_prefix = "srv-"
      port        = 80
      protocol    = "HTTP"
      
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        unhealthy_threshold = 2
      }
    }
  }

  # Listeners
  listeners = {
    ex-http = {
      port     = 80
      protocol = "HTTP"
      
      forward = {
        target_group_key = "ex-service"
      }
    }
  }
}
```

#### **3. VPC and Networking**
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.app_name}-vpc"
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  enable_vpn_gateway = false
  
  enable_dns_hostnames = true
  enable_dns_support   = true
}
```

#### **4. Security Groups**
```hcl
module "alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1.0"

  name        = "${var.app_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP from anywhere"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS from anywhere"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}
```

#### **5. ECR Repository**
```hcl
resource "aws_ecr_repository" "app_repository" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "app_repository_policy" {
  repository = aws_ecr_repository.app_repository.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["latest"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
```

## 🔒 Remote State Configuration

### **Backend Setup (`backend.tf`)**
```hcl
terraform {
  backend "s3" {
    bucket         = "sky-high-booker-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### **State Management Commands**
```bash
# Initialize backend
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Show current state
terraform show

# List resources
terraform state list

# Import existing resource
terraform import aws_s3_bucket.example bucket-name
```

## 📈 Scaling Configuration

### **Auto Scaling Policies**
```hcl
# CPU-based scaling
resource "aws_appautoscaling_policy" "cpu_scaling" {
  name               = "${var.app_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Memory-based scaling
resource "aws_appautoscaling_policy" "memory_scaling" {
  name               = "${var.app_name}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80.0
  }
}
```

## 🔧 Deployment Process

### **1. Infrastructure Deployment**
```bash
cd terraform/

# Initialize Terraform
terraform init

# Plan infrastructure changes
terraform plan -var-file="terraform.tfvars"

# Apply changes
terraform apply -var-file="terraform.tfvars"

# Get outputs
terraform output
```

### **2. Application Deployment**
```bash
# Build and push Docker image
./scripts/deploy-ecs.sh

# Or trigger via GitHub Actions
# Push to main branch or trigger manually
```

### **3. Rolling Updates**
- ECS automatically handles rolling updates
- New task definitions replace old ones gradually
- Zero-downtime deployments with health checks
- Automatic rollback on failed health checks

## 🔍 Monitoring and Logging

### **CloudWatch Integration**
```hcl
# ECS Service logs
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 14
}

# ALB access logs
resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.app_name}-alb-access-logs"
}
```

### **Monitoring Metrics**
- **ECS Service**: CPU, Memory, Running Tasks
- **ALB**: Request Count, Target Response Time, HTTP Errors
- **ECR**: Push/Pull metrics
- **Auto Scaling**: Scaling activities

### **Alarms Setup**
```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.app_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors ECS CPU utilization"
}
```

## 💰 Cost Optimization

### **Fargate Spot Usage**
- 50% Fargate Spot instances for cost savings
- Automatic failover to regular Fargate
- Suitable for non-critical workloads

### **Resource Right-Sizing**
```hcl
# Current configuration
cpu    = 512    # 0.5 vCPU
memory = 1024   # 1 GB RAM

# For higher traffic:
cpu    = 1024   # 1 vCPU  
memory = 2048   # 2 GB RAM
```

### **ECR Lifecycle Policies**
- Automatic cleanup of old images
- Keeps last 10 tagged images
- Reduces storage costs

## 🔒 Security Best Practices

### **Network Security**
- VPC with private subnets for ECS tasks
- NAT Gateway for outbound internet access
- Security groups with minimal required access
- No direct SSH access (containerized environment)

### **IAM Roles**
```hcl
# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.app_name}-ecs-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}
```

### **Container Security**
- ECR image scanning enabled
- Multi-stage Docker builds
- Non-root user in containers
- Minimal base images

## 🚀 Performance Optimization

### **Load Balancer Configuration**
- Health checks every 30 seconds
- 2 consecutive healthy checks required
- Automatic unhealthy target removal
- Cross-zone load balancing enabled

### **ECS Service Configuration**
- Desired count: 2 (minimum for HA)
- Rolling deployment strategy
- 50% deployment configuration
- Grace period for health checks

### **Caching Strategy**
- Static assets served from container
- Browser caching headers
- Optional CloudFront integration

## 🔄 Disaster Recovery

### **Backup Strategy**
- Terraform state in S3 with versioning
- ECR images retained with lifecycle policy
- Infrastructure as Code for quick recovery
- Multi-AZ deployment for high availability

### **Recovery Procedures**
1. **Service Failure**: ECS auto-recovery and health checks
2. **Infrastructure Failure**: Terraform re-deployment
3. **Data Loss**: Supabase handles database backups
4. **Region Failure**: Manual deployment to different region

## 📋 Maintenance Tasks

### **Regular Operations**
```bash
# Update Terraform modules
terraform init -upgrade

# Plan and apply updates
terraform plan && terraform apply

# Monitor resource usage
aws ecs describe-services --cluster sky-high-booker-cluster

# Check ECR repository size
aws ecr describe-repositories --repository-names sky-high-booker
```

### **Troubleshooting Commands**
```bash
# Check ECS service status
aws ecs describe-services --cluster sky-high-booker-cluster --services sky-high-booker

# View ECS task logs
aws logs tail /ecs/sky-high-booker --follow

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn arn:aws:...

# ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin
```