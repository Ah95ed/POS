import 'package:pos/Helper/DataBase/POSDatabase.dart';
import 'package:pos/Model/SaleModel.dart';
import 'package:pos/Helper/Result.dart';

/// مستودع العملاء - Customer Repository
/// يحتوي على جميع العمليات المتعلقة بقاعدة البيانات للعملاء
class CustomerRepository {
  /// إضافة عميل جديد
  Future<Result<int>> addCustomer(CustomerModel customer) async {
    try {
      final db = await POSDatabase.database;
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
          return Result.error('رقم الهاتف موجود مسبقاً');
        }
      }

      final id = await db.insert(POSDatabase.customersTable, customer.toMap());
      return Result.success(id);
    } catch (e) {
      return Result.error('خطأ في إضافة العميل: ${e.toString()}');
    }
  }

  /// تحديث عميل موجود
  Future<Result<bool>> updateCustomer(CustomerModel customer) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      if (customer.id == null) {
        return Result.error('معرف العميل مطلوب للتحديث');
      }

      if (!customer.isValid) {
        return Result.error('بيانات العميل غير صحيحة');
      }

      final rowsAffected = await db.update(
        POSDatabase.customersTable,
        customer.toMap(),
        where: '${POSDatabase.customerId} = ?',
        whereArgs: [customer.id],
      );

      if (rowsAffected > 0) {
        return Result.success(true);
      } else {
        return Result.error('لم يتم العثور على العميل للتحديث');
      }
    } catch (e) {
      return Result.error('خطأ في تحديث العميل: ${e.toString()}');
    }
  }

  /// حذف عميل
  Future<Result<bool>> deleteCustomer(int customerId) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      // التحقق من وجود مبيعات للعميل
      final salesCount = await db.rawQuery(
        '''
        SELECT COUNT(*) as count 
        FROM ${POSDatabase.salesTable} 
        WHERE ${POSDatabase.saleCustomerId} = ?
      ''',
        [customerId],
      );

      final count = salesCount.first['count'] as int;
      if (count > 0) {
        return Result.error('لا يمكن حذف العميل لوجود مبيعات مرتبطة به');
      }

      final rowsAffected = await db.delete(
        POSDatabase.customersTable,
        where: '${POSDatabase.customerId} = ?',
        whereArgs: [customerId],
      );

      if (rowsAffected > 0) {
        return Result.success(true);
      } else {
        return Result.error('لم يتم العثور على العميل للحذف');
      }
    } catch (e) {
      return Result.error('خطأ في حذف العميل: ${e.toString()}');
    }
  }

  /// الحصول على جميع العملاء
  Future<Result<List<CustomerModel>>> getAllCustomers() async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final data = await db.query(
        POSDatabase.customersTable,
        orderBy: '${POSDatabase.customerName} ASC',
      );

      final customers = data
          .map((item) => CustomerModel.fromMap(item))
          .toList();
      return Result.success(customers);
    } catch (e) {
      return Result.error('خطأ في استرجاع العملاء: ${e.toString()}');
    }
  }

  /// الحصول على عميل بالمعرف
  Future<Result<CustomerModel?>> getCustomerById(int customerId) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final data = await db.query(
        POSDatabase.customersTable,
        where: '${POSDatabase.customerId} = ?',
        whereArgs: [customerId],
      );

      if (data.isNotEmpty) {
        final customer = CustomerModel.fromMap(data.first);
        return Result.success(customer);
      } else {
        return Result.success(null);
      }
    } catch (e) {
      return Result.error('خطأ في البحث عن العميل: ${e.toString()}');
    }
  }

  /// البحث عن عميل برقم الهاتف
  Future<Result<CustomerModel?>> getCustomerByPhone(String phone) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      if (phone.trim().isEmpty) {
        return Result.error('رقم الهاتف مطلوب');
      }

      final data = await db.query(
        POSDatabase.customersTable,
        where: '${POSDatabase.customerPhone} = ?',
        whereArgs: [phone.trim()],
      );

      if (data.isNotEmpty) {
        final customer = CustomerModel.fromMap(data.first);
        return Result.success(customer);
      } else {
        return Result.success(null);
      }
    } catch (e) {
      return Result.error('خطأ في البحث عن العميل: ${e.toString()}');
    }
  }

  /// البحث في العملاء بالاسم
  Future<Result<List<CustomerModel>>> searchCustomersByName(String name) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      if (name.trim().isEmpty) {
        return getAllCustomers();
      }

      final data = await db.query(
        POSDatabase.customersTable,
        where: '${POSDatabase.customerName} LIKE ?',
        whereArgs: ['%${name.trim()}%'],
        orderBy: '${POSDatabase.customerName} ASC',
      );

      final customers = data
          .map((item) => CustomerModel.fromMap(item))
          .toList();
      return Result.success(customers);
    } catch (e) {
      return Result.error('خطأ في البحث عن العملاء: ${e.toString()}');
    }
  }

  /// الحصول على العملاء المميزين
  Future<Result<List<CustomerModel>>> getVipCustomers() async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final data = await db.query(
        POSDatabase.customersTable,
        where: '${POSDatabase.customerIsVip} = ?',
        whereArgs: [1],
        orderBy: '${POSDatabase.customerTotalPurchases} DESC',
      );

      final customers = data
          .map((item) => CustomerModel.fromMap(item))
          .toList();
      return Result.success(customers);
    } catch (e) {
      return Result.error('خطأ في استرجاع العملاء المميزين: ${e.toString()}');
    }
  }

  /// الحصول على أفضل العملاء (حسب المشتريات)
  Future<Result<List<CustomerModel>>> getTopCustomers({int limit = 10}) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final data = await db.query(
        POSDatabase.customersTable,
        orderBy: '${POSDatabase.customerTotalPurchases} DESC',
        limit: limit,
      );

      final customers = data
          .map((item) => CustomerModel.fromMap(item))
          .toList();
      return Result.success(customers);
    } catch (e) {
      return Result.error('خطأ في استرجاع أفضل العملاء: ${e.toString()}');
    }
  }

  /// تحديث نقاط العميل
  Future<Result<bool>> updateCustomerPoints(int customerId, int points) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final rowsAffected = await db.update(
        POSDatabase.customersTable,
        {POSDatabase.customerPoints: points},
        where: '${POSDatabase.customerId} = ?',
        whereArgs: [customerId],
      );

      if (rowsAffected > 0) {
        return Result.success(true);
      } else {
        return Result.error('لم يتم العثور على العميل');
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
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final rowsAffected = await db.update(
        POSDatabase.customersTable,
        {POSDatabase.customerTotalPurchases: totalPurchases},
        where: '${POSDatabase.customerId} = ?',
        whereArgs: [customerId],
      );

      if (rowsAffected > 0) {
        return Result.success(true);
      } else {
        return Result.error('لم يتم العثور على العميل');
      }
    } catch (e) {
      return Result.error(
        'خطأ في تحديث إجمالي مشتريات العميل: ${e.toString()}',
      );
    }
  }

  /// تحديث حالة العميل المميز
  Future<Result<bool>> updateCustomerVipStatus(
    int customerId,
    bool isVip,
  ) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final rowsAffected = await db.update(
        POSDatabase.customersTable,
        {POSDatabase.customerIsVip: isVip ? 1 : 0},
        where: '${POSDatabase.customerId} = ?',
        whereArgs: [customerId],
      );

      if (rowsAffected > 0) {
        return Result.success(true);
      } else {
        return Result.error('لم يتم العثور على العميل');
      }
    } catch (e) {
      return Result.error('خطأ في تحديث حالة العميل المميز: ${e.toString()}');
    }
  }

  /// الحصول على إحصائيات العملاء
  Future<Result<Map<String, dynamic>>> getCustomersStats() async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_customers,
          COUNT(CASE WHEN ${POSDatabase.customerIsVip} = 1 THEN 1 END) as vip_customers,
          AVG(${POSDatabase.customerTotalPurchases}) as avg_purchases,
          SUM(${POSDatabase.customerTotalPurchases}) as total_revenue,
          SUM(${POSDatabase.customerPoints}) as total_points
        FROM ${POSDatabase.customersTable}
      ''');

      if (result.isNotEmpty) {
        return Result.success(result.first);
      } else {
        return Result.success({
          'total_customers': 0,
          'vip_customers': 0,
          'avg_purchases': 0.0,
          'total_revenue': 0.0,
          'total_points': 0,
        });
      }
    } catch (e) {
      return Result.error('خطأ في حساب إحصائيات العملاء: ${e.toString()}');
    }
  }
}
