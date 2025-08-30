import 'package:pos/Helper/DataBase/DataBaseSqflite.dart';
import 'package:pos/Repository/ProductRepository.dart';
import 'package:pos/Model/ProductModel.dart';

/// إضافة بيانات تجريبية لحل مشكلة "المنتج غير موجود"

void main() async {
  print('🛠️ إعداد بيانات تجريبية للنظام...\n');

  final setup = SampleDataSetup();
  await setup.setupSampleData();
}

class SampleDataSetup {
  final ProductRepository _productRepository = ProductRepository(
    DataBaseSqflite(),
  );

  /// إعداد بيانات تجريبية شاملة
  Future<void> setupSampleData() async {
    print('🚀 بدء إعداد البيانات التجريبية...\n');

    try {
      // التحقق من وجود منتجات
      final existingProducts = await _productRepository.getAllProducts();

      if (existingProducts.isSuccess && existingProducts.data!.isNotEmpty) {
        print('📦 يوجد ${existingProducts.data!.length} منتج في النظام');
        print('❓ هل تريد إضافة المزيد من المنتجات التجريبية؟');
        print('⚠️ سيتم إضافة منتجات جديدة فقط (لن يتم حذف الموجود)\n');
      }

      // إضافة منتجات تجريبية
      await _addSampleProducts();

      // التحقق من النتائج
      await _verifySetup();

      print('\n✅ تم إعداد البيانات التجريبية بنجاح!');
      print('🎯 يمكنك الآن اختبار عملية البيع');
    } catch (e) {
      print('❌ خطأ في إعداد البيانات: $e');
    }
  }

  /// إضافة منتجات تجريبية متنوعة
  Future<void> _addSampleProducts() async {
    print('📦 إضافة منتجات تجريبية...\n');

    final sampleProducts = [
      // منتجات غذائية
      ProductModel(
        id: 0,
        name: 'أرز أبيض - كيس 5 كيلو',
        code: 'RICE001',
        salePrice: 45.00,
        buyPrice: 40.00,
        quantity: 20,
        company: 'شركة الأرز الذهبي',
        date: DateTime.now().toString(),
        description: 'أرز أبيض عالي الجودة',
        lowStockThreshold: 5,
      ),

      ProductModel(
        id: 0,
        name: 'زيت طبخ - عبوة 1 لتر',
        code: 'OIL001',
        salePrice: 25.50,
        buyPrice: 22.00,
        quantity: 15,
        company: 'مصنع الزيوت',
        date: DateTime.now().toString(),
        description: 'زيت طبخ نباتي',
        lowStockThreshold: 3,
      ),

      ProductModel(
        id: 0,
        name: 'شاي أحمر - علبة 400 جرام',
        code: 'TEA001',
        salePrice: 18.75,
        buyPrice: 15.00,
        quantity: 25,
        company: 'شركة الشاي الممتاز',
        date: DateTime.now().toString(),
        description: 'شاي أحمر فاخر',
        lowStockThreshold: 5,
      ),

      // منتجات تنظيف
      ProductModel(
        id: 0,
        name: 'صابون غسيل - عبوة 3 كيلو',
        code: 'SOAP001',
        salePrice: 35.00,
        buyPrice: 30.00,
        quantity: 12,
        company: 'مصنع الصابون',
        date: DateTime.now().toString(),
        description: 'مسحوق غسيل عالي الجودة',
        lowStockThreshold: 2,
      ),

      ProductModel(
        id: 0,
        name: 'شامبو - عبوة 400 مل',
        code: 'SHAMP001',
        salePrice: 22.00,
        buyPrice: 18.00,
        quantity: 18,
        company: 'شركة العناية',
        date: DateTime.now().toString(),
        description: 'شامبو للشعر العادي',
        lowStockThreshold: 3,
      ),

      // منتجات مكتبية
      ProductModel(
        id: 0,
        name: 'قلم حبر جاف - أزرق',
        code: 'PEN001',
        salePrice: 2.50,
        buyPrice: 1.50,
        quantity: 50,
        company: 'مكتبة الطلاب',
        date: DateTime.now().toString(),
        description: 'قلم حبر جاف لون أزرق',
        lowStockThreshold: 10,
      ),

      ProductModel(
        id: 0,
        name: 'دفتر A4 - 100 ورقة',
        code: 'NOTE001',
        salePrice: 12.00,
        buyPrice: 8.00,
        quantity: 30,
        company: 'مطبعة الكتب',
        date: DateTime.now().toString(),
        description: 'دفتر مسطر A4',
        lowStockThreshold: 5,
      ),

      // منتجات إلكترونية بسيطة
      ProductModel(
        id: 0,
        name: 'بطارية AA - عبوة 4 قطع',
        code: 'BATT001',
        salePrice: 15.00,
        buyPrice: 12.00,
        quantity: 20,
        company: 'شركة الطاقة',
        date: DateTime.now().toString(),
        description: 'بطاريات قلوية AA',
        lowStockThreshold: 4,
      ),

      ProductModel(
        id: 0,
        name: 'كابل USB - متر واحد',
        code: 'USB001',
        salePrice: 8.50,
        buyPrice: 6.00,
        quantity: 25,
        company: 'تكنولوجيا الحاسوب',
        date: DateTime.now().toString(),
        description: 'كابل USB عالي الجودة',
        lowStockThreshold: 5,
      ),

      // منتج بكمية قليلة للاختبار
      ProductModel(
        id: 0,
        name: 'منتج تجريبي - كمية قليلة',
        code: 'TEST001',
        salePrice: 5.00,
        buyPrice: 3.00,
        quantity: 2,
        company: 'شركة التجربة',
        date: DateTime.now().toString(),
        description: 'منتج للاختبار - كمية محدودة',
        lowStockThreshold: 1,
      ),
    ];

    int addedCount = 0;
    int skippedCount = 0;

    for (final product in sampleProducts) {
      try {
        // التحقق من وجود المنتج
        final existingProduct = await _productRepository.getProductByCode(
          product.code,
        );

        if (existingProduct.isSuccess && existingProduct.data != null) {
          print('⏭️ تخطي ${product.name} - موجود مسبقاً');
          skippedCount++;
          continue;
        }

        // إضافة المنتج
        final result = await _productRepository.addProduct(product);

        if (result.isSuccess) {
          print('✅ تم إضافة: ${product.name} (${product.code})');
          addedCount++;
        } else {
          print('❌ فشل في إضافة: ${product.name} - ${result.error}');
        }

        // توقف قصير لتجنب الضغط على قاعدة البيانات
        await Future.delayed(Duration(milliseconds: 100));
      } catch (e) {
        print('❌ خطأ في إضافة ${product.name}: $e');
      }
    }

    print('\n📊 نتائج الإضافة:');
    print('✅ تم إضافة: $addedCount منتج');
    print('⏭️ تم تخطي: $skippedCount منتج (موجود مسبقاً)');
  }

  /// التحقق من إعداد البيانات
  Future<void> _verifySetup() async {
    print('\n🔍 التحقق من البيانات المضافة...');

    try {
      final allProducts = await _productRepository.getAllProducts();

      if (allProducts.isError) {
        print('❌ فشل في استرجاع المنتجات: ${allProducts.error}');
        return;
      }

      final products = allProducts.data!;

      print('📦 إجمالي المنتجات في النظام: ${products.length}');

      if (products.isEmpty) {
        print('⚠️ لا توجد منتجات في النظام!');
        return;
      }

      // إحصائيات بالشركات
      final Map<String, int> companyCounts = {};
      int totalQuantity = 0;
      double totalValue = 0;

      for (final product in products) {
        // عد الشركات
        companyCounts[product.company] =
            (companyCounts[product.company] ?? 0) + 1;

        // حساب الكميات والقيم
        totalQuantity += product.quantity;
        totalValue += (product.salePrice * product.quantity);
      }

      print('\n📊 إحصائيات المنتجات:');
      companyCounts.forEach((company, count) {
        print('   $company: $count منتج');
      });

      print('\n💰 إحصائيات المخزون:');
      print('   إجمالي الكميات: $totalQuantity قطعة');
      print('   إجمالي القيمة: ${totalValue.toStringAsFixed(2)} ريال');

      // عرض عينة من المنتجات
      print('\n📋 عينة من المنتجات المتاحة:');
      for (int i = 0; i < products.length && i < 5; i++) {
        final product = products[i];
        print(
          '   ${i + 1}. ${product.name} (${product.code}) - ${product.quantity} قطعة',
        );
      }

      if (products.length > 5) {
        print('   ... و ${products.length - 5} منتج إضافي');
      }

      // اختبار البحث
      print('\n🔍 اختبار البحث عن المنتجات:');
      final testCodes = ['RICE001', 'TEA001', 'PEN001'];

      for (final code in testCodes) {
        final searchResult = await _productRepository.getProductByCode(code);

        if (searchResult.isSuccess && searchResult.data != null) {
          print('✅ تم العثور على منتج: $code');
        } else {
          print('❌ لم يتم العثور على منتج: $code');
        }
      }
    } catch (e) {
      print('❌ خطأ في التحقق من البيانات: $e');
    }
  }
}
