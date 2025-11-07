variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "region" {
  description = "AWS region (alias for backward compatibility)"
  type        = string
  default     = "us-east-1"
}
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  default = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  default = "10.0.2.0/24"
}

variable "private_subnet_1_cidr" {
  default = "10.0.4.0/24"
}

variable "private_subnet_2_cidr" {
  default = "10.0.5.0/24"
}

variable "name_prefix" {
  type        = string
  description = "name of app"
  default     = "ce11g3-"
}

# DynamoDB variables (tables are created with project_name prefix)
# No additional configuration needed - DynamoDB is serverless

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "sky-high-booker"
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

variable "ecs_task_cpu" {
  description = "CPU units for ECS task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256
}

variable "ecs_task_memory" {
  description = "Memory for ECS task in MiB (512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192)"
  type        = number
  default     = 512
}

variable "use_default_vpc" {
  description = "Whether to use the default VPC or create a new one"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID to use (leave empty to use created VPC)"
  type        = string
  default     = ""
}

variable "create_alb" {
  description = "Whether to create Application Load Balancer"
  type        = bool
  default     = true
}
