# مشروع البنية السحابية والتطبيقات - توثيق شامل
# Complete DevOps Infrastructure & Automation Documentation

---

## 📋 نظرة عامة على المشروع
## Project Overview

هذا المشروع يقوم بإنشاء بنية سحابية متكاملة على AWS مع أتمتة كاملة للنشر والمراقبة.

This project creates a complete cloud infrastructure on AWS with full deployment automation and monitoring.

### المكونات الرئيسية / Main Components:

**Task Group A: البنية الأساسية / Infrastructure**
- VPC 10.0.0.0/16 مع شبكات فرعية عامة وخاصة
- Frontend EC2 (Uptime Kuma) - 1 core, 1GB RAM, 8GB disk
- Backend EC2 (Laravel PHP) - 1 core, 1GB RAM, 8GB disk
- RDS MySQL 8 في شبكة خاصة آمنة

**Task Group B: التطبيقات و الأتمتة / CI/CD & Automation**
- GitHub Actions للـ Frontend - بناء ونشر Uptime Kuma
- GitHub Actions للـ Backend - نشر Laravel مع Database Migrations
- CloudWatch للمراقبة - تنبيهات CPU > 50%
- SNS لإرسال البريد الإلكتروني للتنبيهات

---

## 🏗️ ملفات Terraform

### 1. terraform-main.tf - البنية الأساسية
**الموارد:**
- VPC: 10.0.0.0/16
- Internet Gateway (IGW)
- Route Tables و Route Associations
- Security Groups (عام وخاص)
- IAM Roles للـ EC2 CloudWatch Agent

### 2. terraform-ec2.tf - الخوادم
**الموارد:**
- Frontend EC2 (Ubuntu 22.04, t2.micro)
  - Docker و Docker Compose مثبتان
  - Uptime Kuma يعمل على port 3001
- Backend EC2 (Ubuntu 22.04, t2.micro)
  - PHP 8.1 مثبت
  - Nginx كـ Web Server
  - Laravel في /var/www/laravel-app
- Elastic IPs لكلا الخادمين

### 3. terraform-rds.tf - قاعدة البيانات
**الموارد:**
- RDS MySQL 8.0.35
- Instance Class: db.t3.micro (الأقل سعراً)
- Storage: 20 GB
- Private Subnet (10.0.2.0/24)
- غير قابل للوصول من الإنترنت

### 4. terraform-monitoring.tf - المراقبة
**الموارد:**
- SNS Topic لـ Email Notifications
- CloudWatch Alarms:
  - Frontend CPU > 50%
  - Backend CPU > 50%
  - RDS CPU > 50%
  - Disk Space > 80%

### 5. terraform-variables.tf - المتغيرات
**المتغيرات المهمة:**
- aws_region: us-east-1
- project_name: obelion
- rds_password: (حساس)
- alarm_email: (لاستقبال التنبيهات)

---

## 🚀 خطوات النشر / Deployment Steps

### المتطلبات الأساسية / Prerequisites:
```bash
# تثبيت Terraform
brew install terraform  # macOS
choco install terraform  # Windows
apt-get install terraform  # Linux

# تثبيت AWS CLI
pip install awscli

# إعداد AWS Credentials
aws configure
# أدخل:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region: us-east-1
# - Default output format: json
```

### نشر البنية السحابية / Deploy Infrastructure:
```bash
# 1. الذهاب إلى مجلد Terraform
cd terraform/

# 2. تهيئة Terraform
terraform init

# 3. إنشاء ملف terraform.tfvars
cat > terraform.tfvars <<EOF
aws_region         = "us-east-1"
project_name       = "obelion"
rds_password       = "YourStrongPassword123!"  # يجب أن تكون قوية جداً
alarm_email        = "your-email@example.com"
allowed_ssh_cidr   = "YOUR_IP/32"  # استبدل بـ IP الخاص بك
EOF

# 4. عرض التغييرات المخطط لها
terraform plan

# 5. تطبيق التكوين
terraform apply

# 6. الحصول على المخرجات
terraform output
```

### النتائج المتوقعة / Expected Output:
```
frontend_public_ip = "X.X.X.X"
backend_public_ip  = "X.X.X.X"
uptime_kuma_url    = "http://X.X.X.X:3001"
laravel_app_url    = "http://X.X.X.X"
rds_endpoint       = "obeliondb.xxxxx.us-east-1.rds.amazonaws.com:3306"
```

---

## 🔧 إعداد GitHub Actions

### Task B1: Frontend Deployment (Uptime Kuma)

**الملف:** `.github/workflows/deploy-frontend.yml`

**الخطوات:**
1. انسخ محتوى `github-actions-frontend.yml` إلى:
   `.github/workflows/deploy-frontend.yml`

2. أضف SSH Secrets إلى GitHub:
```bash
# ولِّد SSH Key (إذا لم يكن لديك)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/github_deploy

# في GitHub repo → Settings → Secrets → New repository secret
FRONTEND_EC2_HOST = (IP العام من Terraform)
FRONTEND_EC2_USER = ubuntu
FRONTEND_EC2_SSH_KEY = (محتوى ~/.ssh/github_deploy)
```

3. ضيف SSH Key إلى الـ EC2:
```bash
# من جهازك المحلي
scp -i /path/to/ec2/key ~/.ssh/github_deploy.pub ubuntu@FRONTEND_IP:~/.ssh/authorized_keys
```

**القيم:**
- Build Command: `echo "building...."`
- Deploy Target: Ubuntu 22.04 (Frontend EC2)
- Docker Image: louislam/uptime-kuma:latest
- Port: 3001

**التشغيل:**
```bash
# أي push إلى main branch سيشغل:
git push origin main

# GitHub Actions سيقوم بـ:
# 1. Build Docker image
# 2. Push to Container Registry
# 3. SSH إلى Frontend EC2
# 4. Pull و run الـ image
```

### Task B2: Backend Deployment (Laravel)

**الملف:** `.github/workflows/deploy-backend.yml`

**الخطوات:**
1. انسخ محتوى `github-actions-backend.yml` إلى:
   `.github/workflows/deploy-backend.yml`

2. أضف SSH Secrets:
```bash
BACKEND_EC2_HOST = (IP العام من Terraform)
BACKEND_EC2_USER = ubuntu
BACKEND_EC2_SSH_KEY = (نفس المفتاح أو مفتاح جديد)
```

3. أنشئ script النشر على الـ EC2:
```bash
# قم بـ SSH إلى الـ Backend EC2
ssh -i /path/to/ec2/key ubuntu@BACKEND_IP

# أضف المستخدم في sudoers:
sudo visudo
# أضف: ubuntu ALL=(ALL) NOPASSWD: ALL
```

**التشغيل:**
```bash
# أي push إلى main branch في Laravel repo سيقوم بـ:
# 1. Checkout code
# 2. Setup PHP 8.1
# 3. Install Composer dependencies
# 4. SSH إلى Backend EC2
# 5. Pull الـ changes
# 6. تشغيل: php artisan migrate --force
# 7. إعادة تشغيل Nginx و PHP-FPM
```

### Task B3: CPU Monitoring & Alerts

**التنبيهات تعمل تلقائياً بعد Terraform apply:**

1. **تأكيد البريد الإلكتروني:**
   - تحقق من البريد الوارد
   - انقر على رابط التأكيد من AWS

2. **اختبار التنبيه:**
```bash
# SSH إلى أي EC2
ssh -i /path/to/key ubuntu@EC2_IP

# توليد حمل CPU
yes > /dev/null &
yes > /dev/null &
yes > /dev/null &

# سيصلك بريد تنبيه بعد 10 دقائق
# لإيقاف العملية:
killall yes
```

3. **CloudWatch Dashboard:**
   - اذهب إلى AWS Console
   - CloudWatch → Alarms
   - اعرض حالة الـ Alarms

---

## 📊 مراقبة التطبيقات

### Uptime Kuma (Frontend)
```
URL: http://FRONTEND_IP:3001
الاستخدام: مراقبة uptime التطبيقات
```

### Laravel Backend
```
URL: http://BACKEND_IP:80
Database: MySQL على RDS
قاعدة البيانات: obeliondb
```

### RDS MySQL
```
Host: obeliondb.xxxxx.us-east-1.rds.amazonaws.com
Port: 3306
Username: admin
Password: (من terraform.tfvars)

الاتصال:
mysql -h ENDPOINT -u admin -p
```

---

## 🔐 الأمان والنصائح

### Best Practices:
1. **SSH Security:**
   - استخدم Elastic IPs بدلاً من IPs العادية
   - قيِّد SSH إلى IPs محددة (لا تستخدم 0.0.0.0/0)

2. **RDS Security:**
   - قاعدة البيانات في شبكة خاصة (لا يمكن الوصول من الإنترنت)
   - EC2 instances فقط يمكنها الوصول

3. **Passwords:**
   - استخدم كلمات مرور قوية (> 12 حرف)
   - لا تضع كلمات المرور في الـ Git
   - استخدم AWS Secrets Manager

4. **Monitoring:**
   - راقب الـ CPU utilization
   - راقب الـ Disk space
   - راقب البيانات الداخلة والخارجة (Data Transfer)

### التكاليف:
- EC2 (t2.micro): ~$8.5/شهر
- RDS (db.t3.micro): ~$10/شهر  
- Data Transfer: ~$0.10/GB
- **الإجمالي تقريباً: ~$20-30/شهر**

---

## 🐛 استكشاف الأخطاء

### مشكلة: لا يمكن الاتصال بـ EC2
```bash
# تحقق من Security Group
aws ec2 describe-security-groups --group-ids sg-xxxxx

# تأكد من Public IP
aws ec2 describe-instances --instance-ids i-xxxxx

# فحص SSH
ssh -vvv -i key.pem ubuntu@IP
```

### مشكلة: RDS غير متاح
```bash
# تحقق من Security Groups
aws rds describe-db-instances --db-instance-identifier obeliondb

# اختبار الاتصال من EC2:
ssh -i key.pem ubuntu@EC2_IP
mysql -h RDS_ENDPOINT -u admin -p
```

### مشكلة: GitHub Actions تفشل
```bash
# تحقق من الـ logs
GitHub → Actions → اختر الـ workflow

# تحقق من SSH Key
ssh-keygen -y -f ~/.ssh/github_deploy

# تحقق من Secrets في GitHub
Settings → Secrets → اعرض القيم
```

---

## 📈 التطوير المستقبلي

### المراحل التالية:
1. **Load Balancer:**
   - أضف Application Load Balancer (ALB)
   - وزّع الحمل بين عدة EC2 instances

2. **Auto Scaling:**
   - أنشئ Auto Scaling Group
   - ازدد/انقص الـ instances حسب الحمل

3. **SSL/TLS:**
   - استخدم AWS Certificate Manager (ACM)
   - أضف HTTPS إلى التطبيقات

4. **Database Backup:**
   - أنشئ نسخ احتياطية يومية
   - اختبر الـ restore الدوري

5. **Logging & Analytics:**
   - استخدم CloudWatch Logs
   - استخدم CloudTrail للـ auditing

---

## 📞 الدعم والمزيد

### الموارد المفيدة:
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- GitHub Actions: https://docs.github.com/en/actions
- AWS CloudWatch: https://docs.aws.amazon.com/cloudwatch/
- Laravel Deployment: https://laravel.com/docs/10.x/deployment

---

## ✅ قائمة التحقق / Checklist

- [ ] Terraform files منسوخة وجاهزة
- [ ] AWS Credentials مُعدّة
- [ ] terraform.tfvars مُنشأ بالقيم الصحيحة
- [ ] `terraform apply` نجح
- [ ] SSH Keys مُنشأة وموجودة على EC2
- [ ] GitHub Secrets مُضافة
- [ ] GitHub Actions workflows موجودة و مُفعّلة
- [ ] اختبار الـ Frontend deployment
- [ ] اختبار الـ Backend deployment
- [ ] اختبار CPU alerts
- [ ] Uptime Kuma يعمل بنجاح
- [ ] Laravel application متاح
- [ ] RDS قابل للوصول من Backend

---

**آخر تحديث:** 2025-11-23
**النسخة:** 1.0
**الحالة:** ✅ جاهز للإنتاج

---