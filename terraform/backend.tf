# Backend configuration for remote state management
terraform {
  backend "s3" {
    bucket = "sctp-ce11-tfstate"
    key    = "ce11g3.tfstate" #Change this
    region = "us-east-1"
  }
}