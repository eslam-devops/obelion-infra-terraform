# Obelion Cloud Automation Task

## مهمة أتمتة سحابة Obelion

هذا المستودع يحتوي على حل شامل لمهمة Obelion Cloud Automation Assessment والتي تتضمن:

## Task Group A - Infrastructure as Code (Terraform)

إنشاء موارد AWS باستخدام Terraform:
- **Backend EC2 Instance**: t2.micro with 1 core, 1GB RAM, 8GB disk
- **Frontend EC2 Instance**: t2.micro with 1 core, 1GB RAM, 8GB disk  
- **MySQL RDS Database**: Community version 8, lowest tier instance

### ملفات Task Group A:
- `task-a/main.tf` - تكوين موارد AWS الأساسية (VPC, EC2, RDS)
- `task-a/variables.tf` - متغيرات Terraform
- `task-a/outputs.tf` - مخرجات Terraform
- `task-a/terraform.tfvars.example` - ملف مثال للقيم المطلوبة

### كيفية الاستخدام:
```bash
cd task-a
cp terraform.tfvars.example terraform.tfvars
# تعديل terraform.tfvars بقيمك الخاصة
terraform init
terraform plan
terraform apply
```

## Task Group B - GitHub Actions CI/CD Workflows

تكوين أتمتة النشر من خلال GitHub Actions:

1. **Frontend Deployment (Uptime Kuma)**
   - عند التحديث على فرع main، يتم:
     - تشغيل خطوة البناء (build step)
     - نشر إلى Ubuntu 22.04 machine
     - استخدام docker-compose مع صورة uptime-kuma العامة

2. **Backend Deployment (Laravel PHP)**
   - عند التحديث على فرع main، يتم:
     - الاتصال بخادم Ubuntu 22.04
     - تنفيذ shell script يقوم بـ:
       - Pull للتغييرات الجديدة
       - تشغيل `php artisan migrate`

3. **Monitoring & Alerting**
   - مراقبة استخدام CPU على الخوادم
   - إرسال تنبيهات عند تجاوز 50% CPU
   - البريد الإلكتروني المستقبل للتنبيهات

## الهيكل:
```
obelion-automation-task/
├── README.md (هذا الملف)
├── task-a/          # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
└── task-b/          # CI/CD Workflows (GitHub Actions)
    └── workflows/
        ├── frontend-deploy.yml
        ├── backend-deploy.yml
        └── monitoring.yml
```

## المتطلبات:
- AWS Account (Free Tier)
- Terraform >= 1.0
- Git و GitHub
- SSH access للخوادم

## ملاحظات مهمة:
- استخدام Free Tier AWS resources
- جميع الملفات مُعدة بـ English مع تعليقات بـ Arabic
- اتباع أفضل الممارسات في Security و Infrastructure
