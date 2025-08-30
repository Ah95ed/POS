# دليل استكشاف أخطاء نظام إدارة المخزون
## POS Inventory System Troubleshooting Guide

## 🚨 المشكلة الأساسية
**"عند عملية الدفع يقول لي خطأ في حفظ الفاتورة او المنتج غير موجود"**

## 🔍 التشخيص المنهجي

### 1. فحص أولي - تحقق من هذه النقاط:

#### ✅ التحقق من وجود المنتج
```dart
// في SaleProvider.completeSale()
final productResult = await _productRepository.getProductByCode(item.productCode);
if (productResult.isError || productResult.data == null) {
  _setError('المنتج ${item.productName} غير موجود');
  return false;
}
```

#### ✅ التحقق من صحة البيانات
- **كود المنتج**: يجب ألا يكون فارغاً أو null
- **كمية الفاتورة**: يجب أن تكون أكبر من 0
- **رقم الفاتورة**: يجب أن يكون فريداً

#### ✅ التحقق من المخزون
```dart
if (product.quantity < item.quantity) {
  _setError('الكمية المطلوبة من ${item.productName} غير متوفرة. المتاح: ${product.quantity}');
  return false;
}
```

### 2. الأخطاء الشائعة وحلولها

#### ❌ خطأ: "المنتج غير موجود"

**الأسباب المحتملة:**
1. **كود المنتج خاطئ أو مفقود**
2. **المنتج محذوف من قاعدة البيانات**
3. **مشكلة في البحث في قاعدة البيانات**

**الحلول:**
```dart
// 1. تحقق من كود المنتج قبل البحث
if (item.productCode.trim().isEmpty) {
  return StockValidationResult(false, 'كود المنتج فارغ للمنتج: ${item.productName}');
}

// 2. استخدم البحث المحسن
final productResult = await _productRepository.getProductByCode(item.productCode.trim());

// 3. تحقق من رسالة الخطأ
if (productResult.isError) {
  return StockValidationResult(false, 'خطأ في البحث عن المنتج: ${productResult.error}');
}
```

#### ❌ خطأ: "فشل في حفظ الفاتورة"

**الأسباب المحتملة:**
1. **رقم فاتورة مكرر**
2. **بيانات فاتورة غير صحيحة**
3. **مشكلة في قاعدة البيانات**

**الحلول:**
```dart
// 1. تحقق من صحة الفاتورة
if (!sale.isValid) {
  return Result.error('بيانات الفاتورة غير صحيحة');
}

// 2. تحقق من عدم تكرار رقم الفاتورة
final existingSale = await getSaleByInvoiceNumber(sale.invoiceNumber);
if (existingSale.isSuccess && existingSale.data != null) {
  return Result.error('رقم الفاتورة موجود مسبقاً');
}

// 3. استخدم المعاملات الآمنة
await db.transaction((txn) async {
  // العمليات هنا آمنة
});
```

#### ❌ خطأ: "الكمية المطلوبة أكبر من المتاح"

**الحلول:**
```dart
// تحقق من الكمية قبل البيع
if (currentQuantity < item.quantity) {
  throw Exception(
    'الكمية المطلوبة من $productName (${item.quantity}) أكبر من المتاح ($currentQuantity)',
  );
}
```

### 3. التحقق من سلامة قاعدة البيانات

#### 🔧 فحص اتصال قاعدة البيانات
```dart
Future<bool> checkDatabaseConnection() async {
  try {
    final db = await POSDatabase.database;
    final result = await db!.rawQuery('SELECT 1');
    return result.isNotEmpty;
  } catch (e) {
    print('خطأ في الاتصال بقاعدة البيانات: $e');
    return false;
  }
}
```

#### 🔧 فحص جداول قاعدة البيانات
```dart
Future<void> validateDatabaseTables() async {
  final db = await POSDatabase.database;
  
  // فحص جدول المنتجات
  final itemsCount = await db!.rawQuery('SELECT COUNT(*) FROM ${POSDatabase.itemsTable}');
  print('عدد المنتجات: ${itemsCount.first.values.first}');
  
  // فحص جدول المبيعات
  final salesCount = await db.rawQuery('SELECT COUNT(*) FROM ${POSDatabase.salesTable}');
  print('عدد المبيعات: ${salesCount.first.values.first}');
}
```

### 4. خطوات استكشاف الأخطاء العملية

#### المرحلة 1: فحص المنتج
```dart
// تحقق من وجود المنتج
final product = await productRepository.getProductByCode('كود_المنتج');
if (product.isError) {
  print('❌ المنتج غير موجود: ${product.error}');
} else {
  print('✅ المنتج موجود: ${product.data!.name}');
  print('   الكمية المتاحة: ${product.data!.quantity}');
}
```

#### المرحلة 2: فحص الفاتورة
```dart
// تحقق من صحة بيانات الفاتورة
print('🧾 فحص الفاتورة:');
print('   رقم الفاتورة: ${sale.invoiceNumber}');
print('   عدد العناصر: ${sale.items.length}');
print('   الإجمالي: ${sale.total}');
print('   صحيحة: ${sale.isValid}');
```

#### المرحلة 3: فحص العملية
```dart
// تتبع خطوات حفظ الفاتورة
try {
  print('🔄 بدء حفظ الفاتورة...');
  
  final result = await saleRepository.saveSale(sale);
  
  if (result.isSuccess) {
    print('✅ تم حفظ الفاتورة رقم: ${result.data}');
  } else {
    print('❌ فشل في الحفظ: ${result.error}');
  }
} catch (e) {
  print('💥 خطأ غير متوقع: $e');
}
```

### 5. الحلول السريعة

#### 🛠️ إعادة تعيين النظام
```dart
// مسح البيانات المؤقتة
saleProvider.clearCurrentSale();

// إعادة تحميل المنتجات
await productProvider.loadProducts();

// إعادة تهيئة قاعدة البيانات
await POSDatabase.resetDatabase();
```

#### 🛠️ إصلاح المنتجات المفقودة
```dart
// إضافة منتج جديد إذا كان مفقوداً
final newProduct = ProductModel(
  name: 'منتج محدث',
  code: 'FIXED001',
  salePrice: 100.0,
  buyPrice: 80.0,
  quantity: 50,
  company: 'الشركة',
  date: DateTime.now().toString(),
);

await productRepository.addProduct(newProduct);
```

#### 🛠️ إصلاح أرقام الفواتير
```dart
// توليد رقم فاتورة جديد
final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';
```

### 6. رسائل الخطأ الشائعة والمعاني

| رسالة الخطأ | السبب المحتمل | الحل المقترح |
|-------------|---------------|----------------|
| `المنتج غير موجود` | كود خاطئ أو منتج محذوف | تحقق من الكود وأعد إضافة المنتج |
| `رقم الفاتورة موجود مسبقاً` | رقم فاتورة مكرر | استخدم رقم فاتورة جديد |
| `الكمية غير متوفرة` | مخزون منخفض | زود المخزون أو قلل الكمية |
| `بيانات الفاتورة غير صحيحة` | بيانات ناقصة | تحقق من جميع الحقول المطلوبة |
| `خطأ في قاعدة البيانات` | مشكلة اتصال | أعد تشغيل التطبيق أو فحص القاعدة |

### 7. أدوات التشخيص المتقدمة

#### 📊 سجل العمليات
```dart
// تسجيل تفصيلي للعمليات
void logSaleOperation(String operation, dynamic data) {
  final timestamp = DateTime.now().toIso8601String();
  print('[$timestamp] $operation: $data');
}

// استخدام في العمليات
logSaleOperation('بدء حفظ الفاتورة', sale.toMap());
logSaleOperation('تحقق من المنتج', product.toMap());
logSaleOperation('تحديث المخزون', 'تم بنجاح');
```

#### 🔬 فحص تفصيلي للأخطاء
```dart
Future<void> detailedErrorAnalysis(String error) async {
  print('\n🔍 تحليل مفصل للخطأ:');
  print('الخطأ: $error');
  
  // فحص نوع الخطأ
  if (error.contains('المنتج')) {
    await analyzeProductError();
  } else if (error.contains('الفاتورة')) {
    await analyzeSaleError();
  } else if (error.contains('قاعدة البيانات')) {
    await analyzeDatabaseError();
  }
}
```

### 8. الوقاية من الأخطاء

#### ✨ التحقق المسبق
```dart
// فحص شامل قبل البيع
Future<bool> preSaleValidation() async {
  // 1. فحص اتصال قاعدة البيانات
  // 2. التحقق من وجود المنتجات
  // 3. فحص المخزون
  // 4. تحقق من بيانات الفاتورة
  return true;
}
```

#### 🛡️ حماية البيانات
```dart
// نسخ احتياطي قبل العمليات الحساسة
await backupDatabase();

// استخدام المعاملات الآمنة
await db.transaction((txn) async {
  // العمليات المحمية
});
```

### 9. اختبار النظام

#### 🧪 اختبار شامل
```bash
# تشغيل اختبار النظام
dart test_inventory_system.dart
```

#### 📋 قائمة فحص النظام
- [ ] قاعدة البيانات متصلة
- [ ] المنتجات موجودة ومحدثة
- [ ] نظام توليد أرقام الفواتير يعمل
- [ ] التحقق من المخزون فعال
- [ ] حفظ الفواتير يعمل بشكل صحيح
- [ ] تحديث المخزون تلقائي

### 🎯 الخلاصة

المشكلة الأساسية تكمن عادة في:
1. **عدم العثور على المنتج** - تحقق من الكود والبيانات
2. **رقم فاتورة مكرر** - استخدم نظام توليد أفضل
3. **كمية غير كافية** - فحص المخزون أولاً
4. **بيانات فاتورة غير صحيحة** - تحقق من جميع الحقول

💡 **نصيحة**: استخدم أدوات التشخيص المرفقة لتحديد السبب الدقيق وتطبيق الحل المناسب.
