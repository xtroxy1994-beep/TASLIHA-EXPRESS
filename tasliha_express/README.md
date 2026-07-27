# تسليحة إكسبريس — Tasliha Express 🔧

تطبيق أندرويد لسوق الخدمات المنزلية في الجزائر — مبني بـ Flutter + Firebase.

---

## 🗂️ هيكل المشروع

```
tasliha_express/
├── android/app/google-services.json   ← ضع ملف Firebase الخاص بك هنا
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_constants.dart
│   │   ├── app_routes.dart
│   │   └── algeria_wilayas.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── request_model.dart
│   │   ├── rating_model.dart
│   │   ├── chat_message_model.dart
│   │   └── point_transaction_model.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   ├── storage_service.dart
│   │   ├── points_service.dart
│   │   └── chat_service.dart
│   ├── screens/
│   │   ├── splash/splash_screen.dart
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── otp_screen.dart
│   │   ├── client/
│   │   │   ├── client_home_screen.dart
│   │   │   ├── post_request_screen.dart
│   │   │   └── my_requests_screen.dart
│   │   ├── tech/
│   │   │   ├── tech_home_screen.dart
│   │   │   ├── available_requests_screen.dart
│   │   │   └── my_jobs_screen.dart
│   │   ├── manager/
│   │   │   └── manager_home_screen.dart
│   │   ├── admin/
│   │   │   ├── admin_home_screen.dart
│   │   │   ├── admin_requests_screen.dart
│   │   │   └── admin_payments_screen.dart
│   │   └── shared/
│   │       ├── chat_screen.dart
│   │       ├── profile_screen.dart
│   │       ├── points_screen.dart
│   │       ├── recharge_screen.dart
│   │       └── rating_screen.dart
│   ├── widgets/
│   │   ├── custom_button.dart
│   │   ├── custom_text_field.dart
│   │   ├── rating_widget.dart
│   │   ├── request_card.dart
│   │   └── loading_widget.dart
│   └── l10n/
│       └── app_localizations.dart
├── firestore.rules
├── storage.rules
└── pubspec.yaml
```

---

## 🚀 الإعداد المحلي

### 1. المتطلبات
- Flutter SDK >= 3.19 ([تثبيت](https://docs.flutter.dev/get-started/install))
- Android Studio أو VS Code مع إضافة Flutter
- Java 17+ (مطلوب لـ Gradle)
- Firebase CLI (اختياري لنشر القواعد)

### 2. تثبيت الحزم
```bash
cd tasliha_express
flutter pub get
```

### 3. ربط Firebase
ملف `android/app/google-services.json` يحتوي على قيم placeholder.  
**استبدله بملف `google-services.json` الحقيقي من Firebase Console.**

للحصول عليه:
1. اذهب إلى [Firebase Console](https://console.firebase.google.com/project/tasliha-express)
2. اضغط على ⚙️ إعدادات المشروع
3. في **تطبيقاتك** اختر التطبيق الأندرويد
4. نزّل `google-services.json`
5. ضعه في `tasliha_express/android/app/google-services.json`

كذلك حدّث `lib/firebase_options.dart` بالقيم الصحيحة من نفس الصفحة.

### 4. تفعيل خدمات Firebase

في [Firebase Console](https://console.firebase.google.com/project/tasliha-express):

| الخدمة | ما يجب تفعيله |
|---|---|
| **Authentication** | Email/Password (والـ Phone لاحقاً) |
| **Firestore** | أنشئ قاعدة بيانات في وضع Production |
| **Storage** | أنشئ bucket |

### 5. رفع قواعد Firestore
```bash
# تثبيت Firebase CLI
npm install -g firebase-tools
firebase login

# في مجلد tasliha_express
firebase deploy --only firestore:rules --project tasliha-express
firebase deploy --only storage:rules --project tasliha-express
```

### 6. تشغيل التطبيق
```bash
flutter run
```

أو من Android Studio: افتح مجلد `tasliha_express` واضغط **Run ▶**

---

## 🏗️ بنية Firestore

### Collections

| Collection | الوصف |
|---|---|
| `users` | بيانات المستخدمين (client/tech/manager/admin) |
| `requests` | طلبات الخدمة |
| `ratings` | تقييمات العملاء للفنيين |
| `chats` | غرف المحادثة |
| `chats/{id}/messages` | رسائل كل غرفة |
| `point_transactions` | سجل معاملات النقاط |
| `recharge_requests` | طلبات شحن النقاط |

### الأدوار (Roles)

| الدور | الصلاحيات |
|---|---|
| `client` | نشر طلبات، محادثة الفني، تقييم |
| `tech` | قبول طلبات (بالنقاط)، محادثة العميل |
| `manager` | مراقبة الطلبات والفنيين |
| `admin` | كل الصلاحيات + الموافقة على الطلبات والمدفوعات |

---

## 💰 نظام النقاط

- الفني يحصل على **50 نقطة مجانية** لمدة 30 يوماً عند التسجيل
- كل طلب ينشره الأدمن له **قيمة نقاط** (مثلاً 10–50 نقطة)
- الفني يدفع النقاط عند قبول الطلب — المجانية تُستهلك أولاً
- الشحن: **2000 دج = 200 نقطة** (عبر CCP/BaridiMob)

---

## 💳 معلومات الدفع (Admin)

```
رقم الحساب CCP: 0012345678901 - Clé: 67
المالك: Tasliha Express Admin
البريد: xtroxy1995@gmail.com
```

---

## 🔐 الأمان

- **رقم الهاتف** لا يُكشف إلا بعد قبول الفني للطلب وخصم النقاط
- **المحادثة** لا تُفتح إلا للمشاركَين (العميل + الفني المقبول)
- قواعد Firestore و Storage مكتوبة في `firestore.rules` و `storage.rules`

---

## 🌍 اللغات

التطبيق يدعم ثلاث لغات:
- 🇩🇿 العربية (افتراضية)
- 🇫🇷 الفرنسية
- 🇬🇧 الإنجليزية

يمكن تغيير اللغة من شاشة الملف الشخصي.

---

## 📦 الاعتمادات الرئيسية

```yaml
firebase_core, firebase_auth, cloud_firestore, firebase_storage
provider          # State management
image_picker      # رفع الصور
pin_code_fields   # إدخال OTP
flutter_rating_bar # نجوم التقييم
intl              # التنسيقات والترجمة
flutter_spinkit   # مؤشرات التحميل
```

---

## 🛠️ ملاحظات للمطور

1. **OTP مؤقت**: حالياً يُظهر الكود في Snackbar لأغراض التجربة. في الإنتاج فعّل Firebase Phone Authentication وأزل الكود التجريبي في `otp_screen.dart`.

2. **الإشعارات**: لم تُضف بعد. يمكن إضافة Firebase Cloud Messaging (FCM) لاحقاً.

3. **خرائط**: يمكن إضافة خريطة الموقع في طلبات الخدمة عبر `google_maps_flutter`.

4. **الإصدار المبدئي**: `1.0.0+1` — حدّثه في `pubspec.yaml` عند كل إصدار.
