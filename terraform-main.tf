# ============================================================
# Main Terraform Configuration - AWS Infrastructure
# ============================================================
# يقوم هذا الملف بإنشاء البنية الأساسية للبيئة السحابية
# تم إنشاء VPC جديد مع Subnets عامة وخاصة وRDS MySQL

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

  # التوسيم الافتراضي لجميع الموارد
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  }
}

# ============================================================
# VPC - Virtual Private Cloud
# ============================================================
# إنشاء VPC جديد مع CIDR block 10.0.0.0/16

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# ============================================================
# Internet Gateway
# ============================================================
# يوفر الاتصال بين VPC والإنترنت للشبكات العامة

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ============================================================
# Public Subnet - 10.0.1.0/24
# ============================================================
# شبكة فرعية عامة في منطقة التوفر الأولى
# تستضيف Frontend و Backend EC2 instances

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# ============================================================
# Private Subnet - 10.0.2.0/24
# ============================================================
# شبكة فرعية خاصة لـ RDS MySQL
# معزولة عن الإنترنت - لا يمكن الوصول إليها مباشرة من الخارج

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-private-subnet"
  }
}

# ============================================================
# Route Table for Public Subnet
# ============================================================
# جدول التوجيه للشبكة العامة يربط جميع حركة المرور إلى IGW

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# ربط جدول التوجيه بالشبكة الفرعية العامة
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ============================================================
# Security Groups
# ============================================================

# Security Group for Public EC2 instances
resource "aws_security_group" "public_sg" {
  name        = "${var.project_name}-public-sg"
  description = "Security group for public EC2 instances (Frontend & Backend)"
  vpc_id      = aws_vpc.main.id

  # السماح بـ SSH من أي مكان (يمكن تقييده بـ IP محدد)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # السماح بـ HTTP (Frontend - Uptime Kuma)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # السماح بـ HTTPS (Frontend - Uptime Kuma)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # السماح بـ Backend API (Laravel) على port 8000
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # السماح بـ جميع حركة المرور الخارجة
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-public-sg"
  }
}

# Security Group for RDS MySQL
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS MySQL - Private access only"
  vpc_id      = aws_vpc.main.id

  # السماح بـ MySQL من EC2 instances فقط
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }

  # السماح بـ جميع حركة المرور الخارجة
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# ============================================================
# Data Source - Availability Zones
# ============================================================
# الحصول على قائمة مناطق التوفر المتاحة في الإقليم

data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================================
# IAM Role for EC2 CloudWatch Monitoring
# ============================================================
# دور IAM للسماح بـ EC2 بإرسال المقاييس إلى CloudWatch

resource "aws_iam_role" "ec2_cloudwatch_role" {
  name = "${var.project_name}-ec2-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

# السياسة لـ CloudWatch Agent
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# السياسة لـ SSM (لتثبيت CloudWatch Agent)
resource "aws_iam_role_policy_attachment" "ssm_agent_policy" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_cloudwatch_role.name
}

# ============================================================
# User Data Script - CloudWatch Agent Setup
# ============================================================
# سكريبت لتثبيت وتكوين CloudWatch Agent عند بدء EC2

locals {
  user_data_script = base64encode(<<-EOF
              #!/bin/bash
              set -e
              
              # تحديث النظام
              apt-get update
              apt-get install -y wget curl
              
              # تثبيت CloudWatch Agent
              cd /tmp
              wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
              dpkg -i -E ./amazon-cloudwatch-agent.deb
              
              # إنشاء ملف التكوين للـ CloudWatch Agent
              cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'INNER_EOF'
              {
                "metrics": {
                  "namespace": "${var.project_name}-metrics",
                  "metrics_collected": {
                    "cpu": {
                      "measurement": [
                        {
                          "name": "cpu_usage_idle",
                          "rename": "CPU_IDLE",
                          "unit": "Percent"
                        },
                        {
                          "name": "cpu_usage_iowait",
                          "rename": "CPU_IOWAIT",
                          "unit": "Percent"
                        },
                        "cpu_time_guest"
                      ],
                      "metrics_collection_interval": 60,
                      "resources": ["*"]
                    },
                    "mem": {
                      "measurement": [
                        {
                          "name": "mem_used_percent",
                          "rename": "MEM_USED_PERCENT",
                          "unit": "Percent"
                        }
                      ],
                      "metrics_collection_interval": 60
                    },
                    "disk": {
                      "measurement": [
                        {
                          "name": "used_percent",
                          "rename": "DISK_USED_PERCENT",
                          "unit": "Percent"
                        }
                      ],
                      "metrics_collection_interval": 60,
                      "resources": ["/"]
                    }
                  }
                }
              }
              INNER_EOF
              
              # بدء CloudWatch Agent
              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
                -a fetch-config \
                -m ec2 \
                -s \
                -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
              
              echo "CloudWatch Agent installed and started successfully"
              EOF
  )
}

# ============================================================
# Outputs
# ============================================================
# إظهار معلومات الموارد المهمة بعد الإنشاء

output "vpc_id" {
  description = "معرف VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "معرف الشبكة الفرعية العامة"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "معرف الشبكة الفرعية الخاصة"
  value       = aws_subnet.private.id
}

output "public_security_group_id" {
  description = "معرف مجموعة الأمان للـ EC2"
  value       = aws_security_group.public_sg.id
}

output "rds_security_group_id" {
  description = "معرف مجموعة الأمان لـ RDS"
  value       = aws_security_group.rds_sg.id
}

output "ec2_iam_instance_profile" {
  description = "اسم Instance Profile للـ EC2"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "user_data_script" {
  description = "User data script للـ CloudWatch Agent"
  value       = local.user_data_script
  sensitive   = true
}