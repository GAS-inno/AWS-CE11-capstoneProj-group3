# Simplified ECS Configuration based on jaezeu/ecs-deployment reference
# This replaces the complex main.tf ECS configuration

# Create a simple VPC for ECS (since default VPC doesn't exist)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.tags, {
    Name = "${local.prefix}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags, {
    Name = "${local.prefix}-igw"
  })
}

# Public subnets (2 AZs for ALB requirement)
resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "${local.prefix}-public-${count.index + 1}"
    Type = "Public"
  })
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.tags, {
    Name = "${local.prefix}-public-rt"
  })
}

# Associate route table with public subnets
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Use the created VPC and subnets
locals {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# ECR Repository for our container images
resource "aws_ecr_repository" "ecr" {
  name         = "${local.prefix}-ecr"
  force_delete = true

  tags = local.tags
}

# ECS Cluster and Service using terraform-aws-modules
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.9.0"

  cluster_name = "${local.prefix}-ecs-cluster"

  # Use only Fargate (simpler than Fargate + Spot)
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  services = {
    sky-high-booker = { # Service name
      cpu    = 512
      memory = 1024

      # Container definition - simplified to avoid circular dependencies
      container_definitions = {
        sky-high-booker-container = {
          essential = true
          image     = "nginx:alpine" # Use a simple image for initial deployment

          port_mappings = [
            {
              containerPort = 80
              protocol      = "tcp"
            }
          ]

          # Basic environment - resource IDs will be updated after deployment
          environment = [
            {
              name  = "AWS_DEFAULT_REGION"
              value = "us-east-1"
            }
          ]

          # Health check
          health_check = {
            command = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
          }
        }
      }

      # Network configuration
      assign_public_ip   = true
      subnet_ids         = local.subnet_ids
      security_group_ids = [module.ecs_sg.security_group_id]

      # Load balancer configuration
      load_balancer = {
        service = {
          target_group_arn = aws_lb_target_group.ecs.arn
          container_name   = "sky-high-booker-container"
          container_port   = 80
        }
      }
    }
  }

  tags = local.tags
}

# Security group for ECS tasks
module "ecs_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1.0"

  name        = "${local.prefix}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = local.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp"]
  egress_rules        = ["all-all"]

  tags = local.tags
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${local.prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.alb_sg.security_group_id]
  subnets            = local.subnet_ids

  enable_deletion_protection = false

  tags = local.tags
}

# Security group for ALB
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1.0"

  name        = "${local.prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = local.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  egress_rules        = ["all-all"]

  tags = local.tags
}

# Target Group for ECS service
resource "aws_lb_target_group" "ecs" {
  name        = "${local.prefix}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = local.tags
}

# ALB Listener
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }
}