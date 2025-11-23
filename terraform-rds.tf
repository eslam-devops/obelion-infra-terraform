# ============================================================
# RDS MySQL Configuration
# ============================================================
# هذا الملف يحتوي على إعدادات قاعدة البيانات
# MySQL Community 8 مع أقل خطة (db.t3.micro)
# معزول في الشبكة الفرعية الخاصة - لا يمكن الوصول من الإنترنت

# ============================================================
# RDS Subnet Group
# ============================================================
# مجموعة Subnet لـ RDS - يجب أن تكون في شبكات فرعية مختلفة

resource "aws_db_subnet_group" "main" {
  name           = "${var.project_name}-db-subnet-group"
  subnet_ids     = [aws_subnet.private.id, aws_subnet.public.id]  # Failover subnet
  description    = "Subnet group for RDS MySQL database"

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# ============================================================
# RDS MySQL Instance
# ============================================================
# مواصفات:
# - Engine: MySQL Community 8.0
# - Instance Class: db.t3.micro (أقل خطة)
# - Storage: 20 GB (الحد الأدنى)
# - Availability: Single AZ (في البداية)
# - عدم الوصول من الإنترنت

resource "aws_db_instance" "mysql" {
  # المعرف والمحرك
  identifier              = var.rds_identifier
  engine                  = "mysql"
  engine_version          = "8.0.35"  # آخر إصدار 8.0
  instance_class          = var.rds_instance_class  # db.t3.micro
  
  # التخزين
  allocated_storage       = var.rds_storage_size  # 20 GB
  storage_type            = "gp2"
  storage_encrypted       = false  # يمكن تفعيل later
  
  # قاعدة البيانات
  db_name                 = var.rds_database
  username                = var.rds_username
  password                = var.rds_password
  parameter_group_name    = aws_db_parameter_group.mysql.name
  
  # الشبكة والأمان
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  publicly_accessible     = false  # لا يمكن الوصول من الإنترنت
  
  # النسخ الاحتياطي والصيانة
  backup_retention_period = var.rds_backup_retention_days
  backup_window          = "03:00-04:00"  # UTC time
  maintenance_window     = "sun:04:00-sun:05:00"  # UTC time
  
  # الخيارات الإضافية
  skip_final_snapshot         = false
  final_snapshot_identifier   = "${var.rds_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  auto_minor_version_upgrade  = true
  deletion_protection         = false
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  
  tags = {
    Name = "${var.project_name}-mysql-db"
  }

  depends_on = [
    aws_security_group.rds_sg
  ]
}

# ============================================================
# RDS Parameter Group
# ============================================================
# مجموعة المعاملات لـ MySQL - تحتوي على إعدادات مخصصة

resource "aws_db_parameter_group" "mysql" {
  name   = "${var.project_name}-mysql-params"
  family = "mysql8.0"
  
  # معاملات مخصصة
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
  
  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }
  
  parameter {
    name  = "slow_query_log"
    value = "1"
  }
  
  parameter {
    name  = "long_query_time"
    value = "2"
  }
  
  tags = {
    Name = "${var.project_name}-mysql-param-group"
  }
}

# ============================================================
# Outputs - RDS Information
# ============================================================

output "rds_endpoint" {
  description = "RDS MySQL endpoint للاتصال"
  value       = aws_db_instance.mysql.endpoint
}

output "rds_address" {
  description = "عنوان RDS MySQL"
  value       = aws_db_instance.mysql.address
}

output "rds_port" {
  description = "منفذ RDS MySQL"
  value       = aws_db_instance.mysql.port
}

output "rds_database_name" {
  description = "اسم قاعدة البيانات"
  value       = aws_db_instance.mysql.db_name
}

output "rds_username" {
  description = "اسم المستخدم الإداري"
  value       = aws_db_instance.mysql.username
  sensitive   = true
}

output "rds_password" {
  description = "كلمة مرور المستخدم الإداري"
  value       = aws_db_instance.mysql.password
  sensitive   = true
}

output "rds_engine_version" {
  description = "إصدار محرك MySQL"
  value       = aws_db_instance.mysql.engine_version
}

output "rds_availability_zone" {
  description = "منطقة التوفر لـ RDS"
  value       = aws_db_instance.mysql.availability_zone
}