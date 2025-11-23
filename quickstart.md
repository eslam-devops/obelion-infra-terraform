# 🚀 Quick Start Guide - البدء السريع

## ⚡ 5 خطوات للبدء

### الخطوة 1: تحضير البيئة (15 دقيقة)
```bash
# تثبيت Terraform
brew install terraform  # macOS
# أو scoop install terraform  # Windows

# تثبيت AWS CLI
pip install awscli

# إعداد AWS
aws configure
# أدخل:
# AWS Access Key ID: xxxxxxxxx
# AWS Secret Access Key: xxxxxxxxx
# Default region: us-east-1
# Default output format: json

# التحقق
terraform --version
aws --version
```

---

### الخطوة 2: إعداد Terraform (10 دقائق)
```bash
# نسخ جميع ملفات Terraform
mkdir terraform
cd terraform

# ضع المحتويات التالية في الملفات:
# - terraform-main.tf
# - terraform-ec2.tf
# - terraform-rds.tf
# - terraform-monitoring.tf
# - terraform-variables.tf

# إنشاء terraform.tfvars
cat > terraform.tfvars <<'EOF'
aws_region         = "us-east-1"
environment         = "production"
project_name        = "obelion"
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"

# EC2 Configuration
ec2_instance_type     = "t2.micro"
ec2_root_volume_size  = 8

# RDS Configuration
rds_identifier      = "obeliondb"
rds_instance_class  = "db.t3.micro"
rds_storage_size    = 20
rds_database        = "obeliondb"
rds_username        = "admin"
rds_password        = "YourSuperSecurePassword123!"
rds_backup_retention_days = 7

# Monitoring
cpu_alarm_threshold = 50
alarm_email        = "your-email@example.com"

# Security
allowed_ssh_cidr   = "YOUR_IP/32"  # استبدل بـ IP الخاص بك
EOF

# تهيئة Terraform
terraform init
```

---

### الخطوة 3: نشر البنية السحابية (20 دقيقة)
```bash
# عرض ما سيتم إنشاؤه
terraform plan

# تطبيق التكوين
terraform apply

# سيطلب تأكيد - اكتب: yes

# الحصول على معلومات الوصول
terraform output
```

**ستحصل على:**
```
frontend_public_ip = "XX.XX.XX.XX"
backend_public_ip  = "XX.XX.XX.XX"
uptime_kuma_url    = "http://XX.XX.XX.XX:3001"
laravel_app_url    = "http://XX.XX.XX.XX"
rds_endpoint       = "obeliondb.xxxxx.us-east-1.rds.amazonaws.com"
```

---

### الخطوة 4: إعداد GitHub Actions (15 دقيقة)

#### أ. إنشاء SSH Keys
```bash
# إنشاء مفتاح SSH للنشر
ssh-keygen -t rsa -b 4096 -f ~/.ssh/github_deploy -N ""

# عرض المفتاح العام
cat ~/.ssh/github_deploy.pub
```

#### ب. إضافة Key إلى EC2
```bash
# نسخ key إلى Frontend EC2
scp -i /path/to/ec2/key ~/.ssh/github_deploy.pub ubuntu@FRONTEND_IP:~/.ssh/authorized_keys

# نسخ key إلى Backend EC2
scp -i /path/to/ec2/key ~/.ssh/github_deploy.pub ubuntu@BACKEND_IP:~/.ssh/authorized_keys
```

#### ج. إضافة Secrets إلى GitHub
```
في GitHub Repository:
1. Settings → Secrets and variables → Actions
2. New repository secret

أضف:
- FRONTEND_EC2_HOST = (IP من Terraform output)
- FRONTEND_EC2_USER = ubuntu
- FRONTEND_EC2_SSH_KEY = (محتوى ~/.ssh/github_deploy)

- BACKEND_EC2_HOST = (IP من Terraform output)
- BACKEND_EC2_USER = ubuntu
- BACKEND_EC2_SSH_KEY = (محتوى ~/.ssh/github_deploy)

- GITHUB_TOKEN = (يُنشأ تلقائياً)
```

#### د. إضافة Workflow Files
**في Frontend Repository:**
```bash
mkdir -p .github/workflows
# انسخ محتوى github-actions-frontend.yml إلى:
# .github/workflows/deploy-frontend.yml
```

**في Backend Repository:**
```bash
mkdir -p .github/workflows
# انسخ محتوى github-actions-backend.yml إلى:
# .github/workflows/deploy-backend.yml
```

---

### الخطوة 5: اختبار النظام (10 دقائق)

#### اختبار Frontend
```bash
# اذهب إلى الرابط
http://FRONTEND_IP:3001

# يجب أن ترى واجهة Uptime Kuma
```

#### اختبار Backend
```bash
# اختبر API
curl http://BACKEND_IP/

# يجب أن تحصل على استجابة من Laravel
```

#### اختبار GitHub Actions
```bash
# أنشئ تغييراً بسيطاً و ادفعه
echo "# Test" >> README.md
git add .
git commit -m "Test deployment"
git push origin main

# ستذهب إلى:
# Frontend Repo → Actions → اعرض السجل
# Backend Repo → Actions → اعرض السجل

# يجب أن ترى:
✅ Checkout code
✅ Build Docker image
✅ Deploy to EC2
✅ Health Check
```

#### اختبار المراقبة
```bash
# توليد حمل CPU
ssh -i /path/to/key ubuntu@EC2_IP
yes > /dev/null &
sleep 600  # انتظر 10 دقائق

# يجب أن تستقبل بريداً تنبيهياً!

# لإيقاف العملية:
killall yes
```

---

## 📊 الروابط الهامة

| الخدمة | الرابط | الاستخدام |
|-------|--------|----------|
| Uptime Kuma | http://FRONTEND_IP:3001 | مراقبة uptime التطبيقات |
| Laravel App | http://BACKEND_IP | التطبيق الرئيسي |
| AWS Console | https://console.aws.amazon.com | إدارة الموارد |
| GitHub | https://github.com/your-org | إدارة الكود والـ Actions |
| CloudWatch | AWS Console → CloudWatch | مراقبة الأداء |

---

## 🔐 معلومات الاتصال

### Frontend EC2
```
Host: FRONTEND_IP
User: ubuntu
Key: ~/.ssh/ec2_key.pem
```

### Backend EC2
```
Host: BACKEND_IP
User: ubuntu
Key: ~/.ssh/ec2_key.pem
```

### RDS MySQL
```
Host: obeliondb.xxxxx.us-east-1.rds.amazonaws.com
Port: 3306
Username: admin
Password: (من terraform.tfvars)
Database: obeliondb

الاتصال:
mysql -h ENDPOINT -u admin -p
```

---

## ⚠️ نقاط مهمة

1. **الأمان:**
   - غير `allowed_ssh_cidr` من `0.0.0.0/0` إلى IP الخاص بك
   - استخدم كلمات مرور قوية جداً لـ RDS
   - لا تضع كلمات المرور في Git

2. **التكاليف:**
   - EC2 (t2.micro): ~$8.5/شهر
   - RDS (db.t3.micro): ~$10/شهر
   - البيانات: ~$0.10/GB
   - **الإجمالي: ~$20-30/شهر**

3. **النسخ الاحتياطية:**
   - RDS يحتفظ بـ 7 نسخ احتياطية يومية
   - اختبر الـ restore مرة شهرياً

4. **الحذف (إذا أردت إيقاف المشروع):**
```bash
cd terraform
terraform destroy
# اكتب: yes
```

---

## 🐛 حل المشاكل الشائعة

### المشكلة: لا يمكن الاتصال بـ EC2
**الحل:**
```bash
# تأكد من Security Group
aws ec2 describe-security-groups

# تأكد من Public IP
terraform output frontend_public_ip

# اختبر SSH
ssh -v -i key.pem ubuntu@IP
```

### المشكلة: GitHub Actions تفشل
**الحل:**
```bash
# اذهب إلى GitHub Actions → اعرض السجل
# ابحث عن الخطأ

# تحقق من Secrets
GitHub → Settings → Secrets

# أعد إنشاء SSH Key إذا لزم الأمر
ssh-keygen -y -f ~/.ssh/github_deploy
```

### المشكلة: RDS غير متاح
**الحل:**
```bash
# تحقق من Security Group الخاص بـ RDS
# تأكد من أن EC2 يمكنه الوصول

# من EC2:
ssh ubuntu@EC2_IP
mysql -h ENDPOINT -u admin -p
```

---

## 📞 المزيد من الموارد

- **Terraform Docs:** https://www.terraform.io/docs
- **AWS CLI Reference:** https://docs.aws.amazon.com/cli/
- **GitHub Actions:** https://docs.github.com/en/actions
- **Laravel Documentation:** https://laravel.com/docs
- **Uptime Kuma:** https://uptime.kuma.pet

---

**تم الإنشاء بنجاح! 🎉**

---