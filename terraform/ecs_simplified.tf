# Simplified ECS Configuration based on jaezeu/ecs-deployment reference
# This replaces the complex main.tf ECS configuration

# Use default VPC (persistent, not deleted daily)
data "aws_vpc" "default" {
  default = true
}

# Get default subnets from the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
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
      subnet_ids         = data.aws_subnets.default.ids
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
  vpc_id      = data.aws_vpc.default.id

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
  subnets            = data.aws_subnets.default.ids

  enable_deletion_protection = false

  tags = local.tags
}

# Security group for ALB
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1.0"

  name        = "${local.prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = data.aws_vpc.default.id

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
  vpc_id      = data.aws_vpc.default.id
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