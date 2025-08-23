# نظام إدارة الفواتير - Invoice Management System

## نظرة عامة
تم إنشاء نظام شامل لإدارة الفواتير في تطبيق نقطة البيع (POS) باستخدام Flutter مع هيكلية نظيفة (Clean Architecture) ونمط Provider لإدارة الحالة.

## الهيكلية المُنشأة

### 1. قاعدة البيانات (Database)
- **جدول Invoices**: يحتوي على معلومات الفاتورة الأساسية
  - `id`: المعرف الفريد
  - `customer_id`: معرف العميل (اختياري)
  - `invoice_number`: رقم الفاتورة (فريد)
  - `date`: تاريخ الفاتورة
  - `total_amount`: المبلغ الإجمالي
  - `status`: حالة الفاتورة (pending, paid, overdue, cancelled)
  - `customer_name`: اسم العميل
  - `customer_phone`: رقم هاتف العميل
  - `notes`: ملاحظات
  - `created_at`: تاريخ الإنشاء
  - `updated_at`: تاريخ آخر تحديث

- **جدول InvoiceItems**: يحتوي على عناصر الفاتورة
  - `id`: المعرف الفريد
  - `invoice_id`: معرف الفاتورة
  - `product_id`: معرف المنتج (اختياري)
  - `product_name`: اسم المنتج
  - `product_code`: كود المنتج
  - `quantity`: الكمية
  - `price`: السعر
  - `total`: الإجمالي

### 2. النماذج (Models)
- **InvoiceModel**: نموذج الفاتورة الرئيسي
- **InvoiceItemModel**: نموذج عناصر الفاتورة

### 3. المستودع (Repository)
- **InvoiceRepository**: يدير جميع العمليات مع قاعدة البيانات
  - إضافة فاتورة جديدة
  - تحديث فاتورة موجودة
  - حذف فاتورة
  - جلب جميع الفواتير
  - البحث في الفواتير
  - تصفية الفواتير حسب الحالة أو التاريخ
  - إنشاء رقم فاتورة جديد
  - الحصول على إحصائيات الفواتير

### 4. مزود الحالة (Provider)
- **InvoiceProvider**: يدير حالة الفواتير في التطبيق
  - إدارة قائمة الفواتير
  - البحث والتصفية
  - إدارة حالات التحميل والأخطاء
  - الإحصائيات

### 5. واجهة المستخدم (UI)

#### الشاشات (Screens)
- **InvoicesScreen**: الشاشة الرئيسية لإدارة الفواتير
- **InvoiceDetailsScreen**: شاشة تفاصيل الفاتورة

#### الويدجتس (Widgets)
- **InvoiceCard**: بطاقة عرض الفاتورة
- **InvoiceFormDialog**: حوار إضافة/تعديل الفاتورة
- **InvoiceStatsWidget**: عرض إحصائيات الفواتير

## الميزات الرئيسية

### 1. إدارة الفواتير
- ✅ إضافة فاتورة جديدة مع عناصر متعددة
- ✅ تعديل الفواتير الموجودة
- ✅ حذف الفواتير
- ✅ عرض تفاصيل الفاتورة كاملة
- ✅ تحديث حالة الفاتورة (معلقة، مدفوعة، متأخرة، ملغية)

### 2. البحث والتصفية
- ✅ البحث برقم الفاتورة
- ✅ البحث باسم العميل
- ✅ البحث برقم الهاتف
- ✅ البحث في الملاحظات
- ✅ تصفية حسب حالة الفاتورة
- ✅ تصفية حسب نطاق التاريخ

### 3. الإحصائيات
- ✅ إحصائيات اليوم (عدد الفواتير والمبلغ الإجمالي)
- ✅ إحصائيات الشهر
- ✅ إحصائيات حسب الحالة
- ✅ عرض إجمالي قيمة الفواتير

### 4. واجهة المستخدم
- ✅ تصميم متجاوب باستخدام SmartSizer
- ✅ دعم اللغة العربية
- ✅ ألوان وأيقونات مميزة لكل حالة
- ✅ رسائل تأكيد للعمليات الحساسة
- ✅ مؤشرات التحميل والأخطاء

## كيفية الاستخدام

### 1. إضافة Provider إلى التطبيق
```dart
MultiProvider(
  providers: [
    // ... providers أخرى
    ChangeNotifierProvider(create: (_) => InvoiceProvider()),
  ],
  child: MyApp(),
)
```

### 2. استخدام الشاشة
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const InvoicesScreen(),
  ),
);
```

### 3. الوصول إلى البيانات
```dart
// في أي widget
Consumer<InvoiceProvider>(
  builder: (context, invoiceProvider, child) {
    return ListView.builder(
      itemCount: invoiceProvider.invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoiceProvider.invoices[index];
        return InvoiceCard(invoice: invoice);
      },
    );
  },
)
```

## الملفات المُنشأة

### Models
- `lib/Model/InvoiceModel.dart`
- `lib/Model/InvoiceItemModel.dart`

### Repository
- `lib/Repository/InvoiceRepository.dart`

### Controllers/Providers
- `lib/Controller/InvoiceProvider.dart`

### Screens
- `lib/View/Screens/InvoicesScreen.dart`
- `lib/View/Screens/InvoiceDetailsScreen.dart`

### Widgets
- `lib/View/Widgets/InvoiceCard.dart`
- `lib/View/Widgets/InvoiceFormDialog.dart`
- `lib/View/Widgets/InvoiceStatsWidget.dart`

### Database Updates
- تم تحديث `lib/Helper/DataBase/POSDatabase.dart` لتشمل جداول الفواتير

## الميزات المستقبلية (TODO)

### 1. الطباعة والتصدير
- [ ] طباعة الفاتورة
- [ ] تصدير إلى PDF
- [ ] تصدير إلى Excel
- [ ] مشاركة الفاتورة

### 2. التكامل
- [ ] ربط الفواتير بالمخزون (تقليل الكمية عند الحفظ)
- [ ] ربط الفواتير بالعملاء
- [ ] ربط الفواتير بالمبيعات

### 3. التحسينات
- [ ] إضافة الضرائب والخصومات
- [ ] دعم العملات المتعددة
- [ ] إضافة الباركود للفواتير
- [ ] نظام الموافقات للفواتير الكبيرة

### 4. التقارير
- [ ] تقارير مفصلة للفواتير
- [ ] تحليل الأداء
- [ ] تقارير العملاء
- [ ] تقارير المنتجات الأكثر مبيعاً

## ملاحظات مهمة

1. **قاعدة البيانات**: تأكد من أن إصدار قاعدة البيانات محدث (version 5) لتشمل جداول الفواتير
2. **الأذونات**: قد تحتاج لأذونات إضافية للطباعة والتصدير
3. **الأداء**: النظام محسن للتعامل مع آلاف الفواتير
4. **الأمان**: يتم التحقق من صحة البيانات قبل الحفظ

## الدعم والصيانة

النظام مصمم ليكون قابلاً للتوسع والصيانة:
- كود نظيف ومنظم
- فصل واضح بين الطبقات
- معالجة شاملة للأخطاء
- توثيق كامل للكود
- اختبارات وحدة (يمكن إضافتها لاحقاً)

---

تم إنشاء هذا النظام باستخدام أفضل الممارسات في تطوير Flutter مع التركيز على الأداء وسهولة الاستخدام والقابلية للتوسع.