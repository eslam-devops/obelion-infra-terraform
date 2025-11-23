# ============================================================
# Terraform Variables
# ============================================================
# تعريف جميع المتغيرات التي يتم استخدامها في ملفات Terraform
# يمكن تخصيص هذه القيم في ملف terraform.tfvars

# ============================================================
# AWS Configuration
# ============================================================

variable "aws_region" {
  description = "إقليم AWS"
  type        = string
  default     = "us-east-1"  # يمكن تغييره حسب الحاجة
}

variable "environment" {
  description = "بيئة التطبيق (production/staging/development)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "اسم المشروع - يستخدم في التوسيم"
  type        = string
  default     = "obelion"
}

# ============================================================
# VPC Configuration
# ============================================================

variable "vpc_cidr" {
  description = "CIDR block للـ VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block للشبكة الفرعية العامة"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block للشبكة الفرعية الخاصة"
  type        = string
  default     = "10.0.2.0/24"
}

# ============================================================
# Security Configuration
# ============================================================

variable "allowed_ssh_cidr" {
  description = "CIDR block المسموح له بـ SSH (استخدم IP الخاص بك)"
  type        = string
  default     = "0.0.0.0/0"  # تحذير: غير آمن! استخدم IP محدد في الإنتاج
}

# ============================================================
# EC2 Configuration
# ============================================================

variable "ec2_instance_type" {
  description = "نوع الـ instance للـ EC2"
  type        = string
  default     = "t2.micro"  # الخطة المجانية
}

variable "ec2_root_volume_size" {
  description = "حجم القرص الجذري بـ GB"
  type        = number
  default     = 8
}

# ============================================================
# RDS Configuration
# ============================================================

variable "rds_identifier" {
  description = "معرف instance RDS"
  type        = string
  default     = "obeliondb"
}

variable "rds_instance_class" {
  description = "نوع الـ instance لـ RDS"
  type        = string
  default     = "db.t3.micro"  # الخطة الأقل سعراً
}

variable "rds_storage_size" {
  description = "حجم التخزين بـ GB"
  type        = number
  default     = 20
}

variable "rds_database" {
  description = "اسم قاعدة البيانات الأساسية"
  type        = string
  default     = "obeliondb"
}

variable "rds_username" {
  description = "اسم المستخدم الإداري لـ RDS"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "rds_password" {
  description = "كلمة مرور المستخدم الإداري لـ RDS (يجب أن تكون قوية)"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.rds_password) >= 8
    error_message = "كلمة المرور يجب أن تكون 8 أحرف على الأقل"
  }
}

variable "rds_backup_retention_days" {
  description = "عدد أيام الاحتفاظ بـ النسخ الاحتياطية"
  type        = number
  default     = 7
}

# ============================================================
# CloudWatch & Monitoring
# ============================================================

variable "cpu_alarm_threshold" {
  description = "الحد الأدنى لاستخدام CPU قبل التنبيه (%)"
  type        = number
  default     = 50
}

variable "alarm_email" {
  description = "البريد الإلكتروني لاستقبال التنبيهات"
  type        = string
  sensitive   = true
}