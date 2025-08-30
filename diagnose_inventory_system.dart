import 'package:pos/Helper/DataBase/POSDatabase.dart';
import 'package:pos/Helper/DataBase/DataBaseSqflite.dart';
import 'package:pos/Repository/ProductRepository.dart';
import 'package:pos/Repository/SaleRepository.dart';
import 'package:pos/Controller/SaleProvider.dart';

/// تشخيص سريع لمشكلة: "عند عملية الدفع يقول لي خطأ في حفظ الفاتورة او المنتج غير موجود"

void main() async {
  print('🔍 تشخيص مشكلة نظام المخزون...\n');

  final diagnostics = InventoryDiagnostics();
  await diagnostics.runFullDiagnostics();
}

class InventoryDiagnostics {
  final ProductRepository _productRepository = ProductRepository(
    DataBaseSqflite(),
  );
  final SaleRepository _saleRepository = SaleRepository();

  /// تشخيص شامل للنظام
  Future<void> runFullDiagnostics() async {
    print('🚀 بدء التشخيص الشامل...\n');

    var issuesFound = 0;

    // 1. فحص قاعدة البيانات
    issuesFound += await _diagnoseDatabaseConnection();

    // 2. فحص المنتجات
    issuesFound += await _diagnoseProducts();

    // 3. فحص نظام الفواتير
    issuesFound += await _diagnoseSalesSystem();

    // 4. محاكاة عملية بيع
    issuesFound += await _simulateSaleProcess();

    // 5. النتيجة النهائية
    _showFinalDiagnosis(issuesFound);
  }

  /// فحص اتصال قاعدة البيانات
  Future<int> _diagnoseDatabaseConnection() async {
    print('📊 فحص قاعدة البيانات...');
    int issues = 0;

    try {
      final db = await POSDatabase.database;

      if (db == null) {
        print('❌ لا يمكن الاتصال بقاعدة البيانات');
        issues++;
      } else {
        print('✅ الاتصال بقاعدة البيانات سليم');

        // فحص الجداول المطلوبة
        final tables = [
          POSDatabase.itemsTable,
          POSDatabase.salesTable,
          POSDatabase.saleItemsTable,
        ];

        for (final table in tables) {
          final result = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='$table'",
          );

          if (result.isEmpty) {
            print('❌ جدول $table غير موجود');
            issues++;
          } else {
            print('✅ جدول $table موجود');
          }
        }
      }
    } catch (e) {
      print('❌ خطأ في فحص قاعدة البيانات: $e');
      issues++;
    }

    print('');
    return issues;
  }

  /// فحص المنتجات
  Future<int> _diagnoseProducts() async {
    print('📦 فحص المنتجات...');
    int issues = 0;

    try {
      final productsResult = await _productRepository.getAllProducts();

      if (productsResult.isError) {
        print('❌ فشل في استرجاع المنتجات: ${productsResult.error}');
        issues++;
      } else {
        final products = productsResult.data!;
        print('✅ تم استرجاع ${products.length} منتج');

        if (products.isEmpty) {
          print('⚠️ لا توجد منتجات في النظام');
          issues++;
        } else {
          // فحص المنتجات
          final problematicProducts = <String>[];
          final codes = <String>[];

          for (final product in products) {
            // فحص الكود
            if (product.code.trim().isEmpty) {
              problematicProducts.add('${product.name}: كود فارغ');
            }

            // فحص الكمية
            if (product.quantity < 0) {
              problematicProducts.add(
                '${product.name}: كمية سالبة (${product.quantity})',
              );
            }

            // فحص الأكواد المكررة
            if (codes.contains(product.code)) {
              problematicProducts.add(
                '${product.name}: كود مكرر (${product.code})',
              );
            } else {
              codes.add(product.code);
            }
          }

          if (problematicProducts.isNotEmpty) {
            print('⚠️ مشاكل في المنتجات:');
            for (final problem in problematicProducts) {
              print('   - $problem');
            }
            issues += problematicProducts.length;
          } else {
            print('✅ جميع المنتجات سليمة');
          }
        }
      }
    } catch (e) {
      print('❌ خطأ في فحص المنتجات: $e');
      issues++;
    }

    print('');
    return issues;
  }

  /// فحص نظام المبيعات
  Future<int> _diagnoseSalesSystem() async {
    print('💰 فحص نظام المبيعات...');
    int issues = 0;

    try {
      // اختبار توليد رقم فاتورة
      final invoiceResult = await _saleRepository.generateInvoiceNumber();

      if (invoiceResult.isError) {
        print('❌ فشل في توليد رقم فاتورة: ${invoiceResult.error}');
        issues++;
      } else {
        print('✅ تم توليد رقم فاتورة: ${invoiceResult.data}');
      }

      // فحص جدول المبيعات
      final db = await POSDatabase.database;
      final salesCount = await db!.rawQuery(
        'SELECT COUNT(*) as count FROM ${POSDatabase.salesTable}',
      );

      final count = salesCount.first['count'] as int;
      print('📊 عدد الفواتير المحفوظة: $count');
    } catch (e) {
      print('❌ خطأ في فحص نظام المبيعات: $e');
      issues++;
    }

    print('');
    return issues;
  }

  /// محاكاة عملية بيع
  Future<int> _simulateSaleProcess() async {
    print('🛒 محاكاة عملية بيع...');
    int issues = 0;

    try {
      // الحصول على منتج للاختبار
      final productsResult = await _productRepository.getAllProducts();

      if (productsResult.isError || productsResult.data!.isEmpty) {
        print('❌ لا توجد منتجات للاختبار');
        return 1;
      }

      final testProduct = productsResult.data!.first;
      print(
        '🧪 استخدام منتج للاختبار: ${testProduct.name} (${testProduct.code})',
      );

      // اختبار البحث عن المنتج
      final searchResult = await _productRepository.getProductByCode(
        testProduct.code,
      );

      if (searchResult.isError || searchResult.data == null) {
        print('❌ فشل في البحث عن المنتج: ${searchResult.error}');
        issues++;
      } else {
        print('✅ تم العثور على المنتج بنجاح');

        // اختبار إنشاء SaleProvider
        try {
          final saleProvider = SaleProvider();
          print('✅ تم إنشاء SaleProvider بنجاح');

          // اختبار إضافة منتج للفاتورة
          if (testProduct.quantity > 0) {
            final addResult = await saleProvider.addProductToSale(testProduct);

            if (addResult) {
              print('✅ تم إضافة المنتج للفاتورة');

              // تعيين المبلغ المدفوع
              saleProvider.updatePaidAmount(saleProvider.total);

              // التحقق من إمكانية إتمام البيع
              if (saleProvider.canCompleteSale) {
                print('✅ الفاتورة جاهزة للإتمام');

                // محاولة إتمام البيع (بدون حفظ فعلي)
                print('⚠️ تخطي إتمام البيع لتجنب تعديل البيانات');
              } else {
                print('❌ الفاتورة غير جاهزة للإتمام');
                print('   السبب: ${saleProvider.errorMessage}');
                issues++;
              }
            } else {
              print('❌ فشل في إضافة المنتج للفاتورة');
              print('   السبب: ${saleProvider.errorMessage}');
              issues++;
            }
          } else {
            print('⚠️ المنتج نفد من المخزون (الكمية: ${testProduct.quantity})');
          }
        } catch (e) {
          print('❌ خطأ في إنشاء SaleProvider: $e');
          issues++;
        }
      }
    } catch (e) {
      print('❌ خطأ في محاكاة عملية البيع: $e');
      issues++;
    }

    print('');
    return issues;
  }

  /// عرض التشخيص النهائي
  void _showFinalDiagnosis(int issuesCount) {
    print('📋 تقرير التشخيص النهائي');
    print('=' * 50);

    if (issuesCount == 0) {
      print('🎉 ممتاز! لم يتم العثور على أي مشاكل');
      print('✅ النظام جاهز للاستخدام');
      print('\n💡 إذا كنت ما زلت تواجه مشاكل، تحقق من:');
      print('   - صحة البيانات المدخلة');
      print('   - اتصال الإنترنت (إن وجد)');
      print('   - إعادة تشغيل التطبيق');
    } else {
      print('⚠️ تم العثور على $issuesCount مشكلة');
      print('\n🔧 الحلول المقترحة:');

      print('\n1. تشغيل أداة الإصلاح التلقائي:');
      print('   dart fix_inventory_system.dart');

      print('\n2. إعادة تهيئة قاعدة البيانات:');
      print('   - احذف ملف قاعدة البيانات');
      print('   - أعد تشغيل التطبيق');

      print('\n3. إضافة منتجات تجريبية:');
      print('   - استخدم شاشة إدارة المنتجات');
      print('   - أضف منتج واحد على الأقل للاختبار');

      print('\n4. التحقق من الأخطاء:');
      print('   - راجع رسائل الأخطاء أعلاه');
      print('   - طبق الحلول المناسبة لكل مشكلة');
    }

    print('\n📞 للمساعدة الإضافية:');
    print('   - راجع ملف TROUBLESHOOTING_GUIDE.md');
    print('   - استخدم أدوات التشخيص المتقدمة');
    print('   - تحقق من وثائق النظام');

    print('\n🎯 خطوات الاختبار النهائي:');
    print('   1. أضف منتج جديد');
    print('   2. ابحث عن المنتج بالكود');
    print('   3. أنشئ فاتورة واحفظها');
    print('   4. تحقق من تحديث المخزون');
  }
}
