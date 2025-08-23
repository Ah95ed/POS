import 'package:pos/Helper/DataBase/POSDatabase.dart';
import 'package:pos/Helper/Result.dart';
import 'package:pos/Model/SaleModel.dart';
import 'package:sqflite/sqflite.dart';

/// مستودع العملاء - Customer Repository
/// يدير جميع العمليات المتعلقة بقاعدة بيانات العملاء
class CustomerRepository {
  static const String _tableName = 'Customers';

  /// الحصول على قاعدة البيانات
  Future<Database?> get _database async {
    return await POSDatabase.database;
  }

  /// إضافة عميل جديد
  Future<Result<CustomerModel>> addCustomer(CustomerModel customer) async {
    try {
      final db = await _database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      // التحقق من صحة البيانات
      if (!customer.isValid) {
        return Result.error('بيانات العميل غير صحيحة');
      }

      // التحقق من عدم تكرار رقم الهاتف
      if (customer.phone != null && customer.phone!.isNotEmpty) {
        final existingCustomer = await getCustomerByPhone(customer.phone!);
        if (existingCustomer.isSuccess && existingCustomer.data != null) {
          return Result.error('رقم الهاتف مستخدم من قبل عميل آخر');
        }
      }

      // التحقق من عدم تكرار البريد الإلكتروني
      if (customer.email != null && customer.email!.isNotEmpty) {
        final existingCustomer = await getCustomerByEmail(customer.email!);
        if (existingCustomer.isSuccess && existingCustomer.data != null) {
          return Result.error('البريد الإلكتروني مستخدم من قبل عميل آخر');
        }
      }

      final customerData = customer.toMap();
      customerData.remove('id'); // إزالة المعرف للإدراج التلقائي

      final id = await db.insert(_tableName, customerData);

      final newCustomer = customer.copyWith(id: id);
      return Result.success(newCustomer);
    } catch (e) {
      return Result.error('خطأ في إضافة العميل: ${e.toString()}');
    }
  }

  /// تحديث عميل موجود
  Future<Result<CustomerModel>> updateCustomer(CustomerModel customer) async {
    try {
      final db = await _database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      if (customer.id == null) {
        return Result.error('معرف العميل مطلوب للتحديث');
      }

      // التحقق من صحة البيانات
      if (!customer.isValid) {
        return Result.error('بيانات العميل غير صحيحة');
      }

      // التحقق من وجود العميل
      final existingResult = await getCustomerById(customer.id!);
      if (!existingResult.isSuccess || existingResult.data == null) {
        return Result.error('العميل غير موجود');
      }

      // التحقق من عدم تكرار رقم الهاتف مع عملاء آخرين
      if (customer.phone != null && customer.phone!.isNotEmpty) {
        final phoneResult = await getCustomerByPhone(customer.phone!);
        if (phoneResult.isSuccess &&
            phoneResult.data != null &&
            phoneResult.data!.id != customer.id) {
          return Result.error('رقم الهاتف مستخدم من قبل عميل آخر');
        }
      }

      // التحقق من عدم تكرار البريد الإلكتروني مع عملاء آخرين
      if (customer.email != null && customer.email!.isNotEmpty) {
        final emailResult = await getCustomerByEmail(customer.email!);
        if (emailResult.isSuccess &&
            emailResult.data != null &&
            emailResult.data!.id != customer.id) {
          return Result.error('البريد الإلكتروني مستخدم من قبل عميل آخر');
        }
      }

      final customerData = customer.toMap();

      final rowsAffected = await db.update(
        _tableName,
        customerData,
        where: 'id = ?',
        whereArgs: [customer.id],
      );

      if (rowsAffected > 0) {
        return Result.success(customer);
      } else {
        return Result.error('فشل في تحديث العميل');
      }
    } catch (e) {
      return Result.error('خطأ في تحديث العميل: ${e.toString()}');
    }
  }

  /// حذف عميل
  Future<Result<bool>> deleteCustomer(int customerId) async {
    try {
      final db = await _database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      // التحقق من وجود العميل
      final existingResult = await getCustomerById(customerId);
      if (!existingResult.isSuccess || existingResult.data == null) {
        return Result.error('العميل غير موجود');
      }

      // TODO: التحقق من وجود مبيعات مرتبطة بالعميل
      // يمكن إضافة منطق لمنع حذف العملاء الذين لديهم مبيعات

      final rowsAffected = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [customerId],
      );

      if (rowsAffected > 0) {
        return Result.success(true);
      } else {
        return Result.error('فشل في حذف العميل');
      }
    } catch (e) {
      return Result.error('خطأ في حذف العميل: ${e.toString()}');
    }
  }

  /// الحصول على عميل بالمعرف
  Future<Result<CustomerModel?>> getCustomerById(int customerId) async {
    try {
      final db = await _database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final result = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [customerId],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final customer = CustomerModel.fromMap(result.first);
        return Result.success(customer);
      } else {
        return Result.success(null);
      }
    } catch (e) {
      return Result.error('خطأ في البحث عن العميل: ${e.toString()}');
    }
  }

  /// الحصول على عميل برقم الهاتف
  Future<Result<CustomerModel?>> getCustomerByPhone(String phone) async {
    try {
      final db = await _database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final result = await db.query(
        _tableName,
        where: 'phone = ?',
        whereArgs: [phone],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final customer = CustomerModel.fromMap(result.first);
        return Result.success(customer);
      } else {
        return Result.success(null);
      }
    } catch (e) {
      return Result.error('خطأ في البحث عن العميل: ${e.toString()}');
    }
  }

  /// الحصول على عميل بالبريد الإلكتروني
  Future<Result<CustomerModel?>> getCustomerByEmail(String email) async {
    try {
      final db = await _database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final result = await db.query(
        _tableName,
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final customer = CustomerModel.fromMap(result.first);
        return Result.success(customer);
      } else {
        return Result.success(null);
      }
    } catch (e) {
      return Result.error('خطأ في البحث عن العميل: ${e.toString()}');
    }
  }

  /// الحصول على جميع العملاء
  Future<Result<List<CustomerModel>>> getAllCustomers({
    int? limit,
    int? offset,
    String? orderBy,
  }) async {
    try {
      final db = await _database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final result = await db.query(
        _tableName,
        orderBy: orderBy ?? 'created_at DESC',
        limit: limit,
        offset: offset,
      );

      final customers = result
          .map((map) => CustomerModel.fromMap(map))
          .toList();
      return Result.success(customers);
    } catch (e) {
      return Result.error('خطأ في جلب العملاء: ${e.toString()}');
    }
  }

  /// البحث في العملاء
  Future<Result<List<CustomerModel>>> searchCustomers(
    String query, {
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await _database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final result = await db.query(
        _tableName,
        where: 'name LIKE ? OR phone LIKE ? OR email LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'name ASC',
        limit: limit,
        offset: offset,
      );

      final customers = result
          .map((map) => CustomerModel.fromMap(map))
          .toList();
      return Result.success(customers);
    } catch (e) {
      return Result.error('خطأ في البحث عن العملاء: ${e.toString()}');
    }
  }

  /// الحصول على العملاء المميزين
  Future<Result<List<CustomerModel>>> getVipCustomers({
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await _database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final result = await db.query(
        _tableName,
        where: 'is_vip = ?',
        whereArgs: [1],
        orderBy: 'total_purchases DESC',
        limit: limit,
        offset: offset,
      );

      final customers = result
          .map((map) => CustomerModel.fromMap(map))
          .toList();
      return Result.success(customers);
    } catch (e) {
      return Result.error('خطأ في جلب العملاء المميزين: ${e.toString()}');
    }
  }

  /// الحصول على أفضل العملاء حسب المشتريات
  Future<Result<List<CustomerModel>>> getTopCustomers({
    int limit = 10,
    int? offset,
  }) async {
    try {
      final db = await _database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final result = await db.query(
        _tableName,
        orderBy: 'total_purchases DESC',
        limit: limit,
        offset: offset,
      );

      final customers = result
          .map((map) => CustomerModel.fromMap(map))
          .toList();
      return Result.success(customers);
    } catch (e) {
      return Result.error('خطأ في جلب أفضل العملاء: ${e.toString()}');
    }
  }

  /// تحديث حالة العميل المميز
  Future<Result<bool>> updateCustomerVipStatus(
    int customerId,
    bool isVip,
  ) async {
    try {
      final db = await _database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final rowsAffected = await db.update(
        _tableName,
        {'is_vip': isVip ? 1 : 0},
        where: 'id = ?',
        whereArgs: [customerId],
      );

      if (rowsAffected > 0) {
        return Result.success(true);
      } else {
        return Result.error('فشل في تحديث حالة العميل المميز');
      }
    } catch (e) {
      return Result.error('خطأ في تحديث حالة العميل المميز: ${e.toString()}');
    }
  }

  /// تحديث نقاط العميل
  Future<Result<bool>> updateCustomerPoints(int customerId, int points) async {
    try {
      final db = await _database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final rowsAffected = await db.update(
        _tableName,
        {'points': points},
        where: 'id = ?',
        whereArgs: [customerId],
      );

      if (rowsAffected > 0) {
        return Result.success(true);
      } else {
        return Result.error('فشل في تحديث نقاط العميل');
      }
    } catch (e) {
      return Result.error('خطأ في تحديث نقاط العميل: ${e.toString()}');
    }
  }

  /// تحديث إجمالي مشتريات العميل
  Future<Result<bool>> updateCustomerTotalPurchases(
    int customerId,
    double totalPurchases,
  ) async {
    try {
      final db = await _database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final rowsAffected = await db.update(
        _tableName,
        {'total_purchases': totalPurchases},
        where: 'id = ?',
        whereArgs: [customerId],
      );

      if (rowsAffected > 0) {
        return Result.success(true);
      } else {
        return Result.error('فشل في تحديث إجمالي مشتريات العميل');
      }
    } catch (e) {
      return Result.error(
        'خطأ في تحديث إجمالي مشتريات العميل: ${e.toString()}',
      );
    }
  }

  /// إضافة نقاط للعميل
  Future<Result<bool>> addPointsToCustomer(
    int customerId,
    int pointsToAdd,
  ) async {
    try {
      final db = await _database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      // الحصول على النقاط الحالية
      final customerResult = await getCustomerById(customerId);
      if (!customerResult.isSuccess || customerResult.data == null) {
        return Result.error('العميل غير موجود');
      }

      final currentPoints = customerResult.data!.points;
      final newPoints = currentPoints + pointsToAdd;

      final rowsAffected = await db.update(
        _tableName,
        {'points': newPoints},
        where: 'id = ?',
        whereArgs: [customerId],
      );

      if (rowsAffected > 0) {
        return Result.success(true);
      } else {
        return Result.error('فشل في إضافة النقاط');
      }
    } catch (e) {
      return Result.error('خطأ في إضافة النقاط: ${e.toString()}');
    }
  }

  /// الحصول على إحصائيات العملاء
  Future<Result<Map<String, dynamic>>> getCustomersStats() async {
    try {
      final db = await _database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      // إجمالي العملاء
      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      final totalCustomers = totalResult.first['count'] as int;

      // العملاء المميزون
      final vipResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE is_vip = 1',
      );
      final vipCustomers = vipResult.first['count'] as int;

      // إجمالي الإيرادات من العملاء
      final revenueResult = await db.rawQuery(
        'SELECT SUM(total_purchases) as total FROM $_tableName',
      );
      final totalRevenue = (revenueResult.first['total'] as double?) ?? 0.0;

      // متوسط المشتريات
      final avgResult = await db.rawQuery(
        'SELECT AVG(total_purchases) as avg FROM $_tableName WHERE total_purchases > 0',
      );
      final avgPurchases = (avgResult.first['avg'] as double?) ?? 0.0;

      // إجمالي النقاط
      final pointsResult = await db.rawQuery(
        'SELECT SUM(points) as total FROM $_tableName',
      );
      final totalPoints = (pointsResult.first['total'] as int?) ?? 0;

      final stats = {
        'total_customers': totalCustomers,
        'vip_customers': vipCustomers,
        'total_revenue': totalRevenue,
        'avg_purchases': avgPurchases,
        'total_points': totalPoints,
      };

      return Result.success(stats);
    } catch (e) {
      return Result.error('خطأ في جلب إحصائيات العملاء: ${e.toString()}');
    }
  }

  /// عدد العملاء
  Future<Result<int>> getCustomersCount() async {
    try {
      final db = await _database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      final count = result.first['count'] as int;

      return Result.success(count);
    } catch (e) {
      return Result.error('خطأ في عد العملاء: ${e.toString()}');
    }
  }

  /// حذف جميع العملاء (للاختبار فقط)
  Future<Result<bool>> deleteAllCustomers() async {
    try {
      final db = await _database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      await db.delete(_tableName);
      return Result.success(true);
    } catch (e) {
      return Result.error('خطأ في حذف جميع العملاء: ${e.toString()}');
    }
  }
}
