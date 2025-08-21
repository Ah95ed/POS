# نظام إدارة المخزن - Inventory Management System

## 🏪 نظرة عامة
تم إنشاء نظام شامل لإدارة المخزن مع عمليات CRUD كاملة (إضافة، قراءة، تحديث، حذف) باستخدام Clean Code Architecture.

## 🏗️ هيكل النظام

### 📊 طبقة البيانات (Data Layer)
```
lib/Model/
└── ProductModel.dart          # نموذج المنتج مع جميع الخصائص والطرق
```

### 🔄 طبقة المستودع (Repository Layer)
```
lib/Repository/
└── ProductRepository.dart     # جميع عمليات قاعدة البيانات للمنتجات
```

### 🎯 طبقة التحكم (Controller Layer)
```
lib/Controller/
└── ProductProvider.dart       # إدارة حالة المنتجات والعمليات
```

### 🎨 طبقة العرض (View Layer)
```
lib/View/
├── Screens/
│   └── ProductsScreen.dart    # الشاشة الرئيسية لإدارة المنتجات
└── Widgets/
    ├── ProductCard.dart       # بطاقة عرض المنتج
    └── AddEditProductDialog.dart # نافذة إضافة/تعديل المنتج
```

## ✨ المميزات الرئيسية

### 🔧 العمليات الأساسية (CRUD)
- ✅ **إضافة منتج جديد** - مع التحقق من صحة البيانات
- ✅ **عرض جميع المنتجات** - مع التصفح والبحث
- ✅ **تحديث المنتج** - تعديل جميع البيانات
- ✅ **حذف المنتج** - مع تأكيد الحذف

### 🔍 البحث والفلترة
- **البحث بالاسم** - بحث فوري أثناء الكتابة
- **البحث بالكود** - للوصول السريع للمنتج
- **الترتيب المتقدم** - حسب 8 معايير مختلفة
- **الفلترة الذكية** - حسب حالة المخزون

### 📊 الإحصائيات والتحليلات
- **إجمالي المنتجات** - العدد الكلي
- **المخزون المنخفض** - المنتجات أقل من 10 قطع
- **نافد المخزون** - المنتجات بكمية 0
- **قيمة المخزون** - إجمالي قيمة الشراء والبيع
- **الربح المتوقع** - حساب الأرباح المحتملة

### 🎨 واجهة المستخدم
- **تصميم متجاوب** - يتكيف مع جميع الشاشات
- **واجهة عربية** - دعم كامل للغة العربية
- **بطاقات تفاعلية** - عرض جميل للمنتجات
- **حالات بصرية** - تمييز المخزون المنخفض/النافد

## 📋 تفاصيل المكونات

### 1. ProductModel
```dart
class ProductModel {
  final int? id;
  final String name;
  final String code;
  final double salePrice;
  final double buyPrice;
  final int quantity;
  final String company;
  final String date;
  
  // خصائص محسوبة
  double get profitPerUnit;
  double get totalBuyValue;
  double get totalSaleValue;
  double get totalProfit;
  bool get isLowStock;
  bool get isOutOfStock;
  bool get isValid;
}
```

### 2. ProductRepository
```dart
class ProductRepository {
  // العمليات الأساسية
  Future<Result<int>> addProduct(ProductModel product);
  Future<Result<bool>> updateProduct(ProductModel product);
  Future<Result<bool>> deleteProduct(int productId);
  Future<Result<List<ProductModel>>> getAllProducts();
  
  // البحث والفلترة
  Future<Result<List<ProductModel>>> searchProductsByName(String name);
  Future<Result<ProductModel?>> getProductByCode(String code);
  Future<Result<List<ProductModel>>> getLowStockProducts();
  Future<Result<List<ProductModel>>> getOutOfStockProducts();
  
  // الإحصائيات
  Future<Result<InventoryStats>> getInventoryStats();
  
  // عمليات متقدمة
  Future<Result<bool>> updateProductQuantity(int productId, int newQuantity);
  Future<Result<bool>> updateAllSalePrices(double adjustment);
  Future<Result<bool>> updateAllBuyPrices(double adjustment);
}
```

### 3. ProductProvider
```dart
class ProductProvider extends ChangeNotifier {
  // الحالات
  bool get isLoading;
  String get errorMessage;
  List<ProductModel> get products;
  InventoryStats? get inventoryStats;
  
  // العمليات
  Future<void> loadProducts();
  Future<bool> addProduct(ProductModel product);
  Future<bool> updateProduct(ProductModel product);
  Future<bool> deleteProduct(int productId);
  
  // البحث والترتيب
  Future<void> searchProducts(String query);
  void sortProducts(ProductSortType sortType, {bool? ascending});
  
  // عمليات متقدمة
  Future<List<ProductModel>> getLowStockProducts();
  Future<List<ProductModel>> getOutOfStockProducts();
  Future<bool> updateProductQuantity(int productId, int newQuantity);
}
```

## 🎯 أنواع الترتيب المتاحة

```dart
enum ProductSortType {
  name,        // الاسم
  code,        // الكود
  quantity,    // الكمية
  salePrice,   // سعر البيع
  buyPrice,    // سعر الشراء
  profit,      // الربح
  company,     // الشركة
  date,        // التاريخ
}
```

## 🔧 كيفية الاستخدام

### إضافة منتج جديد
```dart
final product = ProductModel(
  name: 'اسم المنتج',
  code: 'P001',
  salePrice: 100.0,
  buyPrice: 80.0,
  quantity: 50,
  company: 'الشركة',
  date: DateTime.now().toString().split(' ')[0],
);

final success = await productProvider.addProduct(product);
```

### البحث في المنتجات
```dart
await productProvider.searchProducts('اسم المنتج');
```

### ترتيب المنتجات
```dart
productProvider.sortProducts(ProductSortType.name, ascending: true);
```

### الحصول على الإحصائيات
```dart
final stats = productProvider.inventoryStats;
print('إجمالي المنتجات: ${stats?.totalProducts}');
print('مخزون منخفض: ${stats?.lowStockProducts}');
```

## 🎨 واجهة المستخدم

### الشاشة الرئيسية (ProductsScreen)
- **شريط البحث** - بحث فوري
- **إحصائيات سريعة** - 3 بطاقات إحصائية
- **قائمة المنتجات** - عرض تفاعلي
- **أزرار العمليات** - تعديل وحذف
- **زر الإضافة العائم** - إضافة منتج جديد

### بطاقة المنتج (ProductCard)
- **معلومات أساسية** - الاسم والكود
- **حالة المخزون** - متوفر/منخفض/نافد
- **الأسعار والربح** - عرض واضح
- **معلومات إضافية** - الشركة والتاريخ
- **أزرار العمليات** - تعديل وحذف

### نافذة الإضافة/التعديل (AddEditProductDialog)
- **نموذج شامل** - جميع الحقول المطلوبة
- **التحقق من البيانات** - validation متقدم
- **معاينة الربح** - حساب فوري للأرباح
- **تصميم متجاوب** - يتكيف مع الشاشة

## 🔒 التحقق من البيانات

### قواعد التحقق
- **اسم المنتج**: مطلوب، أكثر من حرفين
- **كود المنتج**: مطلوب، فريد
- **الأسعار**: أرقام موجبة، سعر البيع > سعر الشراء
- **الكمية**: رقم صحيح غير سالب
- **الشركة**: اختياري

### معالجة الأخطاء
- **رسائل واضحة** - باللغة العربية
- **تنبيهات بصرية** - ألوان وأيقونات
- **إعادة المحاولة** - خيارات للمستخدم

## 📊 حالات المخزون

### المتوفر (Available)
- الكمية > 10
- لون أخضر
- أيقونة ✅

### منخفض (Low Stock)
- الكمية بين 1-10
- لون برتقالي
- أيقونة ⚠️

### نافد (Out of Stock)
- الكمية = 0
- لون أحمر
- أيقونة ❌

## 🚀 الأداء والتحسينات

### تحسينات الأداء
- **تحميل تدريجي** - Pagination للبيانات الكبيرة
- **بحث محسن** - فلترة محلية وخادم
- **ذاكرة التخزين** - تخزين مؤقت للبيانات
- **تحديث ذكي** - إعادة تحميل عند الحاجة فقط

### إدارة الحالة
- **Provider Pattern** - إدارة حالة متقدمة
- **Reactive UI** - واجهة تتفاعل مع التغييرات
- **Error Handling** - معالجة شاملة للأخطاء
- **Loading States** - حالات التحميل الواضحة

## 🔮 التطوير المستقبلي

### مميزات مخططة
- [ ] **الباركود** - قراءة وإنشاء الباركود
- [ ] **الصور** - إضافة صور للمنتجات
- [ ] **الفئات** - تصنيف المنتجات
- [ ] **الموردين** - ربط المنتجات بالموردين
- [ ] **تتبع المخزون** - سجل حركة المخزون
- [ ] **التنبيهات** - إشعارات المخزون المنخفض
- [ ] **التقارير** - تقارير مفصلة للمخزون
- [ ] **الاستيراد/التصدير** - Excel/CSV

### تحسينات تقنية
- [ ] **قاعدة بيانات سحابية** - مزامنة متعددة الأجهزة
- [ ] **API Integration** - ربط مع أنظمة خارجية
- [ ] **Offline Support** - عمل بدون إنترنت
- [ ] **Real-time Updates** - تحديثات فورية
- [ ] **Advanced Search** - بحث متقدم بمعايير متعددة

## 🤝 كيفية المساهمة

### إضافة ميزة جديدة
1. إنشاء فرع جديد
2. تطبيق التغييرات
3. كتابة الاختبارات
4. تحديث التوثيق
5. إرسال Pull Request

### الإبلاغ عن مشكلة
1. وصف المشكلة بوضوح
2. خطوات إعادة الإنتاج
3. لقطات الشاشة إن أمكن
4. معلومات البيئة

---

**تم تطوير هذا النظام باستخدام Clean Code Architecture لضمان سهولة الصيانة والتطوير** 🏪✨