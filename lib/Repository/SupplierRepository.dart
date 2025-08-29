import 'package:pos/Helper/DataBase/POSDatabase.dart';
import 'package:pos/Helper/Result.dart';
import 'package:pos/Model/SupplierModel.dart';

/// مستودع الموردين - Supplier Repository
/// يدير جميع العمليات المتعلقة بقاعدة البيانات للموردين
class SupplierRepository {
  /// الحصول على جميع الموردين
  Future<Result<List<SupplierModel>>> getAllSuppliers() async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        POSDatabase.suppliersTable,
        orderBy: '${POSDatabase.supplierName} ASC',
      );

      final suppliers = maps.map((map) => SupplierModel.fromMap(map)).toList();
      return Result.success(suppliers);
    } catch (e) {
      return Result.error('خطأ في جلب الموردين: ${e.toString()}');
    }
  }

  /// الحصول على الموردين النشطين فقط
  Future<Result<List<SupplierModel>>> getActiveSuppliers() async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        POSDatabase.suppliersTable,
        where: '${POSDatabase.supplierIsActive} = ?',
        whereArgs: [1],
        orderBy: '${POSDatabase.supplierName} ASC',
      );

      final suppliers = maps.map((map) => SupplierModel.fromMap(map)).toList();
      return Result.success(suppliers);
    } catch (e) {
      return Result.error('خطأ في جلب الموردين النشطين: ${e.toString()}');
    }
  }

  /// الحصول على مورد بالمعرف
  Future<Result<SupplierModel?>> getSupplierById(int id) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        POSDatabase.suppliersTable,
        where: '${POSDatabase.supplierId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return Result.success(null);
      }

      final supplier = SupplierModel.fromMap(maps.first);
      return Result.success(supplier);
    } catch (e) {
      return Result.error('خطأ في جلب المورد: ${e.toString()}');
    }
  }

  /// إضافة مورد جديد
  Future<Result<SupplierModel>> addSupplier(SupplierModel supplier) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      if (!supplier.isValid) {
        return Result.error('بيانات المورد غير صحيحة');
      }

      // التحقق من عدم وجود مورد بنفس الاسم
      final existingSupplier = await getSupplierByName(supplier.name);
      if (existingSupplier.isSuccess && existingSupplier.data != null) {
        return Result.error('مورد بهذا الاسم موجود بالفعل');
      }

      final id = await db.insert(POSDatabase.suppliersTable, supplier.toMap());

      final newSupplier = supplier.copyWith(id: id);
      return Result.success(newSupplier);
    } catch (e) {
      return Result.error('خطأ في إضافة المورد: ${e.toString()}');
    }
  }

  /// تحديث مورد
  Future<Result<SupplierModel>> updateSupplier(SupplierModel supplier) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      if (!supplier.isValid || supplier.id == null) {
        return Result.error('بيانات المورد غير صحيحة');
      }

      final rowsAffected = await db.update(
        POSDatabase.suppliersTable,
        supplier.toMap(),
        where: '${POSDatabase.supplierId} = ?',
        whereArgs: [supplier.id],
      );

      if (rowsAffected == 0) {
        return Result.error('المورد غير موجود');
      }

      return Result.success(supplier);
    } catch (e) {
      return Result.error('خطأ في تحديث المورد: ${e.toString()}');
    }
  }

  /// حذف مورد
  Future<Result<bool>> deleteSupplier(int supplierId) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      // التحقق من عدم وجود مشتريات مرتبطة بالمورد
      final purchasesResult = await db.rawQuery(
        '''
        SELECT COUNT(*) as count 
        FROM ${POSDatabase.purchasesTable} 
        WHERE ${POSDatabase.purchaseSupplierId} = ?
      ''',
        [supplierId],
      );

      final purchasesCount = purchasesResult.first['count'] as int;
      if (purchasesCount > 0) {
        return Result.error('لا يمكن حذف المورد لوجود مشتريات مرتبطة به');
      }

      final rowsAffected = await db.delete(
        POSDatabase.suppliersTable,
        where: '${POSDatabase.supplierId} = ?',
        whereArgs: [supplierId],
      );

      return Result.success(rowsAffected > 0);
    } catch (e) {
      return Result.error('خطأ في حذف المورد: ${e.toString()}');
    }
  }

  /// البحث عن مورد بالاسم
  Future<Result<SupplierModel?>> getSupplierByName(String name) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        POSDatabase.suppliersTable,
        where: '${POSDatabase.supplierName} = ?',
        whereArgs: [name],
        limit: 1,
      );

      if (maps.isEmpty) {
        return Result.success(null);
      }

      final supplier = SupplierModel.fromMap(maps.first);
      return Result.success(supplier);
    } catch (e) {
      return Result.error('خطأ في البحث عن المورد: ${e.toString()}');
    }
  }

  /// البحث في الموردين
  Future<Result<List<SupplierModel>>> searchSuppliers(String query) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        POSDatabase.suppliersTable,
        where:
            '''
          ${POSDatabase.supplierName} LIKE ? OR 
          ${POSDatabase.supplierCompany} LIKE ? OR 
          ${POSDatabase.supplierPhone} LIKE ? OR 
          ${POSDatabase.supplierEmail} LIKE ?
        ''',
        whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
        orderBy: '${POSDatabase.supplierName} ASC',
      );

      final suppliers = maps.map((map) => SupplierModel.fromMap(map)).toList();
      return Result.success(suppliers);
    } catch (e) {
      return Result.error('خطأ في البحث: ${e.toString()}');
    }
  }

  /// تفعيل/إلغاء تفعيل مورد
  Future<Result<bool>> toggleSupplierStatus(
    int supplierId,
    bool isActive,
  ) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final rowsAffected = await db.update(
        POSDatabase.suppliersTable,
        {POSDatabase.supplierIsActive: isActive ? 1 : 0},
        where: '${POSDatabase.supplierId} = ?',
        whereArgs: [supplierId],
      );

      return Result.success(rowsAffected > 0);
    } catch (e) {
      return Result.error('خطأ في تحديث حالة المورد: ${e.toString()}');
    }
  }

  /// تحديث إجمالي المشتريات للمورد
  Future<Result<bool>> updateSupplierTotalPurchases(int supplierId) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      // حساب إجمالي المشتريات المكتملة
      final result = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(${POSDatabase.purchaseTotal}), 0) as total
        FROM ${POSDatabase.purchasesTable}
        WHERE ${POSDatabase.purchaseSupplierId} = ? 
        AND ${POSDatabase.purchaseStatus} = 'completed'
      ''',
        [supplierId],
      );

      final totalPurchases = result.first['total'] as double;

      final rowsAffected = await db.update(
        POSDatabase.suppliersTable,
        {POSDatabase.supplierTotalPurchases: totalPurchases},
        where: '${POSDatabase.supplierId} = ?',
        whereArgs: [supplierId],
      );

      return Result.success(rowsAffected > 0);
    } catch (e) {
      return Result.error('خطأ في تحديث إجمالي المشتريات: ${e.toString()}');
    }
  }

  /// الحصول على أفضل الموردين (بحسب المشتريات)
  Future<Result<List<SupplierModel>>> getTopSuppliers({int limit = 5}) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        POSDatabase.suppliersTable,
        where:
            '${POSDatabase.supplierIsActive} = ? AND ${POSDatabase.supplierTotalPurchases} > 0',
        whereArgs: [1],
        orderBy: '${POSDatabase.supplierTotalPurchases} DESC',
        limit: limit,
      );

      final suppliers = maps.map((map) => SupplierModel.fromMap(map)).toList();
      return Result.success(suppliers);
    } catch (e) {
      return Result.error('خطأ في جلب أفضل الموردين: ${e.toString()}');
    }
  }

  /// إحصائيات الموردين
  Future<Result<SupplierStats>> getSuppliersStats() async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      // إجمالي الموردين
      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${POSDatabase.suppliersTable}',
      );
      final totalSuppliers = totalResult.first['count'] as int;

      // الموردين النشطين
      final activeResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${POSDatabase.suppliersTable} WHERE ${POSDatabase.supplierIsActive} = 1',
      );
      final activeSuppliers = activeResult.first['count'] as int;

      // إجمالي المشتريات
      final purchasesResult = await db.rawQuery(
        'SELECT COALESCE(SUM(${POSDatabase.supplierTotalPurchases}), 0) as total FROM ${POSDatabase.suppliersTable}',
      );
      final totalPurchaseAmount = purchasesResult.first['total'] as double;

      // أفضل مورد
      SupplierModel? topSupplier;
      final topSupplierResult = await getTopSuppliers(limit: 1);
      if (topSupplierResult.isSuccess && topSupplierResult.data!.isNotEmpty) {
        topSupplier = topSupplierResult.data!.first;
      }

      final stats = SupplierStats(
        totalSuppliers: totalSuppliers,
        activeSuppliers: activeSuppliers,
        totalPurchaseAmount: totalPurchaseAmount,
        topSupplier: topSupplier,
      );

      return Result.success(stats);
    } catch (e) {
      return Result.error('خطأ في جلب إحصائيات الموردين: ${e.toString()}');
    }
  }
}
