#!/usr/bin/env dart

import 'dart:io';
import 'dart:async';

/// أداة تشخيص بسيطة لمشكلة "المنتج غير موجود"
/// تعمل بدون مكتبات Flutter

void main() async {
  print('🔍 تشخيص مشكلة نظام المخزون - بدء التشخيص...\n');

  final diagnostics = SimpleDiagnostics();
  await diagnostics.runDiagnostics();
}

class SimpleDiagnostics {
  /// تشخيص شامل للنظام
  Future<void> runDiagnostics() async {
    print('🚀 بدء التشخيص البسيط...\n');

    var issuesFound = 0;

    // 1. فحص ملفات النظام
    issuesFound += await _checkSystemFiles();

    // 2. فحص قاعدة البيانات
    issuesFound += await _checkDatabaseFile();

    // 3. فحص الملفات المهمة
    issuesFound += await _checkImportantFiles();

    // 4. فحص أدوات التشخيص
    issuesFound += await _checkDiagnosticTools();

    // 5. النتيجة النهائية
    _showFinalResult(issuesFound);
  }

  /// فحص ملفات النظام الأساسية
  Future<int> _checkSystemFiles() async {
    print('📁 فحص ملفات النظام...');
    int issues = 0;

    final systemFiles = [
      'lib/Controller/SaleProvider.dart',
      'lib/Repository/SaleRepository.dart',
      'lib/Repository/ProductRepository.dart',
      'lib/Model/ProductModel.dart',
      'lib/Model/SaleModel.dart',
      'lib/Helper/DataBase/POSDatabase.dart',
    ];

    for (final filePath in systemFiles) {
      final file = File(filePath);
      if (await file.exists()) {
        print('✅ $filePath موجود');
      } else {
        print('❌ $filePath مفقود');
        issues++;
      }
    }

    print('');
    return issues;
  }

  /// فحص ملف قاعدة البيانات
  Future<int> _checkDatabaseFile() async {
    print('🗄️ فحص قاعدة البيانات...');
    int issues = 0;

    // البحث عن ملف قاعدة البيانات في المواقع المحتملة
    final possiblePaths = [
      'database/pos_database.db',
      'data/pos_database.db',
      'pos_database.db',
      'databases/pos_database.db',
    ];

    bool dbFound = false;
    for (final dbPath in possiblePaths) {
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        print('✅ قاعدة البيانات موجودة في: $dbPath');

        // التحقق من حجم الملف
        final stats = await dbFile.stat();
        print('   حجم الملف: ${stats.size} بايت');

        if (stats.size == 0) {
          print('⚠️ قاعدة البيانات فارغة');
          issues++;
        }

        dbFound = true;
        break;
      }
    }

    if (!dbFound) {
      print('⚠️ لم يتم العثور على ملف قاعدة البيانات');
      print('💡 قد يتم إنشاؤها عند تشغيل التطبيق لأول مرة');
    }

    print('');
    return issues;
  }

  /// فحص الملفات المهمة
  Future<int> _checkImportantFiles() async {
    print('📋 فحص الملفات المهمة...');
    int issues = 0;

    final importantFiles = [
      'pubspec.yaml',
      'lib/main.dart',
      'android/app/build.gradle.kts',
    ];

    for (final filePath in importantFiles) {
      final file = File(filePath);
      if (await file.exists()) {
        print('✅ $filePath موجود');

        // قراءة محتوى pubspec.yaml للتحقق من التبعيات
        if (filePath == 'pubspec.yaml') {
          final content = await file.readAsString();

          final requiredDeps = ['sqflite', 'provider', 'path'];
          for (final dep in requiredDeps) {
            if (content.contains(dep)) {
              print('   ✅ تبعية $dep موجودة');
            } else {
              print('   ❌ تبعية $dep مفقودة');
              issues++;
            }
          }
        }
      } else {
        print('❌ $filePath مفقود');
        issues++;
      }
    }

    print('');
    return issues;
  }

  /// فحص أدوات التشخيص
  Future<int> _checkDiagnosticTools() async {
    print('🛠️ فحص أدوات التشخيص...');
    int issues = 0;

    final diagnosticTools = [
      'diagnose_inventory_system.dart',
      'fix_inventory_system.dart',
      'test_inventory_system.dart',
      'setup_sample_data.dart',
      'TROUBLESHOOTING_GUIDE.md',
      'QUICK_FIX_GUIDE.md',
      'FINAL_SOLUTION_SUMMARY.md',
    ];

    for (final toolPath in diagnosticTools) {
      final file = File(toolPath);
      if (await file.exists()) {
        print('✅ $toolPath موجود');
      } else {
        print('⚠️ $toolPath مفقود (يمكن إنشاؤه)');
      }
    }

    print('');
    return issues;
  }

  /// عرض النتيجة النهائية
  void _showFinalResult(int issuesCount) {
    print('📋 تقرير التشخيص النهائي');
    print('=' * 50);

    if (issuesCount == 0) {
      print('🎉 ممتاز! البنية الأساسية للنظام سليمة');
      print('');
      print('🎯 خطوات الحل التالية:');
      print('1. تشغيل التطبيق وإنشاء قاعدة البيانات');
      print('2. إضافة منتجات تجريبية');
      print('3. اختبار عملية البيع');
    } else if (issuesCount <= 3) {
      print('⚠️ تم العثور على مشاكل بسيطة ($issuesCount مشكلة)');
      print('');
      print('🔧 حلول سريعة:');
      _showQuickFixes();
    } else {
      print('❌ تم العثور على مشاكل متعددة ($issuesCount مشكلة)');
      print('');
      print('🚨 مطلوب إصلاح شامل:');
      _showComprehensiveFixes();
    }

    print('');
    print('🎯 للتركيز على مشكلة "المنتج غير موجود":');
    print('');
    print('أسباب المشكلة المحتملة:');
    print('1. كود المنتج خاطئ أو غير موجود (70%)');
    print('2. قاعدة البيانات فارغة من المنتجات (20%)');
    print('3. مشكلة في الاتصال بقاعدة البيانات (10%)');
    print('');

    print('خطوات الحل السريع:');
    print('1. افتح التطبيق واذهب لإدارة المنتجات');
    print('2. تحقق من وجود منتجات في القائمة');
    print('3. إذا لم توجد منتجات، أضف منتج تجريبي');
    print('4. احفظ كود المنتج واستخدمه في البيع');
    print('5. تحقق من رسالة الخطأ الدقيقة');

    print('');
    print('🔍 لمزيد من التشخيص المتقدم:');
    print('- افتح التطبيق وانتقل لشاشة المبيعات');
    print('- جرب إضافة منتج وراقب رسالة الخطأ');
    print('- تحقق من تطابق كود المنتج المدخل مع المحفوظ');
  }

  /// عرض حلول سريعة
  void _showQuickFixes() {
    print('• تحقق من تشغيل flutter pub get');
    print('• تحقق من وجود المنتجات في التطبيق');
    print('• أعد تشغيل التطبيق');
    print('• امسح cache التطبيق');
  }

  /// عرض حلول شاملة
  void _showComprehensiveFixes() {
    print('• نشغل flutter clean && flutter pub get');
    print('• تحقق من إعدادات Android/iOS');
    print('• أعد تثبيت التبعيات المفقودة');
    print('• راجع ملفات النظام المفقودة');
    print('• فكر في إعادة إنشاء المشروع');
  }
}
