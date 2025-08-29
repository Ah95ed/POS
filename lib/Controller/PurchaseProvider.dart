import 'package:flutter/foundation.dart';
import 'package:pos/Model/PurchaseModel.dart';
import 'package:pos/Model/SupplierModel.dart';
import 'package:pos/Repository/PurchaseRepository.dart';
import 'package:pos/Repository/SupplierRepository.dart';

/// مزود حالة المشتريات - Purchase Provider
/// يدير جميع العمليات والحالات المتعلقة بالمشتريات
class PurchaseProvider extends ChangeNotifier {
  final PurchaseRepository _purchaseRepository = PurchaseRepository();
  final SupplierRepository _supplierRepository = SupplierRepository();

  // الحالة العامة
  bool _isLoading = false;
  String _errorMessage = '';

  // قائمة المشتريات
  List<PurchaseModel> _purchases = [];
  List<PurchaseModel> _filteredPurchases = [];

  // المشتريات الحالية
  PurchaseModel? _currentPurchase;
  List<PurchaseItemModel> _currentPurchaseItems = [];

  // قائمة الموردين
  List<SupplierModel> _suppliers = [];

  // إحصائيات المشتريات
  PurchaseStats? _purchaseStats;

  // فلاتر البحث
  PurchaseStatus? _statusFilter;
  int? _supplierFilter;
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<PurchaseModel> get purchases => _purchases;
  List<PurchaseModel> get filteredPurchases => _filteredPurchases;
  PurchaseModel? get currentPurchase => _currentPurchase;
  List<PurchaseItemModel> get currentPurchaseItems => _currentPurchaseItems;
  List<SupplierModel> get suppliers => _suppliers;
  PurchaseStats? get purchaseStats => _purchaseStats;
  PurchaseStatus? get statusFilter => _statusFilter;
  int? get supplierFilter => _supplierFilter;
  DateTime? get startDateFilter => _startDateFilter;
  DateTime? get endDateFilter => _endDateFilter;

  /// تحديث حالة التحميل
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// تحديث رسالة الخطأ
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// مسح رسالة الخطأ
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  /// جلب جميع المشتريات
  Future<bool> loadPurchases() async {
    _setLoading(true);
    clearError();

    try {
      final result = await _purchaseRepository.getAllPurchases();

      if (result.isSuccess) {
        _purchases = result.data!;
        _applyFilters();
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('خطأ في جلب المشتريات: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// جلب الموردين
  Future<bool> loadSuppliers() async {
    try {
      final result = await _supplierRepository.getActiveSuppliers();

      if (result.isSuccess) {
        _suppliers = result.data!;
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage);
        return false;
      }
    } catch (e) {
      _setError('خطأ في جلب الموردين: ${e.toString()}');
      return false;
    }
  }

  /// إنشاء مشتريات جديدة
  Future<bool> createPurchase(PurchaseModel purchase) async {
    _setLoading(true);
    clearError();

    try {
      final result = await _purchaseRepository.createPurchase(purchase);

      if (result.isSuccess) {
        _purchases.insert(0, result.data!);
        _applyFilters();
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('خطأ في إنشاء المشتريات: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// تحديث حالة المشتريات
  Future<bool> updatePurchaseStatus(
    int purchaseId,
    PurchaseStatus status,
  ) async {
    _setLoading(true);
    clearError();

    try {
      final result = await _purchaseRepository.updatePurchaseStatus(
        purchaseId,
        status,
      );

      if (result.isSuccess) {
        final index = _purchases.indexWhere((p) => p.id == purchaseId);
        if (index != -1) {
          _purchases[index] = result.data!;
          _applyFilters();
        }

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('خطأ في تحديث حالة المشتريات: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// حذف مشتريات
  Future<bool> deletePurchase(int purchaseId) async {
    _setLoading(true);
    clearError();

    try {
      final result = await _purchaseRepository.deletePurchase(purchaseId);

      if (result.isSuccess) {
        _purchases.removeWhere((p) => p.id == purchaseId);
        _applyFilters();
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('خطأ في حذف المشتريات: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// جلب تفاصيل مشتريات
  Future<bool> loadPurchaseDetails(int purchaseId) async {
    _setLoading(true);
    clearError();

    try {
      final result = await _purchaseRepository.getPurchaseById(purchaseId);

      if (result.isSuccess && result.data != null) {
        _currentPurchase = result.data!;
        _currentPurchaseItems = result.data!.items;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('خطأ في جلب تفاصيل المشتريات: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// البحث في المشتريات
  Future<void> searchPurchases(String query) async {
    if (query.trim().isEmpty) {
      _applyFilters();
      return;
    }

    clearError();

    try {
      final result = await _purchaseRepository.searchPurchases(query);

      if (result.isSuccess) {
        _filteredPurchases = result.data!;
        notifyListeners();
      } else {
        _setError(result.errorMessage);
      }
    } catch (e) {
      _setError('خطأ في البحث: ${e.toString()}');
    }
  }

  /// تطبيق الفلاتر
  void _applyFilters() {
    _filteredPurchases = List.from(_purchases);

    // فلتر بالحالة
    if (_statusFilter != null) {
      _filteredPurchases = _filteredPurchases
          .where((purchase) => purchase.status == _statusFilter)
          .toList();
    }

    // فلتر بالمورد
    if (_supplierFilter != null) {
      _filteredPurchases = _filteredPurchases
          .where((purchase) => purchase.supplierId == _supplierFilter)
          .toList();
    }

    // فلتر بالتاريخ
    if (_startDateFilter != null && _endDateFilter != null) {
      _filteredPurchases = _filteredPurchases
          .where(
            (purchase) =>
                purchase.date.isAfter(_startDateFilter!) &&
                purchase.date.isBefore(
                  _endDateFilter!.add(const Duration(days: 1)),
                ),
          )
          .toList();
    }
  }

  /// تحديد فلتر الحالة
  void setStatusFilter(PurchaseStatus? status) {
    _statusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  /// تحديد فلتر المورد
  void setSupplierFilter(int? supplierId) {
    _supplierFilter = supplierId;
    _applyFilters();
    notifyListeners();
  }

  /// تحديد فلتر التاريخ
  void setDateFilter(DateTime? startDate, DateTime? endDate) {
    _startDateFilter = startDate;
    _endDateFilter = endDate;
    _applyFilters();
    notifyListeners();
  }

  /// مسح جميع الفلاتر
  void clearFilters() {
    _statusFilter = null;
    _supplierFilter = null;
    _startDateFilter = null;
    _endDateFilter = null;
    _applyFilters();
    notifyListeners();
  }

  /// ترتيب المشتريات حسب التاريخ
  void sortPurchasesByDate({bool ascending = false}) {
    _filteredPurchases.sort((a, b) {
      return ascending ? a.date.compareTo(b.date) : b.date.compareTo(a.date);
    });
    notifyListeners();
  }

  /// ترتيب المشتريات حسب القيمة
  void sortPurchasesByAmount({bool ascending = false}) {
    _filteredPurchases.sort((a, b) {
      return ascending
          ? a.total.compareTo(b.total)
          : b.total.compareTo(a.total);
    });
    notifyListeners();
  }

  /// الحصول على مشتريات حسب الحالة
  Future<List<PurchaseModel>> getPurchasesByStatus(
    PurchaseStatus status,
  ) async {
    try {
      final result = await _purchaseRepository.getPurchasesByStatus(status);
      return result.isSuccess ? result.data! : [];
    } catch (e) {
      _setError('خطأ في جلب المشتريات: ${e.toString()}');
      return [];
    }
  }

  /// الحصول على مشتريات مورد معين
  Future<List<PurchaseModel>> getPurchasesBySupplierId(int supplierId) async {
    try {
      final result = await _purchaseRepository.getPurchasesBySupplierId(
        supplierId,
      );
      return result.isSuccess ? result.data! : [];
    } catch (e) {
      _setError('خطأ في جلب مشتريات المورد: ${e.toString()}');
      return [];
    }
  }

  /// الحصول على مشتريات في فترة زمنية
  Future<List<PurchaseModel>> getPurchasesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final result = await _purchaseRepository.getPurchasesByDateRange(
        startDate,
        endDate,
      );
      return result.isSuccess ? result.data! : [];
    } catch (e) {
      _setError('خطأ في جلب المشتريات: ${e.toString()}');
      return [];
    }
  }

  /// جلب إحصائيات المشتريات
  Future<bool> loadPurchaseStats() async {
    clearError();

    try {
      final result = await _purchaseRepository.getPurchasesStats();

      if (result.isSuccess) {
        _purchaseStats = result.data!;
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage);
        return false;
      }
    } catch (e) {
      _setError('خطأ في جلب إحصائيات المشتريات: ${e.toString()}');
      return false;
    }
  }

  /// عدد المشتريات المعلقة
  int get pendingPurchasesCount {
    return _purchases
        .where((purchase) => purchase.status == PurchaseStatus.pending)
        .length;
  }

  /// عدد المشتريات المكتملة
  int get completedPurchasesCount {
    return _purchases
        .where((purchase) => purchase.status == PurchaseStatus.completed)
        .length;
  }

  /// إجمالي قيمة المشتريات
  double get totalPurchasesAmount {
    return _purchases.fold(0.0, (sum, purchase) => sum + purchase.total);
  }

  /// إجمالي قيمة المشتريات المكتملة
  double get completedPurchasesAmount {
    return _purchases
        .where((purchase) => purchase.status == PurchaseStatus.completed)
        .fold(0.0, (sum, purchase) => sum + purchase.total);
  }

  /// متوسط قيمة المشتريات
  double get averagePurchaseAmount {
    if (_purchases.isEmpty) return 0.0;
    return totalPurchasesAmount / _purchases.length;
  }

  /// بدء مشتريات جديدة
  void startNewPurchase() {
    _currentPurchase = null;
    _currentPurchaseItems.clear();
    clearError();
    notifyListeners();
  }

  /// إضافة عنصر للمشتريات الحالية
  void addItemToCurrentPurchase(PurchaseItemModel item) {
    final existingIndex = _currentPurchaseItems.indexWhere(
      (i) => i.productId == item.productId,
    );

    if (existingIndex != -1) {
      // تحديث الكمية إذا كان المنتج موجود
      final existingItem = _currentPurchaseItems[existingIndex];
      final newQuantity = existingItem.quantity + item.quantity;
      final newTotal = newQuantity * existingItem.unitPrice;

      _currentPurchaseItems[existingIndex] = existingItem.copyWith(
        quantity: newQuantity,
        total: newTotal,
      );
    } else {
      // إضافة منتج جديد
      _currentPurchaseItems.add(item);
    }

    notifyListeners();
  }

  /// إزالة عنصر من المشتريات الحالية
  void removeItemFromCurrentPurchase(int index) {
    if (index >= 0 && index < _currentPurchaseItems.length) {
      _currentPurchaseItems.removeAt(index);
      notifyListeners();
    }
  }

  /// تحديث كمية عنصر في المشتريات الحالية
  void updateItemQuantityInCurrentPurchase(int index, int newQuantity) {
    if (index >= 0 && index < _currentPurchaseItems.length && newQuantity > 0) {
      final item = _currentPurchaseItems[index];
      final newTotal = newQuantity * item.unitPrice;

      _currentPurchaseItems[index] = item.copyWith(
        quantity: newQuantity,
        total: newTotal,
      );

      notifyListeners();
    }
  }

  /// حساب إجمالي المشتريات الحالية
  double get currentPurchaseSubtotal {
    return _currentPurchaseItems.fold(0.0, (sum, item) => sum + item.total);
  }

  /// عدد عناصر المشتريات الحالية
  int get currentPurchaseItemsCount {
    return _currentPurchaseItems.length;
  }

  /// إعادة تحميل البيانات
  Future<void> refresh() async {
    await Future.wait([loadPurchases(), loadSuppliers(), loadPurchaseStats()]);
  }

  /// مسح جميع البيانات
  void clear() {
    _purchases.clear();
    _filteredPurchases.clear();
    _suppliers.clear();
    _currentPurchase = null;
    _currentPurchaseItems.clear();
    _purchaseStats = null;
    clearFilters();
    clearError();
    notifyListeners();
  }
}
