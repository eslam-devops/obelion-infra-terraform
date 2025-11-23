# VPC Configuration - بناء الشبكة الافتراضية
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "obelion-vpc"
    Environment = var.environment
  }
}

# Internet Gateway - بوابة الانترنااز
 resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "obelion-igw"
  }
}

# Public Subnet - Subnet عامة للاشتراف
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "obelion-public-subnet"
  }
}

# Private Subnet - Subnet خاصة للبياناات
 resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "obelion-private-subnet"
  }
}

# Data source for AZ
data "aws_availability_zones" "available" {
  state = "available"
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.main.id
  }
  tags = {
    Name = "obelion-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security_groups"
  vpc_id = aws_vpc.main.id
}

# Frontend EC2 Instance - مستودع الواجهة
resource "aws_instance" "frontend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [module.security_groups.frontend_sg_id]
  associate_public_ip_address = true
  
  tags = {
    Name = "obelion-frontend"
  }
}

# Backend EC2 Instance - مستودع الباكاند
resource "aws_instance" "backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [module.security_groups.backend_sg_id]
  associate_public_ip_address = true
  
  tags = {
    Name = "obelion-backend"
  }
}

# DB Subnet Group - مجموعة Subnets للبياناات
resource "aws_db_subnet_group" "main" {
  name       = "obelion-db-subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.public.id]
  tags = {
    Name = "obelion-db-subnet-group"
  }
}

# RDS MySQL Database - بايناات MySQL عبر RDSresource "aws_db_instance" "main" {
  engine               = "mysql"
  engine_version       = "8.0.35"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "gp2"
  db_name              = "obeliondb"
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [module.security_groups.rds_sg_id]
  publicly_accessible  = false
  skip_final_snapshot  = true
  
  tags = {
    Name = "obelion-mysql"
  }
}

# Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
