import 'package:pos/Helper/DataBase/POSDatabase.dart';
import 'package:pos/Helper/Result.dart';
import 'package:pos/Model/InvoiceModel.dart';

/// مستودع الفواتير - Invoice Repository
/// يدير جميع العمليات المتعلقة بقاعدة البيانات للفواتير
class InvoiceRepository {
  /// إضافة فاتورة جديدة
  Future<Result<InvoiceModel>> addInvoice(InvoiceModel invoice) async {
    try {
      final db = await POSDatabase.database;

      // بدء المعاملة
      return await db!.transaction((txn) async {
        // إدراج الفاتورة
        final invoiceId = await txn.insert(POSDatabase.invoicesTable, {
          POSDatabase.invoiceCustomerId: invoice.customerId,
          POSDatabase.invoiceNumber: invoice.invoiceNumber,
          POSDatabase.invoiceDate: invoice.date.toIso8601String(),
          POSDatabase.invoiceTotalAmount: invoice.totalAmount,
          POSDatabase.invoiceStatus: invoice.status,
          POSDatabase.invoiceCustomerName: invoice.customerName,
          POSDatabase.invoiceCustomerPhone: invoice.customerPhone,
          POSDatabase.invoiceNotes: invoice.notes,
          POSDatabase.invoiceCreatedAt: invoice.createdAt.toIso8601String(),
          POSDatabase.invoiceUpdatedAt: invoice.updatedAt.toIso8601String(),
        });

        // إدراج عناصر الفاتورة
        for (final item in invoice.items) {
          await txn.insert(POSDatabase.invoiceItemsTable, {
            POSDatabase.invoiceItemInvoiceId: invoiceId,
            POSDatabase.invoiceItemProductId: item.productId,
            POSDatabase.invoiceItemProductName: item.productName,
            POSDatabase.invoiceItemProductCode: item.productCode,
            POSDatabase.invoiceItemQuantity: item.quantity,
            POSDatabase.invoiceItemPrice: item.price,
            POSDatabase.invoiceItemTotal: item.total,
          });
        }

        // إرجاع الفاتورة مع المعرف الجديد
        final newInvoice = invoice.copyWith(id: invoiceId);
        return Result.success(newInvoice);
      });
    } catch (e) {
      return Result.error('خطأ في إضافة الفاتورة: ${e.toString()}');
    }
  }

  /// تحديث فاتورة موجودة
  Future<Result<InvoiceModel>> updateInvoice(InvoiceModel invoice) async {
    try {
      if (invoice.id == null) {
        return Result.error('معرف الفاتورة مطلوب للتحديث');
      }

      final db = await POSDatabase.database;

      return await db!.transaction((txn) async {
        // تحديث الفاتورة
        final updatedRows = await txn.update(
          POSDatabase.invoicesTable,
          {
            POSDatabase.invoiceCustomerId: invoice.customerId,
            POSDatabase.invoiceNumber: invoice.invoiceNumber,
            POSDatabase.invoiceDate: invoice.date.toIso8601String(),
            POSDatabase.invoiceTotalAmount: invoice.totalAmount,
            POSDatabase.invoiceStatus: invoice.status,
            POSDatabase.invoiceCustomerName: invoice.customerName,
            POSDatabase.invoiceCustomerPhone: invoice.customerPhone,
            POSDatabase.invoiceNotes: invoice.notes,
            POSDatabase.invoiceUpdatedAt: DateTime.now().toIso8601String(),
          },
          where: '${POSDatabase.invoiceId} = ?',
          whereArgs: [invoice.id],
        );

        if (updatedRows == 0) {
          return Result.error('الفاتورة غير موجودة');
        }

        // حذف العناصر القديمة
        await txn.delete(
          POSDatabase.invoiceItemsTable,
          where: '${POSDatabase.invoiceItemInvoiceId} = ?',
          whereArgs: [invoice.id],
        );

        // إدراج العناصر الجديدة
        for (final item in invoice.items) {
          await txn.insert(POSDatabase.invoiceItemsTable, {
            POSDatabase.invoiceItemInvoiceId: invoice.id,
            POSDatabase.invoiceItemProductId: item.productId,
            POSDatabase.invoiceItemProductName: item.productName,
            POSDatabase.invoiceItemProductCode: item.productCode,
            POSDatabase.invoiceItemQuantity: item.quantity,
            POSDatabase.invoiceItemPrice: item.price,
            POSDatabase.invoiceItemTotal: item.total,
          });
        }

        final updatedInvoice = invoice.copyWith(updatedAt: DateTime.now());
        return Result.success(updatedInvoice);
      });
    } catch (e) {
      return Result.error('خطأ في تحديث الفاتورة: ${e.toString()}');
    }
  }

  /// حذف فاتورة
  Future<Result<bool>> deleteInvoice(int invoiceId) async {
    try {
      final db = await POSDatabase.database;

      return await db!.transaction((txn) async {
        // حذف عناصر الفاتورة أولاً
        await txn.delete(
          POSDatabase.invoiceItemsTable,
          where: '${POSDatabase.invoiceItemInvoiceId} = ?',
          whereArgs: [invoiceId],
        );

        // حذف الفاتورة
        final deletedRows = await txn.delete(
          POSDatabase.invoicesTable,
          where: '${POSDatabase.invoiceId} = ?',
          whereArgs: [invoiceId],
        );

        if (deletedRows == 0) {
          return Result.error('الفاتورة غير موجودة');
        }

        return Result.success(true);
      });
    } catch (e) {
      return Result.error('خطأ في حذف الفاتورة: ${e.toString()}');
    }
  }

  /// جلب جميع الفواتير
  Future<Result<List<InvoiceModel>>> getAllInvoices({
    int? limit,
    int? offset,
    String? orderBy,
  }) async {
    try {
      final db = await POSDatabase.database;

      String query =
          '''
        SELECT * FROM ${POSDatabase.invoicesTable}
        ORDER BY ${orderBy ?? '${POSDatabase.invoiceCreatedAt} DESC'}
      ''';

      if (limit != null) {
        query += ' LIMIT $limit';
        if (offset != null) {
          query += ' OFFSET $offset';
        }
      }

      final invoiceRows = await db!.rawQuery(query);
      final invoices = <InvoiceModel>[];

      for (final row in invoiceRows) {
        // جلب عناصر الفاتورة
        final itemRows = await db.query(
          POSDatabase.invoiceItemsTable,
          where: '${POSDatabase.invoiceItemInvoiceId} = ?',
          whereArgs: [row[POSDatabase.invoiceId]],
        );

        final items = itemRows
            .map((itemRow) => InvoiceItemModel.fromMap(itemRow))
            .toList();

        final invoice = InvoiceModel.fromMap(row).copyWith(items: items);
        invoices.add(invoice);
      }

      return Result.success(invoices);
    } catch (e) {
      return Result.error('خطأ في جلب الفواتير: ${e.toString()}');
    }
  }

  /// البحث في الفواتير
  Future<Result<List<InvoiceModel>>> searchInvoices(String query) async {
    try {
      final db = await POSDatabase.database;

      final invoiceRows = await db!.rawQuery(
        '''
        SELECT * FROM ${POSDatabase.invoicesTable}
        WHERE ${POSDatabase.invoiceNumber} LIKE ? 
           OR ${POSDatabase.invoiceCustomerName} LIKE ? 
           OR ${POSDatabase.invoiceCustomerPhone} LIKE ?
           OR ${POSDatabase.invoiceNotes} LIKE ?
        ORDER BY ${POSDatabase.invoiceCreatedAt} DESC
      ''',
        ['%$query%', '%$query%', '%$query%', '%$query%'],
      );

      final invoices = <InvoiceModel>[];

      for (final row in invoiceRows) {
        // جلب عناصر الفاتورة
        final itemRows = await db.query(
          POSDatabase.invoiceItemsTable,
          where: '${POSDatabase.invoiceItemInvoiceId} = ?',
          whereArgs: [row[POSDatabase.invoiceId]],
        );

        final items = itemRows
            .map((itemRow) => InvoiceItemModel.fromMap(itemRow))
            .toList();

        final invoice = InvoiceModel.fromMap(row).copyWith(items: items);
        invoices.add(invoice);
      }

      return Result.success(invoices);
    } catch (e) {
      return Result.error('خطأ في البحث عن الفواتير: ${e.toString()}');
    }
  }

  /// تصفية الفواتير حسب الحالة
  Future<Result<List<InvoiceModel>>> getInvoicesByStatus(String status) async {
    try {
      final db = await POSDatabase.database;

      final invoiceRows = await db!.query(
        POSDatabase.invoicesTable,
        where: '${POSDatabase.invoiceStatus} = ?',
        whereArgs: [status],
        orderBy: '${POSDatabase.invoiceCreatedAt} DESC',
      );

      final invoices = <InvoiceModel>[];

      for (final row in invoiceRows) {
        // جلب عناصر الفاتورة
        final itemRows = await db.query(
          POSDatabase.invoiceItemsTable,
          where: '${POSDatabase.invoiceItemInvoiceId} = ?',
          whereArgs: [row[POSDatabase.invoiceId]],
        );

        final items = itemRows
            .map((itemRow) => InvoiceItemModel.fromMap(itemRow))
            .toList();

        final invoice = InvoiceModel.fromMap(row).copyWith(items: items);
        invoices.add(invoice);
      }

      return Result.success(invoices);
    } catch (e) {
      return Result.error('خطأ في تصفية الفواتير: ${e.toString()}');
    }
  }

  /// تصفية الفواتير حسب نطاق التاريخ
  Future<Result<List<InvoiceModel>>> getInvoicesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await POSDatabase.database;

      final invoiceRows = await db!.query(
        POSDatabase.invoicesTable,
        where: '${POSDatabase.invoiceDate} BETWEEN ? AND ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: '${POSDatabase.invoiceDate} DESC',
      );

      final invoices = <InvoiceModel>[];

      for (final row in invoiceRows) {
        // جلب عناصر الفاتورة
        final itemRows = await db.query(
          POSDatabase.invoiceItemsTable,
          where: '${POSDatabase.invoiceItemInvoiceId} = ?',
          whereArgs: [row[POSDatabase.invoiceId]],
        );

        final items = itemRows
            .map((itemRow) => InvoiceItemModel.fromMap(itemRow))
            .toList();

        final invoice = InvoiceModel.fromMap(row).copyWith(items: items);
        invoices.add(invoice);
      }

      return Result.success(invoices);
    } catch (e) {
      return Result.error('خطأ في تصفية الفواتير حسب التاريخ: ${e.toString()}');
    }
  }

  /// تحديث حالة الفاتورة
  Future<Result<bool>> updateInvoiceStatus(int invoiceId, String status) async {
    try {
      final db = await POSDatabase.database;

      final updatedRows = await db!.update(
        POSDatabase.invoicesTable,
        {
          POSDatabase.invoiceStatus: status,
          POSDatabase.invoiceUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '${POSDatabase.invoiceId} = ?',
        whereArgs: [invoiceId],
      );

      if (updatedRows == 0) {
        return Result.error('الفاتورة غير موجودة');
      }

      return Result.success(true);
    } catch (e) {
      return Result.error('خطأ في تحديث حالة الفاتورة: ${e.toString()}');
    }
  }

  /// إنشاء رقم فاتورة جديد
  Future<Result<String>> generateInvoiceNumber() async {
    try {
      final db = await POSDatabase.database;

      // الحصول على آخر رقم فاتورة
      final result = await db!.rawQuery('''
        SELECT ${POSDatabase.invoiceNumber} FROM ${POSDatabase.invoicesTable} 
        WHERE ${POSDatabase.invoiceNumber} LIKE 'INV-%' 
        ORDER BY ${POSDatabase.invoiceId} DESC 
        LIMIT 1
      ''');

      int nextNumber = 1;

      if (result.isNotEmpty) {
        final lastInvoiceNumber =
            result.first[POSDatabase.invoiceNumber] as String;
        final numberPart = lastInvoiceNumber.split('-').last;
        final lastNumber = int.tryParse(numberPart) ?? 0;
        nextNumber = lastNumber + 1;
      }

      final invoiceNumber = 'INV-${nextNumber.toString().padLeft(6, '0')}';
      return Result.success(invoiceNumber);
    } catch (e) {
      return Result.error('خطأ في إنشاء رقم الفاتورة: ${e.toString()}');
    }
  }

  /// الحصول على إحصائيات الفواتير
  Future<Result<Map<String, dynamic>>> getInvoiceStats() async {
    try {
      final db = await POSDatabase.database;

      // إحصائيات اليوم
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final todayStats = await db!.rawQuery(
        '''
        SELECT COUNT(*) as count, COALESCE(SUM(${POSDatabase.invoiceTotalAmount}), 0) as total_amount
        FROM ${POSDatabase.invoicesTable}
        WHERE ${POSDatabase.invoiceDate} >= ? AND ${POSDatabase.invoiceDate} < ?
      ''',
        [todayStart.toIso8601String(), todayEnd.toIso8601String()],
      );

      // إحصائيات الشهر
      final monthStart = DateTime(today.year, today.month, 1);
      final monthEnd = DateTime(today.year, today.month + 1, 1);

      final monthStats = await db.rawQuery(
        '''
        SELECT COUNT(*) as count, COALESCE(SUM(${POSDatabase.invoiceTotalAmount}), 0) as total_amount
        FROM ${POSDatabase.invoicesTable}
        WHERE ${POSDatabase.invoiceDate} >= ? AND ${POSDatabase.invoiceDate} < ?
      ''',
        [monthStart.toIso8601String(), monthEnd.toIso8601String()],
      );

      // إحصائيات الحالات
      final statusStats = await db.rawQuery('''
        SELECT ${POSDatabase.invoiceStatus}, COUNT(*) as count, COALESCE(SUM(${POSDatabase.invoiceTotalAmount}), 0) as total_amount
        FROM ${POSDatabase.invoicesTable}
        GROUP BY ${POSDatabase.invoiceStatus}
      ''');

      final statusMap = <String, Map<String, dynamic>>{};
      for (final row in statusStats) {
        statusMap[row[POSDatabase.invoiceStatus] as String] = {
          'count': row['count'],
          'total_amount': row['total_amount'],
        };
      }

      final stats = {
        'today': {
          'count': todayStats.first['count'],
          'total_amount': todayStats.first['total_amount'],
        },
        'month': {
          'count': monthStats.first['count'],
          'total_amount': monthStats.first['total_amount'],
        },
        'status': statusMap,
      };

      return Result.success(stats);
    } catch (e) {
      return Result.error('خطأ في جلب إحصائيات الفواتير: ${e.toString()}');
    }
  }

  /// جلب فاتورة واحدة بالمعرف
  Future<Result<InvoiceModel?>> getInvoiceById(int invoiceId) async {
    try {
      final db = await POSDatabase.database;

      final invoiceRows = await db!.query(
        POSDatabase.invoicesTable,
        where: '${POSDatabase.invoiceId} = ?',
        whereArgs: [invoiceId],
      );

      if (invoiceRows.isEmpty) {
        return Result.success(null);
      }

      // جلب عناصر الفاتورة
      final itemRows = await db.query(
        POSDatabase.invoiceItemsTable,
        where: '${POSDatabase.invoiceItemInvoiceId} = ?',
        whereArgs: [invoiceId],
      );

      final items = itemRows
          .map((itemRow) => InvoiceItemModel.fromMap(itemRow))
          .toList();

      final invoice = InvoiceModel.fromMap(
        invoiceRows.first,
      ).copyWith(items: items);
      return Result.success(invoice);
    } catch (e) {
      return Result.error('خطأ في جلب الفاتورة: ${e.toString()}');
    }
  }

  /// التحقق من وجود رقم فاتورة
  Future<Result<bool>> isInvoiceNumberExists(
    String invoiceNumber, {
    int? excludeId,
  }) async {
    try {
      final db = await POSDatabase.database;

      String whereClause = '${POSDatabase.invoiceNumber} = ?';
      List<dynamic> whereArgs = [invoiceNumber];

      if (excludeId != null) {
        whereClause += ' AND ${POSDatabase.invoiceId} != ?';
        whereArgs.add(excludeId);
      }

      final result = await db!.query(
        POSDatabase.invoicesTable,
        where: whereClause,
        whereArgs: whereArgs,
      );

      return Result.success(result.isNotEmpty);
    } catch (e) {
      return Result.error('خطأ في التحقق من رقم الفاتورة: ${e.toString()}');
    }
  }
}
