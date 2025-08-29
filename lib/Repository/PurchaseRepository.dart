import 'package:pos/Helper/DataBase/POSDatabase.dart';
import 'package:pos/Helper/Result.dart';
import 'package:pos/Model/PurchaseModel.dart';
import 'package:pos/Repository/SupplierRepository.dart';

/// مستودع المشتريات - Purchase Repository
/// يدير جميع العمليات المتعلقة بقاعدة البيانات للمشتريات
class PurchaseRepository {
  final SupplierRepository _supplierRepository = SupplierRepository();

  /// الحصول على جميع المشتريات
  Future<Result<List<PurchaseModel>>> getAllPurchases() async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT p.*, s.${POSDatabase.supplierName}, s.${POSDatabase.supplierCompany}
        FROM ${POSDatabase.purchasesTable} p
        LEFT JOIN ${POSDatabase.suppliersTable} s ON p.${POSDatabase.purchaseSupplierId} = s.${POSDatabase.supplierId}
        ORDER BY p.${POSDatabase.purchaseCreatedAt} DESC
      ''');

      final purchases = <PurchaseModel>[];
      for (final map in maps) {
        final purchase = PurchaseModel.fromMap(map);

        // إضافة بيانات المورد إذا كانت متوفرة
        final supplier = map[POSDatabase.supplierName] != null
            ? await _supplierRepository.getSupplierById(purchase.supplierId!)
            : null;

        final purchaseWithSupplier = purchase.copyWith(
          supplier: supplier?.isSuccess == true ? supplier!.data : null,
        );

        purchases.add(purchaseWithSupplier);
      }

      return Result.success(purchases);
    } catch (e) {
      return Result.error('خطأ في جلب المشتريات: ${e.toString()}');
    }
  }

  /// الحصول على مشتريات حسب الحالة
  Future<Result<List<PurchaseModel>>> getPurchasesByStatus(
    PurchaseStatus status,
  ) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        POSDatabase.purchasesTable,
        where: '${POSDatabase.purchaseStatus} = ?',
        whereArgs: [status.toString().split('.').last],
        orderBy: '${POSDatabase.purchaseCreatedAt} DESC',
      );

      final purchases = maps.map((map) => PurchaseModel.fromMap(map)).toList();
      return Result.success(purchases);
    } catch (e) {
      return Result.error('خطأ في جلب المشتريات: ${e.toString()}');
    }
  }

  /// الحصول على مشتريات مورد معين
  Future<Result<List<PurchaseModel>>> getPurchasesBySupplierId(
    int supplierId,
  ) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        POSDatabase.purchasesTable,
        where: '${POSDatabase.purchaseSupplierId} = ?',
        whereArgs: [supplierId],
        orderBy: '${POSDatabase.purchaseCreatedAt} DESC',
      );

      final purchases = maps.map((map) => PurchaseModel.fromMap(map)).toList();
      return Result.success(purchases);
    } catch (e) {
      return Result.error('خطأ في جلب مشتريات المورد: ${e.toString()}');
    }
  }

  /// الحصول على مشتريات بالمعرف مع العناصر
  Future<Result<PurchaseModel?>> getPurchaseById(int id) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        POSDatabase.purchasesTable,
        where: '${POSDatabase.purchaseId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return Result.success(null);
      }

      final purchase = PurchaseModel.fromMap(maps.first);

      // جلب عناصر المشتريات
      final itemsResult = await getPurchaseItems(id);
      if (!itemsResult.isSuccess) {
        return Result.error(itemsResult.errorMessage);
      }

      // جلب بيانات المورد
      final supplier = purchase.supplierId != null
          ? await _supplierRepository.getSupplierById(purchase.supplierId!)
          : null;

      final purchaseWithDetails = purchase.copyWith(
        items: itemsResult.data!,
        supplier: supplier?.isSuccess == true ? supplier!.data : null,
      );

      return Result.success(purchaseWithDetails);
    } catch (e) {
      return Result.error('خطأ في جلب المشتريات: ${e.toString()}');
    }
  }

  /// الحصول على عناصر مشتريات
  Future<Result<List<PurchaseItemModel>>> getPurchaseItems(
    int purchaseId,
  ) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        POSDatabase.purchaseItemsTable,
        where: '${POSDatabase.purchaseItemPurchaseId} = ?',
        whereArgs: [purchaseId],
      );

      final items = maps.map((map) => PurchaseItemModel.fromMap(map)).toList();
      return Result.success(items);
    } catch (e) {
      return Result.error('خطأ في جلب عناصر المشتريات: ${e.toString()}');
    }
  }

  /// إنشاء مشتريات جديدة
  Future<Result<PurchaseModel>> createPurchase(PurchaseModel purchase) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      if (!purchase.isValid) {
        return Result.error('بيانات المشتريات غير صحيحة');
      }

      // التحقق من عدم وجود رقم فاتورة مكرر
      final existingPurchase = await getPurchaseByInvoiceNumber(
        purchase.invoiceNumber,
      );
      if (existingPurchase.isSuccess && existingPurchase.data != null) {
        return Result.error('رقم الفاتورة موجود بالفعل');
      }

      return await db.transaction((txn) async {
        // إدراج المشتريات
        final purchaseId = await txn.insert(
          POSDatabase.purchasesTable,
          purchase.toMap(),
        );

        // إدراج عناصر المشتريات
        for (final item in purchase.items) {
          final itemWithPurchaseId = item.copyWith(purchaseId: purchaseId);
          await txn.insert(
            POSDatabase.purchaseItemsTable,
            itemWithPurchaseId.toMap(),
          );
        }

        // إذا كانت المشتريات مكتملة، تحديث المخزون
        if (purchase.status == PurchaseStatus.completed) {
          await _updateInventoryOnPurchase(txn, purchase.items);
        }

        // تحديث إجمالي مشتريات المورد
        if (purchase.supplierId != null) {
          await _supplierRepository.updateSupplierTotalPurchases(
            purchase.supplierId!,
          );
        }

        final newPurchase = purchase.copyWith(id: purchaseId);
        return Result.success(newPurchase);
      });
    } catch (e) {
      return Result.error('خطأ في إنشاء المشتريات: ${e.toString()}');
    }
  }

  /// تحديث حالة المشتريات
  Future<Result<PurchaseModel>> updatePurchaseStatus(
    int purchaseId,
    PurchaseStatus status,
  ) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      // جلب المشتريات الحالية
      final currentPurchaseResult = await getPurchaseById(purchaseId);
      if (!currentPurchaseResult.isSuccess ||
          currentPurchaseResult.data == null) {
        return Result.error('المشتريات غير موجودة');
      }

      final currentPurchase = currentPurchaseResult.data!;

      return await db.transaction((txn) async {
        // تحديث حالة المشتريات
        await txn.update(
          POSDatabase.purchasesTable,
          {POSDatabase.purchaseStatus: status.toString().split('.').last},
          where: '${POSDatabase.purchaseId} = ?',
          whereArgs: [purchaseId],
        );

        // إذا تم تغيير الحالة إلى مكتملة، تحديث المخزون
        if (status == PurchaseStatus.completed &&
            currentPurchase.status != PurchaseStatus.completed) {
          await _updateInventoryOnPurchase(txn, currentPurchase.items);
        }

        // إذا تم إلغاء المشتريات بعد اكتمالها، إلغاء تحديث المخزون
        if (status == PurchaseStatus.cancelled &&
            currentPurchase.status == PurchaseStatus.completed) {
          await _revertInventoryOnPurchase(txn, currentPurchase.items);
        }

        final updatedPurchase = currentPurchase.copyWith(status: status);
        return Result.success(updatedPurchase);
      });
    } catch (e) {
      return Result.error('خطأ في تحديث حالة المشتريات: ${e.toString()}');
    }
  }

  /// تحديث المخزون عند المشتريات
  Future<void> _updateInventoryOnPurchase(
    dynamic txn,
    List<PurchaseItemModel> items,
  ) async {
    for (final item in items) {
      await txn.rawUpdate(
        '''
        UPDATE ${POSDatabase.itemsTable} 
        SET ${POSDatabase.itemQuantity} = ${POSDatabase.itemQuantity} + ? 
        WHERE ${POSDatabase.itemId} = ?
      ''',
        [item.quantity, item.productId],
      );
    }
  }

  /// إلغاء تحديث المخزون عند إلغاء المشتريات
  Future<void> _revertInventoryOnPurchase(
    dynamic txn,
    List<PurchaseItemModel> items,
  ) async {
    for (final item in items) {
      await txn.rawUpdate(
        '''
        UPDATE ${POSDatabase.itemsTable} 
        SET ${POSDatabase.itemQuantity} = MAX(0, ${POSDatabase.itemQuantity} - ?) 
        WHERE ${POSDatabase.itemId} = ?
      ''',
        [item.quantity, item.productId],
      );
    }
  }

  /// البحث عن مشتريات برقم الفاتورة
  Future<Result<PurchaseModel?>> getPurchaseByInvoiceNumber(
    String invoiceNumber,
  ) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        POSDatabase.purchasesTable,
        where: '${POSDatabase.purchaseInvoiceNumber} = ?',
        whereArgs: [invoiceNumber],
        limit: 1,
      );

      if (maps.isEmpty) {
        return Result.success(null);
      }

      final purchase = PurchaseModel.fromMap(maps.first);
      return Result.success(purchase);
    } catch (e) {
      return Result.error('خطأ في البحث عن المشتريات: ${e.toString()}');
    }
  }

  /// البحث في المشتريات
  Future<Result<List<PurchaseModel>>> searchPurchases(String query) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        '''
        SELECT p.*, s.${POSDatabase.supplierName}
        FROM ${POSDatabase.purchasesTable} p
        LEFT JOIN ${POSDatabase.suppliersTable} s ON p.${POSDatabase.purchaseSupplierId} = s.${POSDatabase.supplierId}
        WHERE p.${POSDatabase.purchaseInvoiceNumber} LIKE ? OR 
              s.${POSDatabase.supplierName} LIKE ? OR 
              p.${POSDatabase.purchaseNotes} LIKE ?
        ORDER BY p.${POSDatabase.purchaseCreatedAt} DESC
      ''',
        ['%$query%', '%$query%', '%$query%'],
      );

      final purchases = maps.map((map) => PurchaseModel.fromMap(map)).toList();
      return Result.success(purchases);
    } catch (e) {
      return Result.error('خطأ في البحث: ${e.toString()}');
    }
  }

  /// الحصول على مشتريات في فترة زمنية
  Future<Result<List<PurchaseModel>>> getPurchasesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        POSDatabase.purchasesTable,
        where: '${POSDatabase.purchaseDate} BETWEEN ? AND ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: '${POSDatabase.purchaseDate} DESC',
      );

      final purchases = maps.map((map) => PurchaseModel.fromMap(map)).toList();
      return Result.success(purchases);
    } catch (e) {
      return Result.error('خطأ في جلب المشتريات: ${e.toString()}');
    }
  }

  /// إحصائيات المشتريات
  Future<Result<PurchaseStats>> getPurchasesStats() async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      // إجمالي المشتريات
      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${POSDatabase.purchasesTable}',
      );
      final totalPurchases = totalResult.first['count'] as int;

      // إجمالي قيمة المشتريات
      final amountResult = await db.rawQuery(
        'SELECT COALESCE(SUM(${POSDatabase.purchaseTotal}), 0) as total FROM ${POSDatabase.purchasesTable}',
      );
      final totalAmount = amountResult.first['total'] as double;

      // متوسط قيمة المشتريات
      final averageAmount = totalPurchases > 0
          ? totalAmount / totalPurchases
          : 0.0;

      // المشتريات المعلقة
      final pendingResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${POSDatabase.purchasesTable} WHERE ${POSDatabase.purchaseStatus} = ?',
        ['pending'],
      );
      final pendingPurchases = pendingResult.first['count'] as int;

      // المشتريات المكتملة
      final completedResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${POSDatabase.purchasesTable} WHERE ${POSDatabase.purchaseStatus} = ?',
        ['completed'],
      );
      final completedPurchases = completedResult.first['count'] as int;

      final stats = PurchaseStats(
        totalPurchases: totalPurchases,
        totalAmount: totalAmount,
        averageAmount: averageAmount,
        pendingPurchases: pendingPurchases,
        completedPurchases: completedPurchases,
      );

      return Result.success(stats);
    } catch (e) {
      return Result.error('خطأ في جلب إحصائيات المشتريات: ${e.toString()}');
    }
  }

  /// حذف مشتريات
  Future<Result<bool>> deletePurchase(int purchaseId) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      // التحقق من حالة المشتريات
      final purchaseResult = await getPurchaseById(purchaseId);
      if (!purchaseResult.isSuccess || purchaseResult.data == null) {
        return Result.error('المشتريات غير موجودة');
      }

      final purchase = purchaseResult.data!;
      if (purchase.status == PurchaseStatus.completed) {
        return Result.error('لا يمكن حذف مشتريات مكتملة');
      }

      return await db.transaction((txn) async {
        // حذف عناصر المشتريات
        await txn.delete(
          POSDatabase.purchaseItemsTable,
          where: '${POSDatabase.purchaseItemPurchaseId} = ?',
          whereArgs: [purchaseId],
        );

        // حذف المشتريات
        final rowsAffected = await txn.delete(
          POSDatabase.purchasesTable,
          where: '${POSDatabase.purchaseId} = ?',
          whereArgs: [purchaseId],
        );

        return Result.success(rowsAffected > 0);
      });
    } catch (e) {
      return Result.error('خطأ في حذف المشتريات: ${e.toString()}');
    }
  }
}
