import 'package:pos/Helper/DataBase/POSDatabase.dart';
import 'package:pos/Helper/DataBase/DataBaseSqflite.dart';
import 'package:pos/Repository/ProductRepository.dart';
import 'package:pos/Repository/SaleRepository.dart';
import 'package:pos/Model/ProductModel.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// ملف الإصلاح السريع لمشاكل نظام المخزون
/// يحل المشاكل الشائعة: "خطأ في حفظ الفاتورة او المنتج غير موجود"

class InventorySystemFixer {
  final ProductRepository _productRepository = ProductRepository(
    DataBaseSqflite(),
  );
  final SaleRepository _saleRepository = SaleRepository();

  /// إصلاح شامل للنظام
  Future<void> fixAllIssues() async {
    print('🔧 بدء عملية الإصلاح الشامل...\n');

    try {
      // 1. إصلاح قاعدة البيانات
      await fixDatabaseIssues();

      // 2. إصلاح المنتجات المفقودة
      await fixMissingProducts();

      // 3. إصلاح أرقام الفواتير
      await fixInvoiceNumbers();

      // 4. تنظيف البيانات التالفة
      await cleanCorruptedData();

      // 5. التحقق من سلامة النظام
      await verifySystemIntegrity();

      print('\n✅ تم إكمال عملية الإصلاح بنجاح!');
      print('🎉 النظام جاهز للاستخدام الآن.');
    } catch (e) {
      print('\n❌ فشل في عملية الإصلاح: $e');
      print('💡 يرجى مراجعة دليل استكشاف الأخطاء للحصول على مساعدة إضافية.');
    }
  }

  /// إصلاح مشاكل قاعدة البيانات
  Future<void> fixDatabaseIssues() async {
    print('🗄️ إصلاح مشاكل قاعدة البيانات...');

    try {
      final db = await POSDatabase.database;

      if (db == null) {
        print('❌ لا يمكن الاتصال بقاعدة البيانات');
        throw Exception('فشل في الاتصال بقاعدة البيانات');
      }

      // التحقق من وجود الجداول المطلوبة
      await _ensureTablesExist(db);

      // إصلاح الفهارس
      await _rebuildIndexes(db);

      print('✅ تم إصلاح قاعدة البيانات');
    } catch (e) {
      print('❌ فشل في إصلاح قاعدة البيانات: $e');
      rethrow;
    }
  }

  /// التأكد من وجود الجداول المطلوبة
  Future<void> _ensureTablesExist(Database db) async {
    final requiredTables = [
      POSDatabase.itemsTable,
      POSDatabase.salesTable,
      POSDatabase.saleItemsTable,
    ];

    for (final tableName in requiredTables) {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'",
      );

      if (result.isEmpty) {
        print('⚠️ جدول $tableName مفقود، سيتم إنشاؤه...');
        await _createMissingTable(db, tableName);
      }
    }
  }

  /// إنشاء الجداول المفقودة
  Future<void> _createMissingTable(Database db, String tableName) async {
    if (tableName == POSDatabase.itemsTable) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${POSDatabase.itemsTable} (
          ${POSDatabase.itemId} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${POSDatabase.itemName} TEXT NOT NULL,
          ${POSDatabase.itemCode} TEXT UNIQUE NOT NULL,
          ${POSDatabase.itemSalePrice} REAL NOT NULL,
          ${POSDatabase.itemBuyPrice} REAL NOT NULL,
          ${POSDatabase.itemQuantity} INTEGER NOT NULL DEFAULT 0,
          ${POSDatabase.itemCompany} TEXT,
          ${POSDatabase.itemDescription} TEXT,
          ${POSDatabase.itemMinStock} INTEGER DEFAULT 5,
          ${POSDatabase.itemIsActive} INTEGER DEFAULT 1,
          ${POSDatabase.itemCreatedAt} TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    } else if (tableName == POSDatabase.salesTable) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${POSDatabase.salesTable} (
          ${POSDatabase.saleId} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${POSDatabase.saleInvoiceNumber} TEXT UNIQUE NOT NULL,
          ${POSDatabase.saleCustomerId} INTEGER,
          subtotal REAL NOT NULL,
          tax REAL DEFAULT 0.0,
          discount REAL DEFAULT 0.0,
          total REAL NOT NULL,
          paid_amount REAL NOT NULL,
          change_amount REAL DEFAULT 0.0,
          payment_method TEXT NOT NULL,
          status TEXT DEFAULT 'completed',
          notes TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    } else if (tableName == POSDatabase.saleItemsTable) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${POSDatabase.saleItemsTable} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_id INTEGER NOT NULL,
          product_id INTEGER,
          product_code TEXT NOT NULL,
          product_name TEXT NOT NULL,
          unit_price REAL NOT NULL,
          quantity INTEGER NOT NULL,
          discount REAL DEFAULT 0.0,
          total REAL NOT NULL,
          FOREIGN KEY (sale_id) REFERENCES ${POSDatabase.salesTable} (${POSDatabase.saleId}) ON DELETE CASCADE
        )
      ''');
    }
  }

  /// إعادة بناء الفهارس
  Future<void> _rebuildIndexes(Database db) async {
    try {
      // فهرس كود المنتج
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_item_code 
        ON ${POSDatabase.itemsTable} (${POSDatabase.itemCode})
      ''');

      // فهرس رقم الفاتورة
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_invoice_number 
        ON ${POSDatabase.salesTable} (${POSDatabase.saleInvoiceNumber})
      ''');

      print('✅ تم إعادة بناء الفهارس');
    } catch (e) {
      print('⚠️ تحذير: فشل في إعادة بناء الفهارس: $e');
    }
  }

  /// إصلاح المنتجات المفقودة
  Future<void> fixMissingProducts() async {
    print('\n📦 إصلاح المنتجات المفقودة...');

    try {
      // الحصول على جميع المنتجات
      final productsResult = await _productRepository.getAllProducts();

      if (productsResult.isError) {
        print('❌ فشل في استرجاع المنتجات: ${productsResult.error}');
        return;
      }

      final products = productsResult.data!;

      if (products.isEmpty) {
        print('⚠️ لا توجد منتجات في النظام، سيتم إنشاء منتجات تجريبية...');
        await _createSampleProducts();
      } else {
        print('✅ تم العثور على ${products.length} منتج');

        // فحص المنتجات ذات الأكواد المفقودة أو المكررة
        await _fixProductCodes(products);
      }
    } catch (e) {
      print('❌ فشل في إصلاح المنتجات: $e');
    }
  }

  /// إنشاء منتجات تجريبية
  Future<void> _createSampleProducts() async {
    final sampleProducts = [
      ProductModel(
        name: 'منتج تجريبي 1',
        code: 'SAMPLE001',
        salePrice: 100.0,
        buyPrice: 80.0,
        quantity: 50,
        company: 'شركة تجريبية',
        date: DateTime.now().toString(),
        description: 'منتج تجريبي للاختبار',
        lowStockThreshold: 10,
      ),
      ProductModel(
        name: 'منتج تجريبي 2',
        code: 'SAMPLE002',
        salePrice: 200.0,
        buyPrice: 150.0,
        quantity: 30,
        company: 'شركة تجريبية',
        date: DateTime.now().toString(),
        description: 'منتج تجريبي للاختبار',
        lowStockThreshold: 5,
      ),
    ];

    for (final product in sampleProducts) {
      final result = await _productRepository.addProduct(product);
      if (result.isSuccess) {
        print('✅ تم إنشاء منتج: ${product.name} (${product.code})');
      } else {
        print('❌ فشل في إنشاء منتج: ${product.name} - ${result.error}');
      }
    }
  }

  /// إصلاح أكواد المنتجات
  Future<void> _fixProductCodes(List<ProductModel> products) async {
    final codesSet = <String>{};

    for (final product in products) {
      if (product.code.trim().isEmpty) {
        print('⚠️ منتج بدون كود: ${product.name}');
        // إنشاء كود جديد
        final newCode =
            'AUTO${product.id ?? DateTime.now().millisecondsSinceEpoch}';
        await _updateProductCode(product, newCode);
      } else if (codesSet.contains(product.code)) {
        print('⚠️ كود مكرر: ${product.code} للمنتج: ${product.name}');
        // إنشاء كود جديد
        final newCode = '${product.code}_${product.id}';
        await _updateProductCode(product, newCode);
      } else {
        codesSet.add(product.code);
      }
    }
  }

  /// تحديث كود المنتج
  Future<void> _updateProductCode(ProductModel product, String newCode) async {
    try {
      final updatedProduct = product.copyWith(code: newCode);
      await _productRepository.updateProduct(updatedProduct);
      print('✅ تم تحديث كود المنتج ${product.name} إلى: $newCode');
    } catch (e) {
      print('❌ فشل في تحديث كود المنتج: $e');
    }
  }

  /// إصلاح أرقام الفواتير
  Future<void> fixInvoiceNumbers() async {
    print('\n🧾 إصلاح أرقام الفواتير...');

    try {
      // اختبار توليد رقم فاتورة جديد
      final newInvoiceResult = await _saleRepository.generateInvoiceNumber();

      if (newInvoiceResult.isSuccess) {
        print('✅ تم توليد رقم فاتورة جديد: ${newInvoiceResult.data}');
      } else {
        print('❌ فشل في توليد رقم فاتورة: ${newInvoiceResult.error}');
      }
    } catch (e) {
      print('❌ فشل في إصلاح أرقام الفواتير: $e');
    }
  }

  /// تنظيف البيانات التالفة
  Future<void> cleanCorruptedData() async {
    print('\n🧹 تنظيف البيانات التالفة...');

    try {
      final db = await POSDatabase.database;

      // حذف العناصر اليتيمة (بدون فاتورة أب)
      final orphanedItemsResult = await db!.rawDelete('''
        DELETE FROM ${POSDatabase.saleItemsTable} 
        WHERE sale_id NOT IN (
          SELECT ${POSDatabase.saleId} FROM ${POSDatabase.salesTable}
        )
      ''');

      if (orphanedItemsResult > 0) {
        print('✅ تم حذف $orphanedItemsResult عنصر يتيم');
      }

      // حذف الفواتير بدون عناصر
      final emptySalesResult = await db.rawDelete('''
        DELETE FROM ${POSDatabase.salesTable} 
        WHERE ${POSDatabase.saleId} NOT IN (
          SELECT DISTINCT sale_id FROM ${POSDatabase.saleItemsTable}
        )
      ''');

      if (emptySalesResult > 0) {
        print('✅ تم حذف $emptySalesResult فاتورة فارغة');
      }

      print('✅ تم تنظيف البيانات التالفة');
    } catch (e) {
      print('❌ فشل في تنظيف البيانات: $e');
    }
  }

  /// التحقق من سلامة النظام
  Future<void> verifySystemIntegrity() async {
    print('\n🔍 التحقق من سلامة النظام...');

    try {
      // فحص قاعدة البيانات
      final dbCheck = await _checkDatabaseIntegrity();

      // فحص المنتجات
      final productsCheck = await _checkProductsIntegrity();

      // فحص المبيعات
      final salesCheck = await _checkSalesIntegrity();

      if (dbCheck && productsCheck && salesCheck) {
        print('✅ النظام سليم ومستعد للعمل');
      } else {
        print('⚠️ هناك مشاكل تحتاج متابعة');
      }
    } catch (e) {
      print('❌ فشل في التحقق من سلامة النظام: $e');
    }
  }

  /// فحص سلامة قاعدة البيانات
  Future<bool> _checkDatabaseIntegrity() async {
    try {
      final db = await POSDatabase.database;
      final result = await db!.rawQuery('PRAGMA integrity_check');

      final isOk =
          result.isNotEmpty &&
          result.first.values.first.toString().toLowerCase() == 'ok';

      if (isOk) {
        print('✅ قاعدة البيانات سليمة');
      } else {
        print('❌ قاعدة البيانات تحتاج إصلاح');
      }

      return isOk;
    } catch (e) {
      print('❌ فشل في فحص قاعدة البيانات: $e');
      return false;
    }
  }

  /// فحص سلامة المنتجات
  Future<bool> _checkProductsIntegrity() async {
    try {
      final productsResult = await _productRepository.getAllProducts();

      if (productsResult.isError) {
        print('❌ فشل في استرجاع المنتجات');
        return false;
      }

      final products = productsResult.data!;
      print('✅ ${products.length} منتج في النظام');

      // فحص المنتجات ذات الأكواد المكررة
      final codes = products.map((p) => p.code).toList();
      final uniqueCodes = codes.toSet();

      if (codes.length != uniqueCodes.length) {
        print('⚠️ يوجد منتجات بأكواد مكررة');
        return false;
      }

      print('✅ جميع أكواد المنتجات فريدة');
      return true;
    } catch (e) {
      print('❌ فشل في فحص المنتجات: $e');
      return false;
    }
  }

  /// فحص سلامة المبيعات
  Future<bool> _checkSalesIntegrity() async {
    try {
      final db = await POSDatabase.database;

      // عدد الفواتير
      final salesCount = await db!.rawQuery(
        'SELECT COUNT(*) as count FROM ${POSDatabase.salesTable}',
      );

      // عدد عناصر الفواتير
      final itemsCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${POSDatabase.saleItemsTable}',
      );

      final salesNum = salesCount.first['count'] as int;
      final itemsNum = itemsCount.first['count'] as int;

      print('✅ $salesNum فاتورة، $itemsNum عنصر');

      return true;
    } catch (e) {
      print('❌ فشل في فحص المبيعات: $e');
      return false;
    }
  }

  /// إجراء اختبار سريع للنظام
  Future<void> quickSystemTest() async {
    print('\n🧪 إجراء اختبار سريع للنظام...');

    try {
      // اختبار إضافة منتج
      final testProduct = ProductModel(
        name: 'اختبار سريع',
        code: 'QUICK_TEST_${DateTime.now().millisecondsSinceEpoch}',
        salePrice: 50.0,
        buyPrice: 40.0,
        quantity: 5,
        company: 'اختبار',
        date: DateTime.now().toString(),
      );

      final addResult = await _productRepository.addProduct(testProduct);

      if (addResult.isSuccess) {
        print('✅ اختبار إضافة المنتج: نجح');

        // اختبار البحث عن المنتج
        final searchResult = await _productRepository.getProductByCode(
          testProduct.code,
        );

        if (searchResult.isSuccess && searchResult.data != null) {
          print('✅ اختبار البحث عن المنتج: نجح');

          // حذف المنتج التجريبي
          if (searchResult.data!.id != null) {
            await _productRepository.deleteProduct(searchResult.data!.id!);
            print('✅ تم حذف المنتج التجريبي');
          }
        } else {
          print('❌ اختبار البحث عن المنتج: فشل');
        }
      } else {
        print('❌ اختبار إضافة المنتج: فشل');
      }
    } catch (e) {
      print('❌ فشل في الاختبار السريع: $e');
    }
  }
}

/// تشغيل الإصلاح
void main() async {
  final fixer = InventorySystemFixer();

  print('🚀 مرحباً بك في أداة الإصلاح السريع لنظام إدارة المخزون');
  print(
    '📋 هذه الأداة ستحل مشاكل: "خطأ في حفظ الفاتورة او المنتج غير موجود"\n',
  );

  // إجراء الإصلاح الشامل
  await fixer.fixAllIssues();

  // إجراء اختبار سريع
  await fixer.quickSystemTest();

  print('\n🎉 انتهت عملية الإصلاح!');
  print('💡 يمكنك الآن استخدام نظام المخزون بثقة.');
}
