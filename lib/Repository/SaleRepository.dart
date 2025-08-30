import 'package:pos/Helper/DataBase/DataBaseSqflite.dart';
import 'package:pos/Helper/DataBase/POSDatabase.dart';
import 'package:pos/Model/SaleModel.dart';
import 'package:pos/Helper/Result.dart';

/// مستودع المبيعات - Sale Repository
/// يحتوي على جميع العمليات المتعلقة بقاعدة البيانات للمبيعات
class SaleRepository {
  SaleRepository();

  /// إنشاء جداول المبيعات
  Future<void> createSalesTables() async {
    final db = await DataBaseSqflite.databasesq;

    // جدول المبيعات الرئيسي
    await db!.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT UNIQUE NOT NULL,
        date TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL DEFAULT 0.0,
        tax REAL DEFAULT 0.0,
        total REAL NOT NULL,
        payment_method TEXT NOT NULL,
        paid_amount REAL NOT NULL,
        change_amount REAL DEFAULT 0.0,
        customer_name TEXT,
        customer_phone TEXT,
        notes TEXT,
        status TEXT DEFAULT 'completed',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // جدول عناصر المبيعات
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_code TEXT NOT NULL,
        product_name TEXT NOT NULL,
        unit_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        discount REAL DEFAULT 0.0,
        total REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');
  }

  /// حفظ فاتورة جديدة
  Future<Result<int>> saveSale(SaleModel sale) async {
    try {
      final db = await POSDatabase.database;

      // التحقق من صحة البيانات
      if (!sale.isValid) {
        return Result.error('بيانات الفاتورة غير صحيحة');
      }

      // التحقق من عدم تكرار رقم الفاتورة
      final existingSale = await getSaleByInvoiceNumber(sale.invoiceNumber);
      if (existingSale.isSuccess && existingSale.data != null) {
        return Result.error('رقم الفاتورة موجود مسبقاً');
      }

      // التحقق المسبق من توفر الكميات في قاعدة بيانات المخزون (بدون تعديل)
      final inventoryDb = await DataBaseSqflite.databasesq;
      if (inventoryDb == null) {
        return Result.error('تعذر الاتصال بقاعدة بيانات المخزون');
      }

      for (final item in sale.items) {
        final cleanProductCode = item.productCode.trim();
        if (cleanProductCode.isEmpty) {
          return Result.error('كود المنتج فارغ للمنتج: ${item.productName}');
        }

        final rows = await inventoryDb.rawQuery(
          'SELECT ${DataBaseSqflite.quantity} as qty, ${DataBaseSqflite.name} as name FROM ${DataBaseSqflite.tableName} WHERE TRIM(${DataBaseSqflite.codeItem}) = ?',
          [cleanProductCode],
        );
        if (rows.isEmpty) {
          return Result.error(
            'المنتج غير موجود في المخزون: ${item.productName} (كود: $cleanProductCode)',
          );
        }
        final qtyVal = rows.first['qty'];
        int currentQty;
        if (qtyVal is int) {
          currentQty = qtyVal;
        } else if (qtyVal is double) {
          currentQty = qtyVal.toInt();
        } else if (qtyVal is String) {
          currentQty = int.tryParse(qtyVal) ?? 0;
        } else {
          currentQty = 0;
        }
        if (currentQty < item.quantity) {
          final name = (rows.first['name'] ?? '').toString();
          return Result.error(
            'الكمية المطلوبة من $name (${item.quantity}) أكبر من المتاح ($currentQty)',
          );
        }
      }

      // بدء المعاملة
      late int saleId;
      await db!.transaction((txn) async {
        // إدراج الفاتورة الرئيسية
        saleId = await txn.insert(POSDatabase.salesTable, sale.toMap());

        // إدراج عناصر الفاتورة
        for (final item in sale.items) {
          final itemMap = item.copyWith(saleId: saleId).toMap();
          await txn.insert(POSDatabase.saleItemsTable, itemMap);
        }

        // تحديث كميات المنتجات في المخزون (مع تعويض في حال الفشل)
        final List<Map<String, dynamic>> decremented = [];
        for (final item in sale.items) {
          // تنظيف كود المنتج من المسافات الإضافية
          final cleanProductCode = item.productCode.trim();

          if (cleanProductCode.isEmpty) {
            throw Exception('كود المنتج فارغ للمنتج: ${item.productName}');
          }

          // الحصول على اسم المنتج لاستخدامه في الرسائل
          final nameRow = await inventoryDb.query(
            DataBaseSqflite.tableName,
            columns: [DataBaseSqflite.name],
            where: 'TRIM(${DataBaseSqflite.codeItem}) = ?',
            whereArgs: [cleanProductCode],
            limit: 1,
          );
          final productName = nameRow.isNotEmpty
              ? (nameRow.first[DataBaseSqflite.name] ?? '').toString()
              : item.productName;

          // تحديث الكمية باستخدام كود المنتج المُنظف
          final updatedRows = await inventoryDb.rawUpdate(
            '''
            UPDATE ${DataBaseSqflite.tableName}
            SET ${DataBaseSqflite.quantity} = (CAST(${DataBaseSqflite.quantity} AS INTEGER) - ?)
            WHERE TRIM(${DataBaseSqflite.codeItem}) = ?
          ''',
            [item.quantity, cleanProductCode],
          );

          if (updatedRows == 0) {
            throw Exception(
              'فشل في تحديث كمية المنتج في المخزون: $productName (كود: $cleanProductCode)',
            );
          }

          // سجل عملية الخصم لتعويضها إن حدث فشل لاحقاً
          decremented.add({'code': cleanProductCode, 'qty': item.quantity});
        }

        // إذا وصلنا هنا، تم خصم الكميات بنجاح. لا حاجة لإجراءات إضافية.
      });

      return Result.success(saleId);
    } catch (e) {
      return Result.error('خطأ في حفظ الفاتورة: ${e.toString()}');
    }
  }

  /// الحصول على فاتورة برقم الفاتورة
  Future<Result<SaleModel?>> getSaleByInvoiceNumber(
    String invoiceNumber,
  ) async {
    try {
      final db = await POSDatabase.database;

      final saleResult = await db!.query(
        POSDatabase.salesTable,
        where: '${POSDatabase.saleInvoiceNumber} = ?',
        whereArgs: [invoiceNumber],
      );

      if (saleResult.isEmpty) {
        return Result.success(null);
      }

      final saleMap = saleResult.first;
      final saleId = saleMap[POSDatabase.saleId] as int;

      // الحصول على عناصر الفاتورة
      final itemsResult = await db.query(
        POSDatabase.saleItemsTable,
        where: '${POSDatabase.saleItemSaleId} = ?',
        whereArgs: [saleId],
      );

      final items = itemsResult
          .map((item) => SaleItemModel.fromMap(item))
          .toList();

      final sale = SaleModel.fromMap(saleMap, items: items);
      return Result.success(sale);
    } catch (e) {
      return Result.error('خطأ في استرجاع الفاتورة: ${e.toString()}');
    }
  }

  /// الحصول على فاتورة بالمعرف
  Future<Result<SaleModel?>> getSaleById(int id) async {
    try {
      final db = await POSDatabase.database;

      final saleResult = await db!.query(
        POSDatabase.salesTable,
        where: '${POSDatabase.saleId} = ?',
        whereArgs: [id],
      );

      if (saleResult.isEmpty) {
        return Result.success(null);
      }

      final saleMap = saleResult.first;

      // الحصول على عناصر الفاتورة
      final itemsResult = await db.query(
        POSDatabase.saleItemsTable,
        where: '${POSDatabase.saleItemSaleId} = ?',
        whereArgs: [id],
      );

      final items = itemsResult
          .map((item) => SaleItemModel.fromMap(item))
          .toList();

      final sale = SaleModel.fromMap(saleMap, items: items);
      return Result.success(sale);
    } catch (e) {
      return Result.error('خطأ في استرجاع الفاتورة: ${e.toString()}');
    }
  }

  /// الحصول على جميع المبيعات
  Future<Result<List<SaleModel>>> getAllSales({
    int? limit,
    int? offset,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final db = await POSDatabase.database;

      String query = 'SELECT * FROM ${POSDatabase.salesTable}';
      List<dynamic> args = [];

      // إضافة فلتر التاريخ
      if (fromDate != null || toDate != null) {
        query += ' WHERE';
        if (fromDate != null) {
          query += ' ${POSDatabase.saleCreatedAt} >= ?';
          args.add(fromDate.toIso8601String());
        }
        if (toDate != null) {
          if (fromDate != null) query += ' AND';
          query += ' ${POSDatabase.saleCreatedAt} <= ?';
          args.add(toDate.toIso8601String());
        }
      }

      query += ' ORDER BY ${POSDatabase.saleCreatedAt} DESC';

      // إضافة الحد والإزاحة
      if (limit != null) {
        query += ' LIMIT ?';
        args.add(limit);
        if (offset != null) {
          query += ' OFFSET ?';
          args.add(offset);
        }
      }

      final salesResult = await db!.rawQuery(query, args);
      final sales = <SaleModel>[];

      for (final saleMap in salesResult) {
        final saleId = saleMap[POSDatabase.saleId] as int;

        // الحصول على عناصر كل فاتورة
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
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getAllSales(fromDate: startOfDay, toDate: endOfDay);
  }

  /// البحث في المبيعات
  Future<Result<List<Sale>>> searchSales({
    String? invoiceNumber,
    String? customerName,
    String? customerPhone,
  }) async {
    try {
      final db = await DataBaseSqflite.databasesq;

      String query = 'SELECT * FROM sales WHERE 1=1';
      List<dynamic> args = [];

      if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
        query += ' AND invoice_number LIKE ?';
        args.add('%$invoiceNumber%');
      }

      if (customerName != null && customerName.isNotEmpty) {
        query += ' AND customer_name LIKE ?';
        args.add('%$customerName%');
      }

      if (customerPhone != null && customerPhone.isNotEmpty) {
        query += ' AND customer_phone LIKE ?';
        args.add('%$customerPhone%');
      }

      query += ' ORDER BY date DESC';

      final salesResult = await db!.rawQuery(query, args);
      final sales = <Sale>[];

      for (final saleMap in salesResult) {
        final saleId = saleMap['id'] as int;

        final itemsResult = await db.query(
          'sale_items',
          where: 'sale_id = ?',
          whereArgs: [saleId],
        );

        final items = itemsResult
            .map((item) => SaleItem.fromMap(item))
            .toList();
        final sale = Sale.fromMap(saleMap).copyWith(items: items);
        sales.add(sale);
      }

      return Result.success(sales);
    } catch (e) {
      return Result.error('خطأ في البحث: ${e.toString()}');
    }
  }

  /// حذف فاتورة
  Future<Result<bool>> deleteSale(int saleId) async {
    try {
      final db = await DataBaseSqflite.databasesq;

      // الحصول على الفاتورة أولاً لاسترجاع الكميات
      final saleResult = await getSaleById(saleId);
      if (saleResult.isError || saleResult.data == null) {
        return Result.error('لم يتم العثور على الفاتورة');
      }

      final sale = saleResult.data!;

      await db!.transaction((txn) async {
        // حذف عناصر الفاتورة
        await txn.delete(
          'sale_items',
          where: 'sale_id = ?',
          whereArgs: [saleId],
        );

        // حذف الفاتورة
        await txn.delete('sales', where: 'id = ?', whereArgs: [saleId]);

        // إرجاع الكميات للمخزون
        for (final item in sale.items) {
          await txn.rawUpdate(
            '''
            UPDATE Items 
            SET Quantity = Quantity + ? 
            WHERE Code = ?
          ''',
            [item.quantity, item.productCode],
          );
        }
      });

      return Result.success(true);
    } catch (e) {
      return Result.error('خطأ في حذف الفاتورة: ${e.toString()}');
    }
  }

  /// تحديث حالة الفاتورة
  Future<Result<bool>> updateSaleStatus(int saleId, SaleStatus status) async {
    try {
      final db = await DataBaseSqflite.databasesq;

      final rowsAffected = await db!.update(
        'sales',
        {'status': status.toString()},
        where: 'id = ?',
        whereArgs: [saleId],
      );

      if (rowsAffected > 0) {
        return Result.success(true);
      } else {
        return Result.error('لم يتم العثور على الفاتورة');
      }
    } catch (e) {
      return Result.error('خطأ في تحديث حالة الفاتورة: ${e.toString()}');
    }
  }

  /// الحصول على إحصائيات المبيعات
  Future<Result<SalesStats>> getSalesStats({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final salesResult = await getAllSales(fromDate: fromDate, toDate: toDate);

      if (salesResult.isError) {
        return Result.error(salesResult.error!);
      }

      final stats = SalesStats.fromSales(salesResult.data!.cast<SaleModel>());
      return Result.success(stats);
    } catch (e) {
      return Result.error('خطأ في حساب الإحصائيات: ${e.toString()}');
    }
  }

  /// توليد رقم فاتورة جديد
  Future<Result<String>> generateInvoiceNumber() async {
    try {
      final db = await POSDatabase.database;

      // الحصول على آخر رقم فاتورة
      final result = await db!.rawQuery('''
        SELECT ${POSDatabase.saleInvoiceNumber} FROM ${POSDatabase.salesTable} 
        ORDER BY ${POSDatabase.saleId} DESC 
        LIMIT 1
      ''');

      int nextNumber = 1;
      if (result.isNotEmpty) {
        final lastInvoice =
            result.first[POSDatabase.saleInvoiceNumber] as String;
        // استخراج الرقم من رقم الفاتورة (مثل INV-001)
        final numberPart = lastInvoice.split('-').last;
        final lastNumber = int.tryParse(numberPart) ?? 0;
        nextNumber = lastNumber + 1;
      }

      // التأكد من عدم تكرار رقم الفاتورة
      String invoiceNumber;
      bool isUnique = false;
      do {
        invoiceNumber = 'INV-${nextNumber.toString().padLeft(6, '0')}';
        final checkResult = await getSaleByInvoiceNumber(invoiceNumber);
        if (checkResult.isSuccess && checkResult.data == null) {
          isUnique = true;
        } else {
          nextNumber++;
        }
      } while (!isUnique && nextNumber < 999999);

      if (!isUnique) {
        return Result.error('تعذر توليد رقم فاتورة فريد');
      }

      return Result.success(invoiceNumber);
    } catch (e) {
      return Result.error('خطأ في توليد رقم الفاتورة: ${e.toString()}');
    }
  }

  /// الحصول على أفضل المنتجات مبيعاً
  Future<Result<List<Map<String, dynamic>>>> getTopSellingProducts({
    int limit = 10,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final db = await DataBaseSqflite.databasesq;

      String query = '''
        SELECT 
          si.product_code,
          si.product_name,
          SUM(si.quantity) as total_quantity,
          SUM(si.total) as total_revenue,
          COUNT(DISTINCT si.sale_id) as sale_count
        FROM sale_items si
        JOIN sales s ON si.sale_id = s.id
        WHERE s.status = 'completed'
      ''';

      List<dynamic> args = [];

      if (fromDate != null) {
        query += ' AND s.date >= ?';
        args.add(fromDate.toIso8601String());
      }

      if (toDate != null) {
        query += ' AND s.date <= ?';
        args.add(toDate.toIso8601String());
      }

      query += '''
        GROUP BY si.product_code, si.product_name
        ORDER BY total_quantity DESC
        LIMIT ?
      ''';
      args.add(limit);

      final result = await db!.rawQuery(query, args);
      return Result.success(result);
    } catch (e) {
      return Result.error('خطأ في استرجاع أفضل المنتجات: ${e.toString()}');
    }
  }

  /// تحديث معرف العميل في الفاتورة
  Future<Result<bool>> updateSaleCustomerId(int saleId, int customerId) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final count = await db.update(
        POSDatabase.salesTable,
        {'customer_id': customerId},
        where: '${POSDatabase.saleId} = ?',
        whereArgs: [saleId],
      );

      return Result.success(count > 0);
    } catch (e) {
      return Result.error('خطأ في تحديث معرف العميل: ${e.toString()}');
    }
  }
}
