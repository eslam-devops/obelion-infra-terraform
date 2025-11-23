# AWS Region Configuration
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone" {
  description = "Availability zone for resources"
  type        = string
  default     = "us-east-1a"
}

# EC2 Instance Configuration
variable "instance_type" {
  description = "EC2 instance type (t2.micro for free tier)"
  type        = string
  default     = "t2.micro"
}

variable "disk_size" {
  description = "EBS volume size in GB"
  type        = number
  default     = 8
}

# RDS MySQL Configuration
variable "db_instance_class" {
  description = "RDS instance class (db.t3.micro for free tier)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of database"
  type        = string
  default     = "obeliondb"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Master password for RDS"
  type        = string
  sensitive   = true
}
