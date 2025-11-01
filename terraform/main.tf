# Modern ECS Deployment Configuration
# Based on terraform-aws-modules best practices

locals {
  prefix = var.name_prefix
  
  # Common tags
  common_tags = {
    Environment = var.environment
    Project     = "SkyHighBooker"
    ManagedBy   = "Terraform"
  }
}

# Data sources for AWS account and region info
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# VPC Data - Using existing VPC or default VPC
data "aws_vpc" "selected" {
  count   = var.use_default_vpc ? 1 : 0
  default = true
}

data "aws_vpc" "custom" {
  count = var.use_default_vpc ? 0 : 1
  id    = var.vpc_id != "" ? var.vpc_id : aws_vpc.main.id
}

# Subnets data
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.use_default_vpc ? data.aws_vpc.selected[0].id : data.aws_vpc.custom[0].id]
  }
  
  filter {
    name   = "tag:Name"
    values = var.use_default_vpc ? ["*public*"] : ["*public*", "${var.name_prefix}public*"]
  }
}

data "aws_subnets" "private" {
  count = var.use_default_vpc ? 0 : 1
  
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.custom[0].id]
  }
  
  filter {
    name   = "tag:Name"
    values = ["*private*", "${var.name_prefix}private*"]
  }
}



# ECS Cluster using terraform-aws-modules
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.9.0"

  cluster_name = "${local.prefix}sky-high-booker-cluster"

  # Fargate capacity providers
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 1
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  # ECS Services
  services = {
    sky-high-booker = {
      cpu    = var.ecs_task_cpu
      memory = var.ecs_task_memory

      # Container definition
      container_definitions = {
        sky-high-booker-container = {
          essential = true
          image     = "${aws_ecr_repository.sky_high_booker.repository_url}:latest"
          
          port_mappings = [
            {
              containerPort = 80
              protocol      = "tcp"
            }
          ]

          # Environment variables
          environment = [
            {
              name  = "VITE_SUPABASE_URL"
              value = var.supabase_url
            },
            {
              name  = "VITE_SUPABASE_ANON_KEY"
              value = var.supabase_anon_key
            },
            {
              name  = "ENVIRONMENT"
              value = var.environment
            }
          ]

          # Logging
          log_configuration = {
            logDriver = "awslogs"
            options = {
              awslogs-create-group  = "true"
              awslogs-group         = "/ecs/${local.prefix}sky-high-booker"
              awslogs-region        = data.aws_region.current.name
              awslogs-stream-prefix = "ecs"
            }
          }

          # Health check
          health_check = {
            command     = ["CMD-SHELL", "curl -f http://localhost:80/health || exit 1"]
            interval    = 30
            timeout     = 5
            retries     = 3
            startPeriod = 60
          }
        }
      }

      # Service configuration
      assign_public_ip                   = var.use_default_vpc ? true : false
      deployment_minimum_healthy_percent = 50
      deployment_maximum_percent         = 200
      desired_count                      = var.ecs_desired_count
      
      # Network configuration
      subnet_ids = var.use_default_vpc ? data.aws_subnets.public.ids : data.aws_subnets.private[0].ids
      security_group_ids = [module.ecs_security_group.security_group_id]

      # Load balancer integration
      load_balancer = var.create_alb ? {
        service = {
          target_group_arn = module.alb[0].target_groups["ecs-service"].arn
          container_name   = "sky-high-booker-container"
          container_port   = 80
        }
      } : {}

      # Auto Scaling
      enable_autoscaling       = true
      autoscaling_min_capacity = 1
      autoscaling_max_capacity = 10
      
      autoscaling_policies = {
        cpu = {
          policy_type = "TargetTrackingScaling"
          target_tracking_scaling_policy_configuration = {
            predefined_metric_specification = {
              predefined_metric_type = "ECSServiceAverageCPUUtilization"
            }
            target_value = 70
          }
        }
        memory = {
          policy_type = "TargetTrackingScaling"
          target_tracking_scaling_policy_configuration = {
            predefined_metric_specification = {
              predefined_metric_type = "ECSServiceAverageMemoryUtilization"
            }
            target_value = 80
          }
        }
      }
    }
  }

  tags = local.common_tags
}

# Security Group for ECS tasks
module "ecs_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1.0"

  name        = "${local.prefix}ecs-security-group"
  description = "Security group for Sky High Booker ECS tasks"
  vpc_id      = var.use_default_vpc ? data.aws_vpc.selected[0].id : data.aws_vpc.custom[0].id

  # Ingress rules
  ingress_cidr_blocks = var.create_alb ? [] : ["0.0.0.0/0"]
  ingress_rules       = var.create_alb ? [] : ["http-80-tcp", "https-443-tcp"]
  
  # Ingress from ALB if ALB is created
  computed_ingress_with_source_security_group_id = var.create_alb ? [
    {
      rule                     = "http-80-tcp"
      source_security_group_id = module.alb_security_group[0].security_group_id
    }
  ] : []
  number_of_computed_ingress_with_source_security_group_id = var.create_alb ? 1 : 0

  # Egress rules
  egress_rules = ["all-all"]

  tags = local.common_tags
}

# Application Load Balancer (conditional)
module "alb" {
  count = var.create_alb ? 1 : 0
  
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name               = "${local.prefix}sky-high-booker-alb"
  load_balancer_type = "application"
  vpc_id             = var.use_default_vpc ? data.aws_vpc.selected[0].id : data.aws_vpc.custom[0].id
  subnets            = data.aws_subnets.public.ids
  security_groups    = [module.alb_security_group[0].security_group_id]

  # Target Groups
  target_groups = {
    ecs-service = {
      name             = "${local.prefix}sky-high-booker-tg"
      protocol         = "HTTP"
      port             = 80
      target_type      = "ip"
      
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30
        matcher             = "200"
        path                = "/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 3
      }
    }
  }

  # Listeners
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      
      default_actions = [{
        type             = "forward"
        target_group_key = "ecs-service"
      }]
    }
  }

  tags = local.common_tags
}

# ALB Security Group (conditional)
module "alb_security_group" {
  count = var.create_alb ? 1 : 0
  
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1.0"

  name        = "${local.prefix}alb-security-group"
  description = "Security group for Sky High Booker ALB"
  vpc_id      = var.use_default_vpc ? data.aws_vpc.selected[0].id : data.aws_vpc.custom[0].id

  # Ingress rules
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]

  # Egress rules  
  egress_rules = ["all-all"]

  tags = local.common_tags
}