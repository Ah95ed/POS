import 'package:flutter/material.dart';
import 'package:pos/Helper/Result.dart';
import 'package:pos/Model/InvoiceModel.dart';
import 'package:pos/Repository/InvoiceRepository.dart';

/// مزود حالة الفواتير - Invoice Provider
/// يدير حالة الفواتير في التطبيق باستخدام Provider pattern
class InvoiceProvider extends ChangeNotifier {
  final InvoiceRepository _invoiceRepository = InvoiceRepository();

  // قائمة الفواتير
  List<InvoiceModel> _invoices = [];
  List<InvoiceModel> get invoices => _invoices;

  // قائمة الفواتير المفلترة للبحث
  List<InvoiceModel> _filteredInvoices = [];
  List<InvoiceModel> get filteredInvoices => _filteredInvoices;

  // حالة التحميل
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // رسالة الخطأ
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // إحصائيات الفواتير
  Map<String, dynamic>? _invoiceStats;
  Map<String, dynamic>? get invoiceStats => _invoiceStats;

  // عدد الفواتير
  int get invoicesCount => _invoices.length;

  // البحث الحالي
  String _currentSearchQuery = '';
  String get currentSearchQuery => _currentSearchQuery;

  // التصفية الحالية
  String _currentStatusFilter = 'all';
  String get currentStatusFilter => _currentStatusFilter;

  /// تحميل جميع الفواتير
  Future<void> loadInvoices({int? limit, int? offset, String? orderBy}) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _invoiceRepository.getAllInvoices(
        limit: limit,
        offset: offset,
        orderBy: orderBy,
      );

      if (result.isSuccess) {
        _invoices = result.data!;
        _filteredInvoices = List.from(_invoices);
        _applyCurrentFilters();
      } else {
        _setError(result.error!);
      }
    } catch (e) {
      _setError('خطأ في تحميل الفواتير: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// إضافة فاتورة جديدة
  Future<bool> addInvoice(InvoiceModel invoice) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _invoiceRepository.addInvoice(invoice);

      if (result.isSuccess) {
        _invoices.insert(0, result.data!);
        _applyCurrentFilters();
        await _loadStats();
        return true;
      } else {
        _setError(result.error!);
        return false;
      }
    } catch (e) {
      _setError('خطأ في إضافة الفاتورة: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// تحديث فاتورة موجودة
  Future<bool> updateInvoice(InvoiceModel invoice) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _invoiceRepository.updateInvoice(invoice);

      if (result.isSuccess) {
        final index = _invoices.indexWhere((i) => i.id == invoice.id);
        if (index != -1) {
          _invoices[index] = result.data!;
          _applyCurrentFilters();
          await _loadStats();
        }
        return true;
      } else {
        _setError(result.error!);
        return false;
      }
    } catch (e) {
      _setError('خطأ في تحديث الفاتورة: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// حذف فاتورة
  Future<bool> deleteInvoice(int invoiceId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _invoiceRepository.deleteInvoice(invoiceId);

      if (result.isSuccess) {
        _invoices.removeWhere((invoice) => invoice.id == invoiceId);
        _applyCurrentFilters();
        await _loadStats();
        return true;
      } else {
        _setError(result.error!);
        return false;
      }
    } catch (e) {
      _setError('خطأ في حذف الفاتورة: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// البحث في الفواتير
  Future<void> searchInvoices(String query) async {
    _currentSearchQuery = query;

    if (query.isEmpty) {
      _filteredInvoices = List.from(_invoices);
      _applyStatusFilter();
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final result = await _invoiceRepository.searchInvoices(query);

      if (result.isSuccess) {
        _filteredInvoices = result.data!;
        _applyStatusFilter();
      } else {
        _setError(result.error!);
      }
    } catch (e) {
      _setError('خطأ في البحث: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// مسح البحث
  void clearSearch() {
    _currentSearchQuery = '';
    _filteredInvoices = List.from(_invoices);
    _applyStatusFilter();
    notifyListeners();
  }

  /// تصفية الفواتير حسب الحالة
  void filterByStatus(String status) {
    _currentStatusFilter = status;
    _applyCurrentFilters();
    notifyListeners();
  }

  /// تصفية الفواتير حسب نطاق التاريخ
  Future<void> filterByDateRange(DateTime startDate, DateTime endDate) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _invoiceRepository.getInvoicesByDateRange(
        startDate,
        endDate,
      );

      if (result.isSuccess) {
        _filteredInvoices = result.data!;
        _applyStatusFilter();
      } else {
        _setError(result.error!);
      }
    } catch (e) {
      _setError('خطأ في التصفية: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// تحديث حالة الفاتورة
  Future<bool> updateInvoiceStatus(int invoiceId, String status) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _invoiceRepository.updateInvoiceStatus(
        invoiceId,
        status,
      );

      if (result.isSuccess) {
        final index = _invoices.indexWhere((i) => i.id == invoiceId);
        if (index != -1) {
          _invoices[index] = _invoices[index].copyWith(
            status: status,
            updatedAt: DateTime.now(),
          );
          _applyCurrentFilters();
          await _loadStats();
        }
        return true;
      } else {
        _setError(result.error!);
        return false;
      }
    } catch (e) {
      _setError('خطأ في تحديث حالة الفاتورة: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// إنشاء رقم فاتورة جديد
  Future<String?> generateInvoiceNumber() async {
    try {
      final result = await _invoiceRepository.generateInvoiceNumber();

      if (result.isSuccess) {
        return result.data!;
      } else {
        _setError(result.error!);
        return null;
      }
    } catch (e) {
      _setError('خطأ في إنشاء رقم الفاتورة: ${e.toString()}');
      return null;
    }
  }

  /// التحقق من وجود رقم فاتورة
  Future<bool> isInvoiceNumberExists(
    String invoiceNumber, {
    int? excludeId,
  }) async {
    try {
      final result = await _invoiceRepository.isInvoiceNumberExists(
        invoiceNumber,
        excludeId: excludeId,
      );

      if (result.isSuccess) {
        return result.data!;
      } else {
        _setError(result.error!);
        return false;
      }
    } catch (e) {
      _setError('خطأ في التحقق من رقم الفاتورة: ${e.toString()}');
      return false;
    }
  }

  /// جلب فاتورة بالمعرف
  Future<InvoiceModel?> getInvoiceById(int invoiceId) async {
    try {
      final result = await _invoiceRepository.getInvoiceById(invoiceId);

      if (result.isSuccess) {
        return result.data;
      } else {
        _setError(result.error!);
        return null;
      }
    } catch (e) {
      _setError('خطأ في جلب الفاتورة: ${e.toString()}');
      return null;
    }
  }

  /// تحميل إحصائيات الفواتير
  Future<void> loadInvoiceStats() async {
    await _loadStats();
  }

  /// تطبيق التصفيات الحالية
  void _applyCurrentFilters() {
    if (_currentSearchQuery.isNotEmpty) {
      // إذا كان هناك بحث، لا نطبق التصفية هنا
      return;
    }

    _filteredInvoices = List.from(_invoices);
    _applyStatusFilter();
  }

  /// تطبيق تصفية الحالة
  void _applyStatusFilter() {
    if (_currentStatusFilter == 'all') {
      // لا نحتاج لتصفية إضافية
      return;
    }

    _filteredInvoices = _filteredInvoices
        .where((invoice) => invoice.status == _currentStatusFilter)
        .toList();
  }

  /// تحميل الإحصائيات
  Future<void> _loadStats() async {
    try {
      final result = await _invoiceRepository.getInvoiceStats();

      if (result.isSuccess) {
        _invoiceStats = result.data!;
        notifyListeners();
      }
    } catch (e) {
      // نتجاهل أخطاء الإحصائيات لأنها ليست حرجة
    }
  }

  /// تعيين حالة التحميل
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// تعيين رسالة خطأ
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// مسح رسالة الخطأ
  void _clearError() {
    _errorMessage = null;
  }

  /// الحصول على الفواتير حسب الحالة
  List<InvoiceModel> getInvoicesByStatus(String status) {
    if (status == 'all') {
      return _filteredInvoices;
    }
    return _filteredInvoices
        .where((invoice) => invoice.status == status)
        .toList();
  }

  /// الحصول على إجمالي قيمة الفواتير
  double get totalInvoicesAmount {
    return _filteredInvoices.fold(
      0.0,
      (sum, invoice) => sum + invoice.totalAmount,
    );
  }

  /// الحصول على عدد الفواتير المدفوعة
  int get paidInvoicesCount {
    return _filteredInvoices
        .where((invoice) => invoice.status == 'paid')
        .length;
  }

  /// الحصول على عدد الفواتير المعلقة
  int get pendingInvoicesCount {
    return _filteredInvoices
        .where((invoice) => invoice.status == 'pending')
        .length;
  }

  /// الحصول على عدد الفواتير المتأخرة
  int get overdueInvoicesCount {
    return _filteredInvoices
        .where((invoice) => invoice.status == 'overdue')
        .length;
  }

  /// إعادة تعيين جميع التصفيات
  void resetFilters() {
    _currentSearchQuery = '';
    _currentStatusFilter = 'all';
    _filteredInvoices = List.from(_invoices);
    notifyListeners();
  }

  /// تحديث الفواتير (Pull to refresh)
  Future<void> refreshInvoices() async {
    await loadInvoices();
    await _loadStats();
  }
}
