variable "region" {
  default = "us-east-1"
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

variable "ec2_instance_type" {
  default = "t2.micro"
}

variable "ec2_ami" {
  default = "ami-0341d95f75f311023"  # Amazon Linux 2 us-east-1
}

variable "key_name" {
  description = "Your existing EC2 key pair name"
  default     = "ce11g3"

}

variable "name_prefix" {
   type = string
   description = "name of app"
   default = "saw-"
}
