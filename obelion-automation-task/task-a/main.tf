# Task Group A - Terraform Configuration
# تكوين موارد AWS الأساسية للتطبيق
# - Backend EC2 Instance
# - Frontend EC2 Instance
# - MySQL RDS Database

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "Production"
      Project     = "Obelion"
      ManagedBy   = "Terraform"
    }
  }
}

# VPC Configuration
resource "aws_vpc" "obelion" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "obelion-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "obelion" {
  vpc_id = aws_vpc.obelion.id

  tags = {
    Name = "obelion-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.obelion.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "obelion-public-subnet"
  }
}

# Private Subnet for RDS
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.obelion.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "obelion-private-subnet"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.obelion.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.obelion.id
  }

  tags = {
    Name = "obelion-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# DB Subnet Group
resource "aws_db_subnet_group" "obelion" {
  name       = "obelion-db-subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.public.id]

  tags = {
    Name = "obelion-db-subnet-group"
  }
}

# Security Group for EC2
resource "aws_security_group" "ec2" {
  name        = "obelion-ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.obelion.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "obelion-ec2-sg"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "obelion-rds-sg"
  description = "Security group for RDS MySQL"
  vpc_id      = aws_vpc.obelion.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "obelion-rds-sg"
  }
}

# Data source for Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Backend EC2 Instance
resource "aws_instance" "backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.disk_size
    delete_on_termination = true
  }

  tags = {
    Name = "obelion-backend"
  }
}

# Frontend EC2 Instance
resource "aws_instance" "frontend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.disk_size
    delete_on_termination = true
  }

  tags = {
    Name = "obelion-frontend"
  }
}

# RDS MySQL Instance
resource "aws_db_instance" "mysql" {
  identifier              = "obelion-mysql"
  engine                  = "mysql"
  engine_version          = "8.0.35"
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.obelion.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  publicly_accessible     = false
  skip_final_snapshot     = true
  multi_az                = false

  tags = {
    Name = "obelion-mysql"
  }
}
