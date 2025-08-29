import 'package:flutter/foundation.dart';
import 'package:pos/Model/SupplierModel.dart';
import 'package:pos/Repository/SupplierRepository.dart';

/// مزود حالة الموردين - Supplier Provider
/// يدير جميع العمليات والحالات المتعلقة بالموردين
class SupplierProvider extends ChangeNotifier {
  final SupplierRepository _supplierRepository = SupplierRepository();

  // الحالة العامة
  bool _isLoading = false;
  String _errorMessage = '';

  // قائمة الموردين
  List<SupplierModel> _suppliers = [];
  List<SupplierModel> _filteredSuppliers = [];

  // إحصائيات الموردين
  SupplierStats? _supplierStats;

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<SupplierModel> get suppliers => _suppliers;
  List<SupplierModel> get filteredSuppliers => _filteredSuppliers;
  SupplierStats? get supplierStats => _supplierStats;

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

  /// جلب جميع الموردين
  Future<bool> loadSuppliers() async {
    _setLoading(true);
    clearError();

    try {
      final result = await _supplierRepository.getAllSuppliers();

      if (result.isSuccess) {
        _suppliers = result.data!;
        _filteredSuppliers = List.from(_suppliers);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('خطأ في جلب الموردين: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// جلب الموردين النشطين فقط
  Future<bool> loadActiveSuppliers() async {
    _setLoading(true);
    clearError();

    try {
      final result = await _supplierRepository.getActiveSuppliers();

      if (result.isSuccess) {
        _suppliers = result.data!;
        _filteredSuppliers = List.from(_suppliers);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('خطأ في جلب الموردين النشطين: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// إضافة مورد جديد
  Future<bool> addSupplier(SupplierModel supplier) async {
    _setLoading(true);
    clearError();

    try {
      final result = await _supplierRepository.addSupplier(supplier);

      if (result.isSuccess) {
        _suppliers.add(result.data!);
        _filteredSuppliers = List.from(_suppliers);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('خطأ في إضافة المورد: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// تحديث مورد
  Future<bool> updateSupplier(SupplierModel supplier) async {
    _setLoading(true);
    clearError();

    try {
      final result = await _supplierRepository.updateSupplier(supplier);

      if (result.isSuccess) {
        final index = _suppliers.indexWhere((s) => s.id == supplier.id);
        if (index != -1) {
          _suppliers[index] = result.data!;
          _filteredSuppliers = List.from(_suppliers);
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
      _setError('خطأ في تحديث المورد: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// حذف مورد
  Future<bool> deleteSupplier(int supplierId) async {
    _setLoading(true);
    clearError();

    try {
      final result = await _supplierRepository.deleteSupplier(supplierId);

      if (result.isSuccess) {
        _suppliers.removeWhere((s) => s.id == supplierId);
        _filteredSuppliers = List.from(_suppliers);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('خطأ في حذف المورد: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// تفعيل/إلغاء تفعيل مورد
  Future<bool> toggleSupplierStatus(int supplierId, bool isActive) async {
    _setLoading(true);
    clearError();

    try {
      final result = await _supplierRepository.toggleSupplierStatus(
        supplierId,
        isActive,
      );

      if (result.isSuccess) {
        final index = _suppliers.indexWhere((s) => s.id == supplierId);
        if (index != -1) {
          _suppliers[index] = _suppliers[index].copyWith(isActive: isActive);
          _filteredSuppliers = List.from(_suppliers);
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
      _setError('خطأ في تحديث حالة المورد: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// البحث في الموردين
  Future<void> searchSuppliers(String query) async {
    if (query.trim().isEmpty) {
      _filteredSuppliers = List.from(_suppliers);
      notifyListeners();
      return;
    }

    clearError();

    try {
      final result = await _supplierRepository.searchSuppliers(query);

      if (result.isSuccess) {
        _filteredSuppliers = result.data!;
        notifyListeners();
      } else {
        _setError(result.errorMessage);
      }
    } catch (e) {
      _setError('خطأ في البحث: ${e.toString()}');
    }
  }

  /// تصفية الموردين حسب الحالة
  void filterSuppliersByStatus(bool? isActive) {
    if (isActive == null) {
      _filteredSuppliers = List.from(_suppliers);
    } else {
      _filteredSuppliers = _suppliers
          .where((supplier) => supplier.isActive == isActive)
          .toList();
    }
    notifyListeners();
  }

  /// ترتيب الموردين حسب اسم
  void sortSuppliersByName({bool ascending = true}) {
    _filteredSuppliers.sort((a, b) {
      return ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name);
    });
    notifyListeners();
  }

  /// ترتيب الموردين حسب إجمالي المشتريات
  void sortSuppliersByPurchases({bool ascending = false}) {
    _filteredSuppliers.sort((a, b) {
      return ascending
          ? a.totalPurchases.compareTo(b.totalPurchases)
          : b.totalPurchases.compareTo(a.totalPurchases);
    });
    notifyListeners();
  }

  /// الحصول على مورد بالمعرف
  Future<SupplierModel?> getSupplierById(int id) async {
    try {
      final result = await _supplierRepository.getSupplierById(id);
      return result.isSuccess ? result.data : null;
    } catch (e) {
      _setError('خطأ في جلب المورد: ${e.toString()}');
      return null;
    }
  }

  /// الحصول على أفضل الموردين
  Future<List<SupplierModel>> getTopSuppliers({int limit = 5}) async {
    try {
      final result = await _supplierRepository.getTopSuppliers(limit: limit);
      return result.isSuccess ? result.data! : [];
    } catch (e) {
      _setError('خطأ في جلب أفضل الموردين: ${e.toString()}');
      return [];
    }
  }

  /// جلب إحصائيات الموردين
  Future<bool> loadSupplierStats() async {
    clearError();

    try {
      final result = await _supplierRepository.getSuppliersStats();

      if (result.isSuccess) {
        _supplierStats = result.data!;
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage);
        return false;
      }
    } catch (e) {
      _setError('خطأ في جلب إحصائيات الموردين: ${e.toString()}');
      return false;
    }
  }

  /// تحديث إجمالي المشتريات لمورد
  Future<bool> updateSupplierTotalPurchases(int supplierId) async {
    try {
      final result = await _supplierRepository.updateSupplierTotalPurchases(
        supplierId,
      );

      if (result.isSuccess) {
        // إعادة تحميل المورد لتحديث البيانات
        final updatedSupplier = await getSupplierById(supplierId);
        if (updatedSupplier != null) {
          final index = _suppliers.indexWhere((s) => s.id == supplierId);
          if (index != -1) {
            _suppliers[index] = updatedSupplier;
            _filteredSuppliers = List.from(_suppliers);
            notifyListeners();
          }
        }
        return true;
      } else {
        _setError(result.errorMessage);
        return false;
      }
    } catch (e) {
      _setError('خطأ في تحديث إجمالي المشتريات: ${e.toString()}');
      return false;
    }
  }

  /// عدد الموردين النشطين
  int get activeSuppliersCount {
    return _suppliers.where((supplier) => supplier.isActive).length;
  }

  /// عدد الموردين غير النشطين
  int get inactiveSuppliersCount {
    return _suppliers.where((supplier) => !supplier.isActive).length;
  }

  /// إجمالي المشتريات من جميع الموردين
  double get totalPurchasesAmount {
    return _suppliers.fold(
      0.0,
      (sum, supplier) => sum + supplier.totalPurchases,
    );
  }

  /// متوسط المشتريات لكل مورد
  double get averagePurchasesPerSupplier {
    if (_suppliers.isEmpty) return 0.0;
    return totalPurchasesAmount / _suppliers.length;
  }

  /// الموردين الذين لديهم معلومات اتصال
  List<SupplierModel> get suppliersWithContact {
    return _suppliers.where((supplier) => supplier.hasContactInfo).toList();
  }

  /// إعادة تحميل البيانات
  Future<void> refresh() async {
    await Future.wait([loadSuppliers(), loadSupplierStats()]);
  }

  /// مسح جميع البيانات
  void clear() {
    _suppliers.clear();
    _filteredSuppliers.clear();
    _supplierStats = null;
    clearError();
    notifyListeners();
  }
}
