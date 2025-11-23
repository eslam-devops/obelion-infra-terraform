# AWS Region متغير
variable "aws_region" {
  type        = string
  default     = "eu-central-1"
  description = "AWS region to deploy resources"
}

# VPC CIDR Block
variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for VPC"
}

# Public Subnet CIDR
variable "public_subnet_cidr" {
  type        = string
  default     = "10.0.1.0/24"
  description = "CIDR block for public subnet"
}

# Private Subnet CIDR
variable "private_subnet_cidr" {
  type        = string
  default     = "10.0.2.0/24"
  description = "CIDR block for private subnet (RDS)"
}

# EC2 Instance Type
variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type for Frontend and Backend"
}

# Database Username
variable "db_username" {
  type        = string
  default     = "admin"
  description = "RDS MySQL master username"
}

# Database Password - مهم: ليس آمن تماما لخزن الباسورد هنا!
variable "db_password" {
  type        = string
  description = "RDS MySQL master password - use environment variable TF_VAR_db_password"
  sensitive   = true
}

# Environment tag
variable "environment" {
  type        = string
  default     = "production"
  description = "Environment name for tagging resources"
}
