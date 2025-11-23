# ============================================================
# CloudWatch Alarms and SNS Configuration
# ============================================================
# هذا الملف يحتوي على إعدادات المراقبة والتنبيهات
# - CloudWatch Alarms لـ CPU Utilization
# - SNS Topic لإرسال البريد الإلكتروني
# - تنبيهات لكل EC2 instance

# ============================================================
# SNS Topic - Email Notifications
# ============================================================
# إنشاء SNS Topic لإرسال التنبيهات عبر البريد الإلكتروني

resource "aws_sns_topic" "cpu_alerts" {
  name = "${var.project_name}-cpu-alerts-topic"

  tags = {
    Name = "${var.project_name}-cpu-alerts"
  }
}

# ============================================================
# SNS Topic Subscription - Email
# ============================================================
# الاشتراك في الـ Topic عبر البريد الإلكتروني

resource "aws_sns_topic_subscription" "cpu_alerts_email" {
  topic_arn = aws_sns_topic.cpu_alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email

  # ملاحظة: قد تحتاج للتأكيد على البريد الإلكتروني يدوياً من AWS
}

# ============================================================
# CloudWatch Alarm - Frontend CPU Utilization
# ============================================================
# تنبيه لاستخدام CPU على Frontend EC2 (Uptime Kuma)

resource "aws_cloudwatch_metric_alarm" "frontend_cpu" {
  alarm_name          = "${var.project_name}-frontend-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"  # عدد الفترات المتتالية
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"  # 5 دقائق
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold  # 50%
  
  alarm_description   = "تنبيه عندما يتجاوز استخدام CPU على Frontend 50%"
  alarm_actions       = [aws_sns_topic.cpu_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.frontend.id
  }

  tags = {
    Name = "${var.project_name}-frontend-cpu-alarm"
  }

  depends_on = [aws_instance.frontend]
}

# ============================================================
# CloudWatch Alarm - Backend CPU Utilization
# ============================================================
# تنبيه لاستخدام CPU على Backend EC2 (Laravel)

resource "aws_cloudwatch_metric_alarm" "backend_cpu" {
  alarm_name          = "${var.project_name}-backend-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"  # 5 دقائق
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold  # 50%
  
  alarm_description   = "تنبيه عندما يتجاوز استخدام CPU على Backend 50%"
  alarm_actions       = [aws_sns_topic.cpu_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.backend.id
  }

  tags = {
    Name = "${var.project_name}-backend-cpu-alarm"
  }

  depends_on = [aws_instance.backend]
}

# ============================================================
# CloudWatch Alarm - RDS CPU Utilization
# ============================================================
# تنبيه لاستخدام CPU على RDS MySQL

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-rds-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold  # 50%
  
  alarm_description   = "تنبيه عندما يتجاوز استخدام CPU على RDS 50%"
  alarm_actions       = [aws_sns_topic.cpu_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql.id
  }

  tags = {
    Name = "${var.project_name}-rds-cpu-alarm"
  }

  depends_on = [aws_db_instance.mysql]
}

# ============================================================
# CloudWatch Alarm - Frontend Disk Space
# ============================================================
# تنبيه عندما يقل المساحة الحرة على القرص

resource "aws_cloudwatch_metric_alarm" "frontend_disk_space" {
  alarm_name          = "${var.project_name}-frontend-disk-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "DISK_USED_PERCENT"
  namespace           = "${var.project_name}-metrics"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"  # تنبيه عندما تكون 80% مستخدمة
  
  alarm_description   = "تنبيه عندما تقل المساحة الحرة على Frontend"
  alarm_actions       = [aws_sns_topic.cpu_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.frontend.id
  }

  tags = {
    Name = "${var.project_name}-frontend-disk-alarm"
  }

  depends_on = [aws_instance.frontend]
}

# ============================================================
# CloudWatch Alarm - Backend Disk Space
# ============================================================

resource "aws_cloudwatch_metric_alarm" "backend_disk_space" {
  alarm_name          = "${var.project_name}-backend-disk-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "DISK_USED_PERCENT"
  namespace           = "${var.project_name}-metrics"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  
  alarm_description   = "تنبيه عندما تقل المساحة الحرة على Backend"
  alarm_actions       = [aws_sns_topic.cpu_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.backend.id
  }

  tags = {
    Name = "${var.project_name}-backend-disk-alarm"
  }

  depends_on = [aws_instance.backend]
}

# ============================================================
# Outputs - SNS Topic Information
# ============================================================

output "sns_topic_arn" {
  description = "ARN للـ SNS Topic"
  value       = aws_sns_topic.cpu_alerts.arn
}

output "sns_topic_name" {
  description = "اسم الـ SNS Topic"
  value       = aws_sns_topic.cpu_alerts.name
}