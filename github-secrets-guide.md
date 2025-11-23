# 🔐 GitHub Secrets Configuration - إعدادات السرار في GitHub

## كيفية إضافة Secrets:

### الخطوة 1: اذهب إلى GitHub
```
Repository → Settings → Secrets and variables → Actions → New repository secret
```

### الخطوة 2: أضف Secrets التالية:

---

## Frontend Repository Secrets

### 1. FRONTEND_EC2_HOST
```
القيمة: 1.2.3.4  (IP العام من Terraform output)
الوصف: رابط Frontend EC2
```

### 2. FRONTEND_EC2_USER
```
القيمة: ubuntu
الوصف: اسم المستخدم على EC2
```

### 3. FRONTEND_EC2_SSH_KEY
```
القيمة: (محتوى الملف ~/.ssh/github_deploy)

كيف تحصل عليها:
cat ~/.ssh/github_deploy | pbcopy  # macOS
cat ~/.ssh/github_deploy | clip    # Windows
cat ~/.ssh/github_deploy           # Linux ثم انسخ يدوياً

الوصف: SSH Private Key للاتصال بـ EC2
```

---

## Backend Repository Secrets

### 1. BACKEND_EC2_HOST
```
القيمة: 5.6.7.8  (IP العام من Terraform output)
الوصف: رابط Backend EC2
```

### 2. BACKEND_EC2_USER
```
القيمة: ubuntu
الوصف: اسم المستخدم على EC2
```

### 3. BACKEND_EC2_SSH_KEY
```
القيمة: (محتوى الملف ~/.ssh/github_deploy)

الوصف: SSH Private Key للاتصال بـ EC2
```

---

## إنشاء SSH Keys الخاص بك

### الخطوة 1: إنشاء Key
```bash
# إنشاء مجلد SSH إذا لم يكن موجوداً
mkdir -p ~/.ssh
cd ~/.ssh

# إنشاء Key جديد (بدون كلمة مرور للتوافقية)
ssh-keygen -t rsa -b 4096 -f github_deploy -N ""

# التحقق من الملفات المنشأة
ls -la github_deploy*
# يجب أن ترى:
# - github_deploy (Private Key - حساس جداً!)
# - github_deploy.pub (Public Key - آمن للمشاركة)
```

### الخطوة 2: إضافة Key إلى EC2
```bash
# الطريقة 1: نسخ أثناء إنشاء البنية
# (أثناء terraform apply - يتم إضافة authorized_keys تلقائياً)

# الطريقة 2: نسخ يدوي إلى EC2
scp -i /path/to/ec2/key ~/.ssh/github_deploy.pub ubuntu@EC2_IP:~/github_key.pub

# ثم الاتصال والإضافة:
ssh -i /path/to/ec2/key ubuntu@EC2_IP
mkdir -p ~/.ssh
cat ~/github_key.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
exit
```

### الخطوة 3: اختبر الاتصال
```bash
# تأكد من الاتصال بدون password
ssh -i ~/.ssh/github_deploy ubuntu@EC2_IP

# يجب أن يتصل بدون طلب كلمة مرور
# إذا طلبك كلمة مرور، أعد المحاولة من الخطوة 2
```

---

## أمثلة على القيم الفعلية

### مثال لـ Frontend EC2 Host:
```
FRONTEND_EC2_HOST = 54.243.123.45
```

### مثال لـ SSH Key:
```
FRONTEND_EC2_SSH_KEY = -----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA2x+h3u0vQzLb...
(المحتوى الكامل للـ Private Key)
...
-----END RSA PRIVATE KEY-----
```

---

## ⚠️ تحذيرات أمان مهمة

### ❌ لا تفعل:
- ❌ لا تشارك SSH Private Keys مع أحد
- ❌ لا تضع Secrets في Git commits
- ❌ لا تستخدم نفس Key لعدة أشياء
- ❌ لا تحفظ Key في ملفات Config
- ❌ لا تشارك Screenshots للـ Secrets

### ✅ أفضل الممارسات:
- ✅ استخدم Secrets الآمنة من GitHub
- ✅ أعد إنشاء Keys إذا تسرب أحدها
- ✅ استخدم Key منفصل لكل Repository
- ✅ راجع Secrets دورياً
- ✅ احذف Keys القديمة غير المستخدمة

---

## استكشاف الأخطاء

### المشكلة: "Permission denied (publickey)"
```bash
الحل:
1. تأكد من أن authorized_keys موجود:
   ssh -i ~/.ssh/github_deploy ubuntu@EC2_IP "cat ~/.ssh/authorized_keys"

2. تأكد من الصلاحيات:
   ssh -i ~/.ssh/github_deploy ubuntu@EC2_IP "chmod 600 ~/.ssh/authorized_keys"

3. أعد إضافة المفتاح:
   cat ~/.ssh/github_deploy.pub | ssh -i ~/.ssh/ec2_key ubuntu@EC2_IP \
   "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### المشكلة: GitHub Actions تفشل في SSH
```bash
الحل:
1. اختبر الـ Secret:
   - أنسخ محتوى Private Key بدقة
   - تأكد من عدم وجود مسافات إضافية

2. تحقق من البنية:
   echo "${{ secrets.BACKEND_EC2_SSH_KEY }}" | head -1
   # يجب أن يبدأ بـ: -----BEGIN RSA PRIVATE KEY-----

3. أعد إنشاء السرار:
   - احذف السرار القديم
   - أنشئ واحد جديد بنفس الاسم
```

---

## التحقق من الإعدادات

### اختبر كل Secret:
```bash
# 1. تحقق من الوصول
ssh -v -i ~/.ssh/github_deploy ubuntu@FRONTEND_EC2_HOST

# 2. شغّل أمر بسيط
ssh -i ~/.ssh/github_deploy ubuntu@FRONTEND_EC2_HOST "uname -a"

# 3. تحقق من Uptime Kuma
ssh -i ~/.ssh/github_deploy ubuntu@FRONTEND_EC2_HOST \
  "docker ps | grep uptime"
```

---

## قائمة التحقق النهائية

- [ ] SSH Key منشأ بدون خطأ
- [ ] Public Key موجود على EC2
- [ ] الاتصال يعمل بدون password
- [ ] Secrets مضافة في GitHub
- [ ] أسماء الـ Secrets صحيحة تماماً
- [ ] GitHub Actions يمكنه الاتصال بـ EC2
- [ ] Deployments تعمل بنجاح

---

## الملفات المطلوبة

```
~/.ssh/
├── github_deploy          (Private - حساس جداً!)
├── github_deploy.pub      (Public - آمن للمشاركة)
└── authorized_keys        (على EC2 لتخزين Public Keys)
```

---

## النسخة والتاريخ

- **النسخة:** 1.0
- **آخر تحديث:** 2025-11-23
- **الحالة:** ✅ جاهز للاستخدام

---