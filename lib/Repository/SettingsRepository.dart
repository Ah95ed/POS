import 'package:pos/Helper/DataBase/DataBaseSqflite.dart';
import 'package:pos/Helper/Result.dart';
import 'package:pos/Model/SettingsModel.dart';

/// مستودع الإعدادات - Settings Repository
/// يتعامل مع تخزين واسترجاع إعدادات التطبيق من قاعدة البيانات
class SettingsRepository {
  final DataBaseSqflite _database;

  // اسم جدول الإعدادات
  static const String tableName = 'settings_table';

  // أسماء الأعمدة
  static const String columnId = 'id';
  static const String columnLanguage = 'language';
  static const String columnTheme = 'theme';
  static const String columnCurrency = 'currency';
  static const String columnNotifications = 'notifications';
  static const String columnStoreName = 'storeName';
  static const String columnPhone = 'phone';

  SettingsRepository(this._database) {
    _initSettingsTable();
  }

  /// تهيئة جدول الإعدادات إذا لم يكن موجوداً
  Future<void> _initSettingsTable() async {
    final db = await DataBaseSqflite.databasesq;

    // إنشاء جدول الإعدادات إذا لم يكن موجوداً
    await db?.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnLanguage TEXT NOT NULL,
        $columnTheme INTEGER NOT NULL,
        $columnCurrency TEXT NOT NULL,
        $columnNotifications INTEGER NOT NULL,
        $columnStoreName TEXT NOT NULL,
        $columnPhone TEXT NOT NULL
      )
    ''');

    // التحقق من وجود إعدادات افتراضية
    final settings = await getSettings();
    if (settings.isSuccess && settings.data == null) {
      // إضافة إعدادات افتراضية إذا لم تكن موجودة
      await saveSettings(SettingsModel.defaultSettings());
    }
  }

  /// حفظ الإعدادات في قاعدة البيانات
  Future<Result<bool>> saveSettings(SettingsModel settings) async {
    try {
      final db = await DataBaseSqflite.databasesq;

      // التحقق من وجود إعدادات سابقة
      final existingSettings = await getSettings();

      if (existingSettings.isSuccess && existingSettings.data != null) {
        // تحديث الإعدادات الموجودة
        await db?.update(
          tableName,
          settings.toMap(),
          where: '$columnId = ?',
          whereArgs: [existingSettings.data!.id],
        );
      } else {
        // إضافة إعدادات جديدة
        await db?.insert(tableName, settings.toMap());
      }

      return Result.success(true);
    } catch (e) {
      return Result.error('خطأ في حفظ الإعدادات: ${e.toString()}');
    }
  }

  /// الحصول على الإعدادات الحالية
  Future<Result<SettingsModel?>> getSettings() async {
    try {
      final db = await DataBaseSqflite.databasesq;

      final List<Map<String, dynamic>>? maps = await db?.query(tableName);

      if (maps != null && maps.isNotEmpty) {
        return Result.success(SettingsModel.fromMap(maps.first));
      } else {
        return Result.success(null);
      }
    } catch (e) {
      return Result.error('خطأ في استرجاع الإعدادات: ${e.toString()}');
    }
  }

  /// تحديث إعدادات محددة
  Future<Result<bool>> updateSettings(SettingsModel settings) async {
    try {
      final db = await DataBaseSqflite.databasesq;

      await db?.update(
        tableName,
        settings.toMap(),
        where: '$columnId = ?',
        whereArgs: [settings.id],
      );

      return Result.success(true);
    } catch (e) {
      return Result.error('خطأ في تحديث الإعدادات: ${e.toString()}');
    }
  }
}
