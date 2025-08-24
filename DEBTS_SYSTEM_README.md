# نظام إدارة الديون والحسابات - POS System

## نظرة عامة
تم إنشاء نظام شامل لإدارة ديون العملاء والموردين في نظام نقاط البيع باستخدام Flutter مع تطبيق مبادئ Clean Code وMVC Pattern وProvider لإدارة الحالة.

## الميزات الرئيسية

### 1. إدارة الديون
- ✅ إضافة ديون جديدة للعملاء والموردين
- ✅ تعديل الديون الموجودة
- ✅ حذف الديون
- ✅ أرشفة الديون المسددة أو المنتهية الصلاحية
- ✅ البحث والفلترة حسب الاسم، النوع، والحالة

### 2. إدارة الدفعات
- ✅ إضافة دفعات جزئية على الديون
- ✅ تحديث تلقائي للمبلغ المتبقي والحالة
- ✅ تتبع تاريخ المعاملات
- ✅ إضافة ملاحظات للدفعات

### 3. الإحصائيات والتقارير
- ✅ إجمالي الديون حسب النوع (عملاء/موردين)
- ✅ إحصائيات الحالة (مدفوع/جزئي/غير مدفوع)
- ✅ عدد الديون والمبالغ لكل فئة
- ✅ تحديث فوري للإحصائيات

### 4. واجهة المستخدم
- ✅ تصميم متجاوب باستخدام SmartSizer
- ✅ عرض الديون في بطاقات منظمة
- ✅ ألوان مميزة لحالات الديون المختلفة
- ✅ أزرار سريعة للعمليات الشائعة
- ✅ حوارات تفاعلية لإدخال البيانات

## البنية التقنية

### قاعدة البيانات
```sql
-- جدول الديون الرئيسي
CREATE TABLE Debts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    party_id INTEGER NOT NULL,
    party_type TEXT NOT NULL CHECK (party_type IN ('customer', 'supplier')),
    party_name TEXT NOT NULL,
    party_phone TEXT,
    amount REAL NOT NULL DEFAULT 0,
    paid_amount REAL NOT NULL DEFAULT 0,
    remaining_amount REAL NOT NULL DEFAULT 0,
    due_date TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'unpaid' CHECK (status IN ('unpaid', 'partiallyPaid', 'paid')),
    archived INTEGER DEFAULT 0,
    notes TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- جدول معاملات الديون
CREATE TABLE DebtTransactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    debt_id INTEGER NOT NULL,
    amount_paid REAL NOT NULL DEFAULT 0,
    date TEXT NOT NULL,
    notes TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (debt_id) REFERENCES Debts (id) ON DELETE CASCADE
);
```

### الملفات المنشأة

#### النماذج (Models)
- `lib/Model/DebtModel.dart` - نموذج الدين الأساسي
- `lib/Model/DebtTransactionModel.dart` - نموذج معاملات الدفع

#### المستودعات (Repositories)
- `lib/Repository/DebtRepository.dart` - طبقة الوصول للبيانات

#### المزودين (Providers)
- `lib/Controller/DebtProvider.dart` - إدارة حالة الديون

#### الشاشات (Screens)
- `lib/View/Screens/DebtsScreen.dart` - الشاشة الرئيسية للديون

#### الويدجتس (Widgets)
- `lib/View/Widgets/DebtCard.dart` - بطاقة عرض الدين
- `lib/View/Widgets/DebtFormDialog.dart` - حوار إضافة/تعديل الدين
- `lib/View/Widgets/DebtPaymentDialog.dart` - حوار إضافة دفعة
- `lib/View/Widgets/DebtStatsWidget.dart` - ويدجت الإحصائيات

## العملة
تم تكوين النظام لاستخدام **الدينار العراقي (د.ع)** كعملة أساسية:
- لا توجد خانات عشرية (الدينار العراقي يُحسب بالوحدات الكاملة)
- تنسيق العرض: `1000 د.ع`
- تحديث `AppConstants.dart` لدعم العملة العراقية

## كيفية الاستخدام

### 1. الوصول للشاشة
- من القائمة الجانبية، اختر "الديون والحسابات"
- أو من شريط التنقل السفلي في الأجهزة المحمولة

### 2. إضافة دين جديد
1. اضغط على زر "إضافة دين جديد"
2. اختر نوع الطرف (عميل أو مورد)
3. أدخل البيانات المطلوبة
4. حدد تاريخ الاستحقاق
5. اضغط "حفظ"

### 3. إدارة الدفعات
1. من بطاقة الدين، اضغط "إضافة دفعة"
2. أدخل مبلغ الدفعة
3. استخدم الأزرار السريعة للمبالغ الشائعة
4. أضف ملاحظات إذا لزم الأمر
5. اضغط "حفظ"

### 4. البحث والفلترة
- استخدم شريط البحث للبحث بالاسم
- استخدم أزرار الفلترة السريعة للحالة والنوع
- اضغط على "الأرشيف" لعرض الديون المؤرشفة

## الحالات المدعومة

### حالات الدين
- **غير مدفوع** (`unpaid`) - لم يتم دفع أي مبلغ
- **مدفوع جزئياً** (`partiallyPaid`) - تم دفع جزء من المبلغ
- **مدفوع** (`paid`) - تم دفع المبلغ كاملاً

### أنواع الأطراف
- **عميل** (`customer`) - ديون على العملاء
- **مورد** (`supplier`) - ديون للموردين

## التحديثات التلقائية
- تحديث حالة الدين تلقائياً عند إضافة دفعات
- حساب المبلغ المتبقي تلقائياً
- تحديث الإحصائيات فورياً
- إشعارات للمستخدم عند نجاح/فشل العمليات

## الأمان والتحقق
- التحقق من صحة البيانات قبل الحفظ
- منع إدخال مبالغ سالبة
- منع تجاوز المبلغ المدفوع للمبلغ الكلي
- رسائل خطأ واضحة ومفيدة

## التوافق
- ✅ Android
- ✅ iOS  
- ✅ Windows
- ✅ Linux
- ✅ macOS
- ✅ Web

## المتطلبات التقنية
- Flutter SDK ^3.9.0
- Dart SDK ^3.9.0
- sqflite ^2.0.0
- provider ^6.0.0
- smart_sizer ^1.0.0

## الصيانة والتطوير
النظام مصمم ليكون قابلاً للتوسع والصيانة:
- فصل واضح بين طبقات التطبيق
- كود نظيف ومُعلق باللغة العربية
- معالجة شاملة للأخطاء
- تسجيل مفصل للعمليات

---

تم تطوير هذا النظام باستخدام أفضل الممارسات في تطوير تطبيقات Flutter مع التركيز على الأداء وسهولة الاستخدام والصيانة.