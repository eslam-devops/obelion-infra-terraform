# ============================================================
# EC2 Instances Configuration
# ============================================================
# هذا الملف يحتوي على إعدادات الـ EC2 instances
# - Frontend EC2 (Uptime Kuma)
# - Backend EC2 (Laravel PHP)

# ============================================================
# AMI Data Source - Ubuntu 22.04
# ============================================================
# البحث عن آخر صورة AMI لـ Ubuntu 22.04

data "aws_ami" "ubuntu_22_04" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ============================================================
# Frontend EC2 Instance - Uptime Kuma
# ============================================================
# مواصفات:
# - OS: Ubuntu 22.04
# - Instance Type: t2.micro (1 vCPU, 1 GB RAM)
# - Storage: 8 GB
# - الوصول: Public IP
# - التطبيق: Uptime Kuma (عبر Docker Compose)

resource "aws_instance" "frontend" {
  # المواصفات الأساسية
  ami                    = data.aws_ami.ubuntu_22_04.id
  instance_type          = var.ec2_instance_type  # t2.micro
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  
  # IAM Role for CloudWatch
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # تخزين الجذر
  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.ec2_root_volume_size  # 8 GB
    delete_on_termination = true
  }

  # السماح بـ IP عام
  associate_public_ip_address = true

  # User Data - تثبيت Docker و Docker Compose و Uptime Kuma
  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e
              
              # تحديث النظام
              apt-get update
              apt-get upgrade -y
              
              # تثبيت Docker
              apt-get install -y \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
              
              # إضافة Docker GPG key
              mkdir -p /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              
              # إضافة Docker Repository
              echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              
              # تحديث و تثبيت Docker
              apt-get update
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
              
              # تثبيت Docker Compose (standalone)
              curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              
              # إنشاء مجلد Uptime Kuma
              mkdir -p /opt/uptime-kuma
              cd /opt/uptime-kuma
              
              # إنشاء docker-compose.yml لـ Uptime Kuma
              cat > docker-compose.yml <<'COMPOSE_EOF'
              version: '3.8'
              services:
                uptime-kuma:
                  image: louislam/uptime-kuma:latest
                  ports:
                    - "3001:3001"
                  volumes:
                    - uptime-kuma-data:/app/data
                  restart: always
                  environment:
                    - TIMEZONE=UTC
              
              volumes:
                uptime-kuma-data:
              COMPOSE_EOF
              
              # بدء Uptime Kuma
              docker-compose up -d
              
              # تثبيت CloudWatch Agent
              apt-get install -y wget
              cd /tmp
              wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
              dpkg -i -E ./amazon-cloudwatch-agent.deb
              
              echo "Frontend setup completed successfully!"
              EOF
  )

  tags = {
    Name = "${var.project_name}-frontend"
    Role = "Frontend-Uptime-Kuma"
  }

  depends_on = [
    aws_internet_gateway.main
  ]
}

# ============================================================
# Backend EC2 Instance - Laravel PHP
# ============================================================
# مواصفات:
# - OS: Ubuntu 22.04
# - Instance Type: t2.micro (1 vCPU, 1 GB RAM)
# - Storage: 8 GB
# - الوصول: Public IP
# - التطبيق: Laravel PHP

resource "aws_instance" "backend" {
  # المواصفات الأساسية
  ami                    = data.aws_ami.ubuntu_22_04.id
  instance_type          = var.ec2_instance_type  # t2.micro
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  
  # IAM Role for CloudWatch
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # تخزين الجذر
  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.ec2_root_volume_size  # 8 GB
    delete_on_termination = true
  }

  # السماح بـ IP عام
  associate_public_ip_address = true

  # User Data - تثبيت PHP و Laravel
  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e
              
              # تحديث النظام
              apt-get update
              apt-get upgrade -y
              
              # تثبيت PHP و الامتدادات المطلوبة
              apt-get install -y \
                php8.1-cli \
                php8.1-common \
                php8.1-fpm \
                php8.1-mysql \
                php8.1-zip \
                php8.1-gd \
                php8.1-mbstring \
                php8.1-curl \
                php8.1-xml \
                php8.1-bcmath \
                php8.1-json \
                curl \
                git \
                unzip
              
              # تثبيت Composer
              curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
              
              # تثبيت Nginx
              apt-get install -y nginx
              
              # إنشاء مجلد للتطبيق
              mkdir -p /var/www/laravel-app
              cd /var/www/laravel-app
              
              # إنشاء ملف .env وهمي (يجب تحديثه لاحقاً)
              cat > .env <<'ENV_EOF'
              APP_NAME="Laravel Backend"
              APP_ENV=production
              APP_DEBUG=false
              APP_KEY=base64:dummy
              APP_URL=http://localhost:8000
              
              DB_CONNECTION=mysql
              DB_HOST=${var.rds_endpoint}
              DB_PORT=3306
              DB_DATABASE=${var.rds_database}
              DB_USERNAME=${var.rds_username}
              DB_PASSWORD=${var.rds_password}
              
              CACHE_DRIVER=file
              SESSION_DRIVER=file
              QUEUE_DRIVER=sync
              ENV_EOF
              
              # إعطاء الصلاحيات المناسبة
              chown -R www-data:www-data /var/www/laravel-app
              chmod -R 755 /var/www/laravel-app
              chmod -R 775 /var/www/laravel-app/storage
              chmod -R 775 /var/www/laravel-app/bootstrap/cache
              
              # تكوين Nginx
              cat > /etc/nginx/sites-available/default <<'NGINX_EOF'
              server {
                  listen 80 default_server;
                  listen [::]:80 default_server;
              
                  server_name _;
              
                  root /var/www/laravel-app/public;
                  index index.php index.html;
              
                  location / {
                      try_files \$uri \$uri/ /index.php?\$query_string;
                  }
              
                  location ~ \.php\$ {
                      include snippets/fastcgi-php.conf;
                      fastcgi_pass unix:/run/php/php8.1-fpm.sock;
                  }
              
                  location ~ /\.ht {
                      deny all;
                  }
              }
              NGINX_EOF
              
              # بدء الخدمات
              systemctl restart nginx
              systemctl restart php8.1-fpm
              systemctl enable nginx
              systemctl enable php8.1-fpm
              
              # تثبيت CloudWatch Agent
              apt-get install -y wget
              cd /tmp
              wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
              dpkg -i -E ./amazon-cloudwatch-agent.deb
              
              echo "Backend setup completed successfully!"
              EOF
  )

  tags = {
    Name = "${var.project_name}-backend"
    Role = "Backend-Laravel-PHP"
  }

  depends_on = [
    aws_internet_gateway.main,
    aws_db_instance.mysql
  ]
}

# ============================================================
# Elastic IPs for EC2 Instances
# ============================================================
# حجز Elastic IPs للـ EC2 للاستقرار

resource "aws_eip" "frontend" {
  instance = aws_instance.frontend.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-frontend-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_eip" "backend" {
  instance = aws_instance.backend.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-backend-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

# ============================================================
# Outputs - EC2 Information
# ============================================================

output "frontend_public_ip" {
  description = "IP العام لـ Frontend EC2 (Uptime Kuma)"
  value       = aws_eip.frontend.public_ip
}

output "frontend_instance_id" {
  description = "معرف instance Frontend"
  value       = aws_instance.frontend.id
}

output "backend_public_ip" {
  description = "IP العام لـ Backend EC2 (Laravel)"
  value       = aws_eip.backend.public_ip
}

output "backend_instance_id" {
  description = "معرف instance Backend"
  value       = aws_instance.backend.id
}

output "uptime_kuma_url" {
  description = "رابط الوصول لـ Uptime Kuma"
  value       = "http://${aws_eip.frontend.public_ip}:3001"
}

output "laravel_app_url" {
  description = "رابط الوصول لـ Laravel App"
  value       = "http://${aws_eip.backend.public_ip}:80"
}