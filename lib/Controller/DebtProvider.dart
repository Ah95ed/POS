import 'package:flutter/material.dart';
import 'package:pos/Helper/Log/LogApp.dart';
import 'package:pos/Model/DebtModel.dart';
import 'package:pos/Repository/DebtRepository.dart';

/// مزود إدارة الديون
class DebtProvider extends ChangeNotifier {
  final DebtRepository _repository = DebtRepository();

  // حالة التحميل
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // قائمة الديون
  List<DebtModel> _debts = [];
  List<DebtModel> get debts => _debts;

  // قائمة الديون المؤرشفة
  List<DebtModel> _archivedDebts = [];
  List<DebtModel> get archivedDebts => _archivedDebts;

  // الديون المتأخرة
  List<DebtModel> _overdueDebts = [];
  List<DebtModel> get overdueDebts => _overdueDebts;

  // معاملات الدين المحدد
  List<DebtTransactionModel> _debtTransactions = [];
  List<DebtTransactionModel> get debtTransactions => _debtTransactions;

  // إحصائيات الديون
  Map<String, dynamic> _statistics = {};
  Map<String, dynamic> get statistics => _statistics;

  // رسالة الخطأ
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // فلاتر البحث
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedPartyType = '';
  String get selectedPartyType => _selectedPartyType;

  String _selectedStatus = '';
  String get selectedStatus => _selectedStatus;

  // الصفحة الحالية للتصفح
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMoreData = true;
  bool get hasMoreData => _hasMoreData;

  /// تعيين حالة التحميل
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// تعيين رسالة الخطأ
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// تحميل الديون
  Future<void> loadDebts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _hasMoreData = true;
      _debts.clear();
    }

    if (_isLoading || !_hasMoreData) return;

    _setLoading(true);
    _setError(null);

    try {
      final result = await _repository.getDebts(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        partyType: _selectedPartyType.isEmpty ? null : _selectedPartyType,
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
        archived: false,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (result.isSuccess) {
        final newDebts = result.data!;

        if (refresh) {
          _debts = newDebts;
        } else {
          _debts.addAll(newDebts);
        }

        _hasMoreData = newDebts.length == _pageSize;
        _currentPage++;

        logInfo('تم تحميل ${newDebts.length} دين');
      } else {
        _setError(result.error);
        logError('فشل في تحميل الديون: ${result.error}');
      }
    } catch (e) {
      _setError('خطأ غير متوقع: $e');
      logError('خطأ في تحميل الديون: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// تحميل الديون المؤرشفة
  Future<void> loadArchivedDebts() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _repository.getDebts(archived: true);

      if (result.isSuccess) {
        _archivedDebts = result.data!;
        logInfo('تم تحميل ${_archivedDebts.length} دين مؤرشف');
      } else {
        _setError(result.error);
        logError('فشل في تحميل الديون المؤرشفة: ${result.error}');
      }
    } catch (e) {
      _setError('خطأ غير متوقع: $e');
      logError('خطأ في تحميل الديون المؤرشفة: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// تحميل الديون المتأخرة
  Future<void> loadOverdueDebts() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _repository.getOverdueDebts();

      if (result.isSuccess) {
        _overdueDebts = result.data!;
        logInfo('تم تحميل ${_overdueDebts.length} دين متأخر');
      } else {
        _setError(result.error);
        logError('فشل في تحميل الديون المتأخرة: ${result.error}');
      }
    } catch (e) {
      _setError('خطأ غير متوقع: $e');
      logError('خطأ في تحميل الديون المتأخرة: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// تحميل إحصائيات الديون
  Future<void> loadStatistics() async {
    try {
      final result = await _repository.getDebtsStatistics();

      if (result.isSuccess) {
        _statistics = result.data!;
        notifyListeners();
        logInfo('تم تحميل إحصائيات الديون');
      } else {
        logError('فشل في تحميل إحصائيات الديون: ${result.error}');
      }
    } catch (e) {
      logError('خطأ في تحميل إحصائيات الديون: $e');
    }
  }

  /// إضافة دين جديد
  Future<bool> addDebt(DebtModel debt) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _repository.addDebt(debt);

      if (result.isSuccess) {
        _debts.insert(0, result.data!);
        await loadStatistics();
        notifyListeners();
        logInfo('تم إضافة دين جديد: ${debt.partyName}');
        return true;
      } else {
        _setError(result.error);
        logError('فشل في إضافة الدين: ${result.error}');
        return false;
      }
    } catch (e) {
      _setError('خطأ غير متوقع: $e');
      logError('خطأ في إضافة الدين: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// تحديث دين موجود
  Future<bool> updateDebt(DebtModel debt) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _repository.updateDebt(debt);

      if (result.isSuccess) {
        final index = _debts.indexWhere((d) => d.id == debt.id);
        if (index != -1) {
          _debts[index] = result.data!;
        }
        await loadStatistics();
        notifyListeners();
        logInfo('تم تحديث الدين: ${debt.partyName}');
        return true;
      } else {
        _setError(result.error);
        logError('فشل في تحديث الدين: ${result.error}');
        return false;
      }
    } catch (e) {
      _setError('خطأ غير متوقع: $e');
      logError('خطأ في تحديث الدين: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// حذف دين
  Future<bool> deleteDebt(int debtId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _repository.deleteDebt(debtId);

      if (result.isSuccess) {
        _debts.removeWhere((debt) => debt.id == debtId);
        _archivedDebts.removeWhere((debt) => debt.id == debtId);
        await loadStatistics();
        notifyListeners();
        logInfo('تم حذف الدين رقم: $debtId');
        return true;
      } else {
        _setError(result.error);
        logError('فشل في حذف الدين: ${result.error}');
        return false;
      }
    } catch (e) {
      _setError('خطأ غير متوقع: $e');
      logError('خطأ في حذف الدين: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// أرشفة دين
  Future<bool> archiveDebt(int debtId, bool archived) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _repository.archiveDebt(debtId, archived);

      if (result.isSuccess) {
        final debt = result.data!;

        if (archived) {
          // نقل من الديون العادية إلى المؤرشفة
          _debts.removeWhere((d) => d.id == debtId);
          _archivedDebts.insert(0, debt);
        } else {
          // نقل من المؤرشفة إلى الديون العادية
          _archivedDebts.removeWhere((d) => d.id == debtId);
          _debts.insert(0, debt);
        }

        await loadStatistics();
        notifyListeners();
        logInfo(
          'تم ${archived ? 'أرشفة' : 'إلغاء أرشفة'} الدين: ${debt.partyName}',
        );
        return true;
      } else {
        _setError(result.error);
        logError('فشل في أرشفة الدين: ${result.error}');
        return false;
      }
    } catch (e) {
      _setError('خطأ غير متوقع: $e');
      logError('خطأ في أرشفة الدين: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// إضافة دفعة على دين
  Future<bool> addPayment(int debtId, double amount, {String? notes}) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _repository.addPayment(debtId, amount, notes: notes);

      if (result.isSuccess) {
        final updatedDebt = result.data!;

        // تحديث الدين في القائمة
        final index = _debts.indexWhere((d) => d.id == debtId);
        if (index != -1) {
          _debts[index] = updatedDebt;
        }

        await loadStatistics();
        notifyListeners();
        logInfo('تم إضافة دفعة بمبلغ $amount للدين رقم: $debtId');
        return true;
      } else {
        _setError(result.error);
        logError('فشل في إضافة الدفعة: ${result.error}');
        return false;
      }
    } catch (e) {
      _setError('خطأ غير متوقع: $e');
      logError('خطأ في إضافة الدفعة: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// تحميل معاملات دين معين
  Future<void> loadDebtTransactions(int debtId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _repository.getDebtTransactions(debtId);

      if (result.isSuccess) {
        _debtTransactions = result.data!;
        logInfo(
          'تم تحميل ${_debtTransactions.length} معاملة للدين رقم: $debtId',
        );
      } else {
        _setError(result.error);
        logError('فشل في تحميل معاملات الدين: ${result.error}');
      }
    } catch (e) {
      _setError('خطأ غير متوقع: $e');
      logError('خطأ في تحميل معاملات الدين: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// تعيين استعلام البحث
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      loadDebts(refresh: true);
    }
  }

  /// تعيين فلتر نوع الطرف
  void setPartyTypeFilter(String partyType) {
    if (_selectedPartyType != partyType) {
      _selectedPartyType = partyType;
      loadDebts(refresh: true);
    }
  }

  /// تعيين فلتر الحالة
  void setStatusFilter(String status) {
    if (_selectedStatus != status) {
      _selectedStatus = status;
      loadDebts(refresh: true);
    }
  }

  /// مسح جميع الفلاتر
  void clearFilters() {
    _searchQuery = '';
    _selectedPartyType = '';
    _selectedStatus = '';
    loadDebts(refresh: true);
  }

  /// جلب دين بالمعرف
  Future<DebtModel?> getDebtById(int debtId) async {
    try {
      final result = await _repository.getDebtById(debtId);
      if (result.isSuccess) {
        return result.data;
      } else {
        _setError(result.error);
        return null;
      }
    } catch (e) {
      _setError('خطأ غير متوقع: $e');
      return null;
    }
  }

  /// جلب ديون طرف معين
  Future<List<DebtModel>> getDebtsByParty(int partyId, String partyType) async {
    try {
      final result = await _repository.getDebtsByParty(partyId, partyType);
      if (result.isSuccess) {
        return result.data!;
      } else {
        _setError(result.error);
        return [];
      }
    } catch (e) {
      _setError('خطأ غير متوقع: $e');
      return [];
    }
  }

  /// تحديث البيانات
  Future<void> refresh() async {
    await Future.wait([
      loadDebts(refresh: true),
      loadStatistics(),
      loadOverdueDebts(),
    ]);
  }

  /// مسح رسالة الخطأ
  void clearError() {
    _setError(null);
  }

  /// الحصول على إجمالي المبلغ المتبقي
  double get totalRemainingAmount {
    return _debts.fold(0.0, (sum, debt) => sum + debt.remainingAmount);
  }

  /// الحصول على عدد الديون غير المدفوعة
  int get unpaidDebtsCount {
    return _debts.where((debt) => debt.status == 'unpaid').length;
  }

  /// الحصول على عدد الديون المدفوعة جزئياً
  int get partiallyPaidDebtsCount {
    return _debts.where((debt) => debt.status == 'partiallyPaid').length;
  }

  /// الحصول على عدد الديون المتأخرة
  int get overdueDebtsCount {
    return _debts.where((debt) => debt.isOverdue).length;
  }
}
