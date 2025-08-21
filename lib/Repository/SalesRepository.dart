import 'package:pos/Helper/DataBase/POSDatabase.dart';
import 'package:pos/Helper/Result.dart';
import 'package:pos/Model/SaleModel.dart';
import 'package:pos/Repository/ProductRepository.dart';

/// مستودع المبيعات - Sales Repository
/// يحتوي على جميع العمليات المتعلقة بقاعدة البيانات للمبيعات
class SalesRepository {
  /// إنشاء مبيعة جديدة
  Future<Result<int>> createSale(SaleModel sale) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      // التحقق من صحة البيانات
      if (!sale.isValid) {
        return Result.error('بيانات المبيعة غير صحيحة');
      }

      // بدء المعاملة
      return await db.transaction((txn) async {
        // إدراج المبيعة الرئيسية
        final saleId = await txn.insert(POSDatabase.salesTable, sale.toMap());

        // إدراج عناصر المبيعة
        for (final item in sale.items) {
          final itemMap = item.copyWith(saleId: saleId).toMap();
          await txn.insert(POSDatabase.saleItemsTable, itemMap);

          // تحديث كمية المنتج في المخزون
          await txn.rawUpdate(
            '''
            UPDATE ${POSDatabase.itemsTable} 
            SET ${POSDatabase.itemQuantity} = ${POSDatabase.itemQuantity} - ?
            WHERE ${POSDatabase.itemId} = ?
          ''',
            [item.quantity, item.productId],
          );
        }

        // تحديث بيانات العميل إذا كان موجوداً
        if (sale.customerId != null) {
          await txn.rawUpdate(
            '''
            UPDATE ${POSDatabase.customersTable} 
            SET ${POSDatabase.customerTotalPurchases} = ${POSDatabase.customerTotalPurchases} + ?,
                ${POSDatabase.customerPoints} = ${POSDatabase.customerPoints} + ?
            WHERE ${POSDatabase.customerId} = ?
          ''',
            [sale.total, (sale.total / 10).floor(), sale.customerId],
          );
        }

        return Result.success(saleId);
      });
    } catch (e) {
      return Result.error('خطأ في إنشاء المبيعة: ${e.toString()}');
    }
  }

  /// الحصول على مبيعة بالمعرف
  Future<Result<SaleModel?>> getSaleById(int saleId) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      // الحصول على بيانات المبيعة
      final saleResult = await db.query(
        POSDatabase.salesTable,
        where: '${POSDatabase.saleId} = ?',
        whereArgs: [saleId],
      );

      if (saleResult.isEmpty) {
        return Result.success(null);
      }

      // الحصول على عناصر المبيعة
      final itemsResult = await db.query(
        POSDatabase.saleItemsTable,
        where: '${POSDatabase.saleItemSaleId} = ?',
        whereArgs: [saleId],
      );

      final items = itemsResult
          .map((item) => SaleItemModel.fromMap(item))
          .toList();
      final sale = SaleModel.fromMap(saleResult.first, items: items);

      return Result.success(sale);
    } catch (e) {
      return Result.error('خطأ في استرجاع المبيعة: ${e.toString()}');
    }
  }

  /// الحصول على مبيعة برقم الفاتورة
  Future<Result<SaleModel?>> getSaleByInvoiceNumber(
    String invoiceNumber,
  ) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final saleResult = await db.query(
        POSDatabase.salesTable,
        where: '${POSDatabase.saleInvoiceNumber} = ?',
        whereArgs: [invoiceNumber],
      );

      if (saleResult.isEmpty) {
        return Result.success(null);
      }

      final saleId = saleResult.first[POSDatabase.saleId] as int;
      return await getSaleById(saleId);
    } catch (e) {
      return Result.error('خطأ في البحث عن الفاتورة: ${e.toString()}');
    }
  }

  /// الحصول على جميع المبيعات
  Future<Result<List<SaleModel>>> getAllSales({
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      String whereClause = '';
      List<dynamic> whereArgs = [];

      // فلترة حسب التاريخ
      if (startDate != null && endDate != null) {
        whereClause = '${POSDatabase.saleCreatedAt} BETWEEN ? AND ?';
        whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
      }

      final salesResult = await db.query(
        POSDatabase.salesTable,
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: '${POSDatabase.saleCreatedAt} DESC',
        limit: limit,
        offset: offset,
      );

      final sales = <SaleModel>[];
      for (final saleMap in salesResult) {
        final saleId = saleMap[POSDatabase.saleId] as int;

        // الحصول على عناصر المبيعة
        final itemsResult = await db.query(
          POSDatabase.saleItemsTable,
          where: '${POSDatabase.saleItemSaleId} = ?',
          whereArgs: [saleId],
        );

        final items = itemsResult
            .map((item) => SaleItemModel.fromMap(item))
            .toList();
        final sale = SaleModel.fromMap(saleMap, items: items);
        sales.add(sale);
      }

      return Result.success(sales);
    } catch (e) {
      return Result.error('خطأ في استرجاع المبيعات: ${e.toString()}');
    }
  }

  /// الحصول على مبيعات اليوم
  Future<Result<List<SaleModel>>> getTodaySales() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return await getAllSales(startDate: startOfDay, endDate: endOfDay);
  }

  /// الحصول على مبيعات العميل
  Future<Result<List<SaleModel>>> getCustomerSales(int customerId) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final salesResult = await db.query(
        POSDatabase.salesTable,
        where: '${POSDatabase.saleCustomerId} = ?',
        whereArgs: [customerId],
        orderBy: '${POSDatabase.saleCreatedAt} DESC',
      );

      final sales = <SaleModel>[];
      for (final saleMap in salesResult) {
        final saleId = saleMap[POSDatabase.saleId] as int;

        final itemsResult = await db.query(
          POSDatabase.saleItemsTable,
          where: '${POSDatabase.saleItemSaleId} = ?',
          whereArgs: [saleId],
        );

        final items = itemsResult
            .map((item) => SaleItemModel.fromMap(item))
            .toList();
        final sale = SaleModel.fromMap(saleMap, items: items);
        sales.add(sale);
      }

      return Result.success(sales);
    } catch (e) {
      return Result.error('خطأ في استرجاع مبيعات العميل: ${e.toString()}');
    }
  }

  /// حذف مبيعة
  Future<Result<bool>> deleteSale(int saleId) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      return await db.transaction((txn) async {
        // الحصول على عناصر المبيعة لإرجاع الكميات
        final itemsResult = await txn.query(
          POSDatabase.saleItemsTable,
          where: '${POSDatabase.saleItemSaleId} = ?',
          whereArgs: [saleId],
        );

        // إرجاع الكميات للمخزون
        for (final itemMap in itemsResult) {
          final item = SaleItemModel.fromMap(itemMap);
          await txn.rawUpdate(
            '''
            UPDATE ${POSDatabase.itemsTable} 
            SET ${POSDatabase.itemQuantity} = ${POSDatabase.itemQuantity} + ?
            WHERE ${POSDatabase.itemId} = ?
          ''',
            [item.quantity, item.productId],
          );
        }

        // حذف عناصر المبيعة
        await txn.delete(
          POSDatabase.saleItemsTable,
          where: '${POSDatabase.saleItemSaleId} = ?',
          whereArgs: [saleId],
        );

        // حذف المبيعة
        final rowsAffected = await txn.delete(
          POSDatabase.salesTable,
          where: '${POSDatabase.saleId} = ?',
          whereArgs: [saleId],
        );

        if (rowsAffected > 0) {
          return Result.success(true);
        } else {
          return Result.error('لم يتم العثور على المبيعة للحذف');
        }
      });
    } catch (e) {
      return Result.error('خطأ في حذف المبيعة: ${e.toString()}');
    }
  }

  /// الحصول على إحصائيات المبيعات
  Future<Result<SalesStats>> getSalesStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final salesResult = await getAllSales(
        startDate: startDate,
        endDate: endDate,
      );

      if (salesResult.isError) {
        return Result.error(salesResult.error!);
      }

      final stats = SalesStats.fromSales(
        salesResult.data!,
        periodStart: startDate,
        periodEnd: endDate,
      );

      return Result.success(stats);
    } catch (e) {
      return Result.error('خطأ في حساب إحصائيات المبيعات: ${e.toString()}');
    }
  }

  /// البحث في المبيعات
  Future<Result<List<SaleModel>>> searchSales(String query) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final salesResult = await db.query(
        POSDatabase.salesTable,
        where:
            '''
          ${POSDatabase.saleInvoiceNumber} LIKE ? OR 
          ${POSDatabase.saleNotes} LIKE ?
        ''',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: '${POSDatabase.saleCreatedAt} DESC',
      );

      final sales = <SaleModel>[];
      for (final saleMap in salesResult) {
        final saleId = saleMap[POSDatabase.saleId] as int;

        final itemsResult = await db.query(
          POSDatabase.saleItemsTable,
          where: '${POSDatabase.saleItemSaleId} = ?',
          whereArgs: [saleId],
        );

        final items = itemsResult
            .map((item) => SaleItemModel.fromMap(item))
            .toList();
        final sale = SaleModel.fromMap(saleMap, items: items);
        sales.add(sale);
      }

      return Result.success(sales);
    } catch (e) {
      return Result.error('خطأ في البحث في المبيعات: ${e.toString()}');
    }
  }

  /// إنشاء رقم فاتورة جديد
  Future<Result<String>> generateInvoiceNumber() async {
    try {
      final invoiceNumber = await POSDatabase.generateInvoiceNumber();
      return Result.success(invoiceNumber);
    } catch (e) {
      return Result.error('خطأ في إنشاء رقم الفاتورة: ${e.toString()}');
    }
  }

  /// الحصول على أفضل المنتجات مبيعاً
  Future<Result<List<Map<String, dynamic>>>> getTopSellingProducts({
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (startDate != null && endDate != null) {
        whereClause =
            '''
          WHERE s.${POSDatabase.saleCreatedAt} BETWEEN ? AND ?
        ''';
        whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
      }

      final result = await db.rawQuery(
        '''
        SELECT 
          si.${POSDatabase.saleItemProductId} as product_id,
          si.${POSDatabase.saleItemProductName} as product_name,
          si.${POSDatabase.saleItemProductCode} as product_code,
          SUM(si.${POSDatabase.saleItemQuantity}) as total_quantity,
          SUM(si.${POSDatabase.saleItemTotal}) as total_revenue,
          COUNT(DISTINCT si.${POSDatabase.saleItemSaleId}) as sales_count
        FROM ${POSDatabase.saleItemsTable} si
        JOIN ${POSDatabase.salesTable} s ON si.${POSDatabase.saleItemSaleId} = s.${POSDatabase.saleId}
        $whereClause
        GROUP BY si.${POSDatabase.saleItemProductId}
        ORDER BY total_quantity DESC
        LIMIT ?
      ''',
        [...whereArgs, limit],
      );

      return Result.success(result);
    } catch (e) {
      return Result.error(
        'خطأ في استرجاع أفضل المنتجات مبيعاً: ${e.toString()}',
      );
    }
  }
}
