import 'package:pos/Helper/DataBase/POSDatabase.dart';
import 'package:pos/Helper/Log/LogApp.dart';
import 'package:pos/Helper/Result.dart';
import 'package:pos/Model/DebtModel.dart';

/// مستودع إدارة الديون
class DebtRepository {
  // أسماء الجداول
  static const String debtsTable = POSDatabase.debtsTable;
  static const String debtTransactionsTable = POSDatabase.debtTransactionsTable;

  /// إضافة دين جديد
  Future<Result<DebtModel>> addDebt(DebtModel debt) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('فشل في الاتصال بقاعدة البيانات');
      }

      if (!debt.isValid) {
        return Result.error('بيانات الدين غير صحيحة');
      }

      final now = DateTime.now();
      final debtData = debt
          .copyWith(
            createdAt: now,
            updatedAt: now,
            remainingAmount: debt.amount - debt.paidAmount,
            status: debt.calculatedStatus,
          )
          .toMap();

      final id = await db.insert(debtsTable, debtData);
      final newDebt = debt.copyWith(
        id: id,
        createdAt: now,
        updatedAt: now,
        remainingAmount: debt.amount - debt.paidAmount,
        status: debt.calculatedStatus,
      );

      logInfo('تم إضافة دين جديد: ${newDebt.partyName}');
      return Result.success(newDebt);
    } catch (e) {
      logError('خطأ في إضافة الدين: $e');
      return Result.error('فشل في إضافة الدين: $e');
    }
  }

  /// تحديث دين موجود
  Future<Result<DebtModel>> updateDebt(DebtModel debt) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('فشل في الاتصال بقاعدة البيانات');
      }

      if (debt.id == null || !debt.isValid) {
        return Result.error('بيانات الدين غير صحيحة');
      }

      final updatedDebt = debt.copyWith(
        updatedAt: DateTime.now(),
        remainingAmount: debt.amount - debt.paidAmount,
        status: debt.calculatedStatus,
      );

      final count = await db.update(
        debtsTable,
        updatedDebt.toMap(),
        where: 'id = ?',
        whereArgs: [debt.id],
      );

      if (count == 0) {
        return Result.error('الدين غير موجود');
      }

      logInfo('تم تحديث الدين: ${updatedDebt.partyName}');
      return Result.success(updatedDebt);
    } catch (e) {
      logError('خطأ في تحديث الدين: $e');
      return Result.error('فشل في تحديث الدين: $e');
    }
  }

  /// حذف دين
  Future<Result<bool>> deleteDebt(int debtId) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('فشل في الاتصال بقاعدة البيانات');
      }

      final count = await db.delete(
        debtsTable,
        where: 'id = ?',
        whereArgs: [debtId],
      );

      if (count == 0) {
        return Result.error('الدين غير موجود');
      }

      logInfo('تم حذف الدين رقم: $debtId');
      return Result.success(true);
    } catch (e) {
      logError('خطأ في حذف الدين: $e');
      return Result.error('فشل في حذف الدين: $e');
    }
  }

  /// أرشفة دين
  Future<Result<DebtModel>> archiveDebt(int debtId, bool archived) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('فشل في الاتصال بقاعدة البيانات');
      }

      final count = await db.update(
        debtsTable,
        {
          'archived': archived ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [debtId],
      );

      if (count == 0) {
        return Result.error('الدين غير موجود');
      }

      final debtResult = await getDebtById(debtId);
      if (debtResult.isSuccess) {
        logInfo(
          'تم ${archived ? 'أرشفة' : 'إلغاء أرشفة'} الدين: ${debtResult.data!.partyName}',
        );
        return Result.success(debtResult.data!);
      }

      return Result.error('فشل في جلب بيانات الدين المحدث');
    } catch (e) {
      logError('خطأ في أرشفة الدين: $e');
      return Result.error('فشل في أرشفة الدين: $e');
    }
  }

  /// جلب دين بالمعرف
  Future<Result<DebtModel>> getDebtById(int debtId) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('فشل في الاتصال بقاعدة البيانات');
      }

      final result = await db.query(
        debtsTable,
        where: 'id = ?',
        whereArgs: [debtId],
      );

      if (result.isEmpty) {
        return Result.error('الدين غير موجود');
      }

      final debt = DebtModel.fromMap(result.first);
      return Result.success(debt);
    } catch (e) {
      logError('خطأ في جلب الدين: $e');
      return Result.error('فشل في جلب الدين: $e');
    }
  }

  /// جلب جميع الديون مع الفلترة والبحث
  Future<Result<List<DebtModel>>> getDebts({
    String? searchQuery,
    String? partyType,
    String? status,
    bool? archived,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('فشل في الاتصال بقاعدة البيانات');
      }

      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      // فلترة حسب البحث
      if (searchQuery != null && searchQuery.isNotEmpty) {
        whereClause += ' AND (party_name LIKE ? OR party_phone LIKE ?)';
        whereArgs.addAll(['%$searchQuery%', '%$searchQuery%']);
      }

      // فلترة حسب نوع الطرف
      if (partyType != null && partyType.isNotEmpty) {
        whereClause += ' AND party_type = ?';
        whereArgs.add(partyType);
      }

      // فلترة حسب الحالة
      if (status != null && status.isNotEmpty) {
        whereClause += ' AND status = ?';
        whereArgs.add(status);
      }

      // فلترة حسب الأرشفة
      if (archived != null) {
        whereClause += ' AND archived = ?';
        whereArgs.add(archived ? 1 : 0);
      }

      final result = await db.query(
        debtsTable,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );

      final debts = result.map((map) => DebtModel.fromMap(map)).toList();
      return Result.success(debts);
    } catch (e) {
      logError('خطأ في جلب الديون: $e');
      return Result.error('فشل في جلب الديون: $e');
    }
  }

  /// جلب ديون طرف معين (عميل أو مورد)
  Future<Result<List<DebtModel>>> getDebtsByParty(
    int partyId,
    String partyType,
  ) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('فشل في الاتصال بقاعدة البيانات');
      }

      final result = await db.query(
        debtsTable,
        where: 'party_id = ? AND party_type = ?',
        whereArgs: [partyId, partyType],
        orderBy: 'created_at DESC',
      );

      final debts = result.map((map) => DebtModel.fromMap(map)).toList();
      return Result.success(debts);
    } catch (e) {
      logError('خطأ في جلب ديون الطرف: $e');
      return Result.error('فشل في جلب ديون الطرف: $e');
    }
  }

  /// إضافة دفعة على دين
  Future<Result<DebtModel>> addPayment(
    int debtId,
    double amount, {
    String? notes,
  }) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('فشل في الاتصال بقاعدة البيانات');
      }

      if (amount <= 0) {
        return Result.error('مبلغ الدفعة يجب أن يكون أكبر من صفر');
      }

      // جلب الدين الحالي
      final debtResult = await getDebtById(debtId);
      if (!debtResult.isSuccess) {
        return Result.error(debtResult.error!);
      }

      final debt = debtResult.data!;

      // التحقق من أن المبلغ لا يتجاوز المبلغ المتبقي
      if (amount > debt.remainingAmount) {
        return Result.error('مبلغ الدفعة يتجاوز المبلغ المتبقي');
      }

      // إضافة معاملة الدفع
      final transaction = DebtTransactionModel(
        debtId: debtId,
        amountPaid: amount,
        date: DateTime.now(),
        notes: notes,
        createdAt: DateTime.now(),
      );

      await db.insert(debtTransactionsTable, transaction.toMap());

      // تحديث الدين
      final newPaidAmount = debt.paidAmount + amount;
      final newRemainingAmount = debt.amount - newPaidAmount;
      final newStatus = newRemainingAmount <= 0
          ? 'paid'
          : newPaidAmount > 0
          ? 'partiallyPaid'
          : 'unpaid';

      final updatedDebt = debt.copyWith(
        paidAmount: newPaidAmount,
        remainingAmount: newRemainingAmount,
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      final updateResult = await updateDebt(updatedDebt);
      if (!updateResult.isSuccess) {
        return Result.error(updateResult.error!);
      }

      logInfo('تم إضافة دفعة بمبلغ $amount للدين: ${debt.partyName}');
      return Result.success(updateResult.data!);
    } catch (e) {
      logError('خطأ في إضافة الدفعة: $e');
      return Result.error('فشل في إضافة الدفعة: $e');
    }
  }

  /// جلب معاملات دين معين
  Future<Result<List<DebtTransactionModel>>> getDebtTransactions(
    int debtId,
  ) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('فشل في الاتصال بقاعدة البيانات');
      }

      final result = await db.query(
        debtTransactionsTable,
        where: 'debt_id = ?',
        whereArgs: [debtId],
        orderBy: 'date DESC',
      );

      final transactions = result
          .map((map) => DebtTransactionModel.fromMap(map))
          .toList();
      return Result.success(transactions);
    } catch (e) {
      logError('خطأ في جلب معاملات الدين: $e');
      return Result.error('فشل في جلب معاملات الدين: $e');
    }
  }

  /// جلب إحصائيات الديون
  Future<Result<Map<String, dynamic>>> getDebtsStatistics() async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('فشل في الاتصال بقاعدة البيانات');
      }

      // إجمالي الديون
      final totalResult = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_count,
          SUM(amount) as total_amount,
          SUM(paid_amount) as total_paid,
          SUM(remaining_amount) as total_remaining
        FROM $debtsTable 
        WHERE archived = 0
      ''');

      // الديون حسب الحالة
      final statusResult = await db.rawQuery('''
        SELECT 
          status,
          COUNT(*) as count,
          SUM(remaining_amount) as amount
        FROM $debtsTable 
        WHERE archived = 0
        GROUP BY status
      ''');

      // الديون حسب النوع
      final typeResult = await db.rawQuery('''
        SELECT 
          party_type,
          COUNT(*) as count,
          SUM(remaining_amount) as amount
        FROM $debtsTable 
        WHERE archived = 0
        GROUP BY party_type
      ''');

      // الديون المتأخرة
      final overdueResult = await db.rawQuery(
        '''
        SELECT 
          COUNT(*) as count,
          SUM(remaining_amount) as amount
        FROM $debtsTable 
        WHERE archived = 0 AND status != 'paid' AND due_date < ?
      ''',
        [DateTime.now().toIso8601String()],
      );

      final statistics = {
        'total': totalResult.first,
        'by_status': statusResult,
        'by_type': typeResult,
        'overdue': overdueResult.first,
      };

      return Result.success(statistics);
    } catch (e) {
      logError('خطأ في جلب إحصائيات الديون: $e');
      return Result.error('فشل في جلب إحصائيات الديون: $e');
    }
  }

  /// البحث في الديون
  Future<Result<List<DebtModel>>> searchDebts(String query) async {
    return getDebts(searchQuery: query);
  }

  /// جلب الديون المتأخرة
  Future<Result<List<DebtModel>>> getOverdueDebts() async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('فشل في الاتصال بقاعدة البيانات');
      }

      final result = await db.query(
        debtsTable,
        where: 'archived = 0 AND status != ? AND due_date < ?',
        whereArgs: ['paid', DateTime.now().toIso8601String()],
        orderBy: 'due_date ASC',
      );

      final debts = result.map((map) => DebtModel.fromMap(map)).toList();
      return Result.success(debts);
    } catch (e) {
      logError('خطأ في جلب الديون المتأخرة: $e');
      return Result.error('فشل في جلب الديون المتأخرة: $e');
    }
  }
}
