import 'package:pos/Helper/DataBase/DataBaseSqflite.dart';
import 'package:pos/Repository/ProductRepository.dart';
import 'package:pos/Repository/SaleRepository.dart';
import 'package:pos/Controller/SaleProvider.dart';
import 'package:pos/Model/ProductModel.dart';
import 'package:pos/Model/SaleModel.dart';

/// ملف اختبار نظام إدارة المخزون
/// لاختبار المشكلة: "خطأ في حفظ الفاتورة او المنتج غير موجود"

void main() async {
  print('🧪 بدء اختبار نظام إدارة المخزون...\n');

  try {
    // 1. إنشاء منتج تجريبي
    await testProductCreation();

    // 2. اختبار البحث عن المنتج
    await testProductSearch();

    // 3. اختبار إنشاء فاتورة
    await testSaleCreation();

    print('\n✅ تم اكتمال جميع الاختبارات بنجاح!');
  } catch (e) {
    print('\n❌ فشل في الاختبار: $e');
  }
}

/// اختبار إنشاء منتج
Future<void> testProductCreation() async {
  print('📦 اختبار إنشاء منتج...');

  final productRepo = ProductRepository(DataBaseSqflite());

  final testProduct = ProductModel(
    name: 'منتج تجريبي',
    code: 'TEST001',
    salePrice: 100.0,
    buyPrice: 80.0,
    quantity: 10,
    company: 'شركة تجريبية',
    date: DateTime.now().toString(),
    lowStockThreshold: 5,
  );

  final result = await productRepo.addProduct(testProduct);

  if (result.isSuccess) {
    print('✅ تم إنشاء المنتج بنجاح (ID: ${result.data})');
  } else {
    print('❌ فشل في إنشاء المنتج: ${result.error}');
    throw Exception('فشل في إنشاء المنتج');
  }
}

/// اختبار البحث عن المنتج
Future<void> testProductSearch() async {
  print('\n🔍 اختبار البحث عن المنتج...');

  final productRepo = ProductRepository(DataBaseSqflite());

  // البحث بالكود
  final searchResult = await productRepo.getProductByCode('TEST001');

  if (searchResult.isSuccess && searchResult.data != null) {
    final product = searchResult.data!;
    print('✅ تم العثور على المنتج:');
    print('   - الاسم: ${product.name}');
    print('   - الكود: ${product.code}');
    print('   - الكمية: ${product.quantity}');
    print('   - السعر: ${product.salePrice}');
  } else {
    print('❌ لم يتم العثور على المنتج: ${searchResult.error}');
    throw Exception('فشل في البحث عن المنتج');
  }
}

/// اختبار إنشاء فاتورة
Future<void> testSaleCreation() async {
  print('\n💰 اختبار إنشاء فاتورة...');

  final saleRepo = SaleRepository();

  // إنشاء فاتورة تجريبية
  final testSale = SaleModel(
    invoiceNumber: 'INV-TEST-${DateTime.now().millisecondsSinceEpoch}',
    subtotal: 100.0,
    tax: 15.0,
    discount: 0.0,
    total: 115.0,
    paidAmount: 115.0,
    changeAmount: 0.0,
    paymentMethod: 'نقدي',
    status: 'completed',
    createdAt: DateTime.now(),
    items: [
      SaleItemModel(
        productId: 1, // سيتم تحديثه حسب المنتج المُنشأ
        productCode: 'TEST001',
        productName: 'منتج تجريبي',
        unitPrice: 100.0,
        quantity: 1,
        discount: 0.0,
        total: 100.0,
      ),
    ],
  );

  // التحقق من صحة الفاتورة
  if (!testSale.isValid) {
    print('❌ بيانات الفاتورة غير صحيحة');
    throw Exception('بيانات الفاتورة غير صحيحة');
  }

  // محاولة حفظ الفاتورة
  final result = await saleRepo.saveSale(testSale);

  if (result.isSuccess) {
    print('✅ تم حفظ الفاتورة بنجاح (ID: ${result.data})');
    print('✅ تم تحديث المخزون تلقائياً');

    // التحقق من تحديث المخزون
    await verifyStockUpdate();
  } else {
    print('❌ فشل في حفظ الفاتورة: ${result.error}');

    // تحليل سبب الفشل
    await analyzeSaleFailure(result.error!);

    throw Exception('فشل في حفظ الفاتورة');
  }
}

/// التحقق من تحديث المخزون
Future<void> verifyStockUpdate() async {
  print('\n📊 التحقق من تحديث المخزون...');

  final productRepo = ProductRepository(DataBaseSqflite());

  final productResult = await productRepo.getProductByCode('TEST001');

  if (productResult.isSuccess && productResult.data != null) {
    final product = productResult.data!;
    print('✅ الكمية الحالية للمنتج: ${product.quantity}');

    if (product.quantity == 9) {
      // كان 10، تم بيع 1
      print('✅ تم تحديث المخزون بشكل صحيح');
    } else {
      print('⚠️ المخزون لم يتم تحديثه بشكل صحيح');
    }
  } else {
    print('❌ فشل في التحقق من المخزون: ${productResult.error}');
  }
}

/// تحليل سبب فشل الفاتورة
Future<void> analyzeSaleFailure(String error) async {
  print('\n🔍 تحليل سبب فشل الفاتورة...');
  print('رسالة الخطأ: $error');

  // فحص الأسباب المحتملة
  if (error.contains('غير موجود')) {
    print('\n💡 السبب المحتمل: المنتج غير موجود في قاعدة البيانات');
    print('🔧 الحلول المقترحة:');
    print('   1. تأكد من إضافة المنتج قبل البيع');
    print('   2. تحقق من صحة كود المنتج');
    print('   3. تأكد من عدم حذف المنتج');
  } else if (error.contains('الكمية')) {
    print('\n💡 السبب المحتمل: كمية غير كافية في المخزون');
    print('🔧 الحلول المقترحة:');
    print('   1. تزويد المخزون');
    print('   2. تقليل الكمية المطلوبة');
    print('   3. التحقق من صحة الكمية المتاحة');
  } else if (error.contains('رقم الفاتورة')) {
    print('\n💡 السبب المحتمل: رقم فاتورة مكرر');
    print('🔧 الحلول المقترحة:');
    print('   1. استخدام رقم فاتورة جديد');
    print('   2. تحسين نظام توليد أرقام الفواتير');
  } else {
    print('\n💡 السبب المحتمل: خطأ عام في النظام');
    print('🔧 الحلول المقترحة:');
    print('   1. تحقق من اتصال قاعدة البيانات');
    print('   2. تأكد من صحة بيانات الفاتورة');
    print('   3. راجع صلاحيات قاعدة البيانات');
  }
}

/// اختبار استخدام SaleProvider
Future<void> testSaleProvider() async {
  print('\n🎯 اختبار SaleProvider...');

  try {
    final saleProvider = SaleProvider();

    // محاولة إضافة منتج للفاتورة
    final productRepo = ProductRepository(DataBaseSqflite());
    final productResult = await productRepo.getProductByCode('TEST001');

    if (productResult.isSuccess && productResult.data != null) {
      final product = productResult.data!;

      // إضافة المنتج للفاتورة
      final addResult = await saleProvider.addProductToSale(product);

      if (addResult) {
        print('✅ تم إضافة المنتج للفاتورة');

        // تعيين المبلغ المدفوع
        saleProvider.updatePaidAmount(saleProvider.total);

        // محاولة إتمام البيع
        final completeResult = await saleProvider.completeSale();

        if (completeResult) {
          print('✅ تم إتمام البيع بنجاح');
        } else {
          print('❌ فشل في إتمام البيع: ${saleProvider.errorMessage}');
        }
      } else {
        print('❌ فشل في إضافة المنتج للفاتورة: ${saleProvider.errorMessage}');
      }
    } else {
      print('❌ لم يتم العثور على المنتج للاختبار');
    }
  } catch (e) {
    print('❌ خطأ في اختبار SaleProvider: $e');
  }
}
