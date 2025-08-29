import 'package:flutter/material.dart';
import 'package:pos/Model/CustomerModel.dart';
import 'package:pos/Repository/CustomerRepository.dart';
import 'package:pos/Model/SaleModel.dart';

/// مزود حالة العملاء - Customer Provider
/// يدير جميع العمليات المتعلقة بالعملاء في التطبيق
class CustomerProvider extends ChangeNotifier {
  final CustomerRepository _customerRepository = CustomerRepository();

  // قائمة العملاء
  List<CustomerModel> _customers = [];
  List<CustomerModel> _filteredCustomers = [];

  // حالة التحميل والأخطاء
  bool _isLoading = false;
  String? _errorMessage;

  // البحث
  String _searchQuery = '';

  // إحصائيات العملاء
  Map<String, dynamic> _customerStats = {};

  // Getters
  List<CustomerModel> get customers => _customers;
  List<CustomerModel> get filteredCustomers => _filteredCustomers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get customerStats => _customerStats;

  // عدد العملاء
  int get customersCount => _customers.length;
  int get vipCustomersCount => _customers.where((c) => c.isVip).length;

  /// تحميل جميع العملاء
  Future<void> loadCustomers() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _customerRepository.getAllCustomers();

      if (result.isSuccess) {
        _customers = result.data ?? [];
        _applySearch();
        await _loadCustomerStats();
      } else {
        _setError(result.error ?? 'خطأ في تحميل العملاء');
      }
    } catch (e) {
      _setError('خطأ غير متوقع: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// إضافة عميل جديد
  Future<bool> addCustomer(CustomerModel customer) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _customerRepository.addCustomer(customer);

      if (result.isSuccess) {
        await loadCustomers(); // إعادة تحميل القائمة
        return true;
      } else {
        _setError(result.error ?? 'خطأ في إضافة العميل');
        return false;
      }
    } catch (e) {
      _setError('خطأ غير متوقع: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// تحديث عميل موجود
  Future<bool> updateCustomer(CustomerModel customer) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _customerRepository.updateCustomer(customer);

      if (result.isSuccess) {
        await loadCustomers(); // إعادة تحميل القائمة
        return true;
      } else {
        _setError(result.error ?? 'خطأ في تحديث العميل');
        return false;
      }
    } catch (e) {
      _setError('خطأ غير متوقع: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// حذف عميل
  Future<bool> deleteCustomer(int customerId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _customerRepository.deleteCustomer(customerId);

      if (result.isSuccess) {
        await loadCustomers(); // إعادة تحميل القائمة
        return true;
      } else {
        _setError(result.error ?? 'خطأ في حذف العميل');
        return false;
      }
    } catch (e) {
      _setError('خطأ غير متوقع: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// البحث في العملاء
  void searchCustomers(String query) {
    _searchQuery = query.trim();
    _applySearch();
    notifyListeners();
  }

  /// تطبيق البحث على القائمة
  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredCustomers = List.from(_customers);
    } else {
      _filteredCustomers = _customers.where((customer) {
        final name = customer.name.toLowerCase();
        final phone = customer.phone?.toLowerCase() ?? '';
        final email = customer.email?.toLowerCase() ?? '';
        final searchLower = _searchQuery.toLowerCase();

        return name.contains(searchLower) ||
            phone.contains(searchLower) ||
            email.contains(searchLower);
      }).toList();
    }
  }

  /// الحصول على عميل بالمعرف
  Future<CustomerModel?> getCustomerById(int customerId) async {
    try {
      final result = await _customerRepository.getCustomerById(customerId);
      return result.isSuccess ? result.data : null;
    } catch (e) {
      _setError('خطأ في البحث عن العميل: ${e.toString()}');
      return null;
    }
  }

  /// الحصول على عميل برقم الهاتف
  Future<CustomerModel?> getCustomerByPhone(String phone) async {
    try {
      final result = await _customerRepository.getCustomerByPhone(phone);
      return result.isSuccess ? result.data : null;
    } catch (e) {
      _setError('خطأ في البحث عن العميل: ${e.toString()}');
      return null;
    }
  }

  /// تحديث حالة العميل المميز
  Future<bool> updateVipStatus(int customerId, bool isVip) async {
    try {
      final result = await _customerRepository.updateCustomerVipStatus(
        customerId,
        isVip,
      );

      if (result.isSuccess) {
        await loadCustomers(); // إعادة تحميل القائمة
        return true;
      } else {
        _setError(result.error ?? 'خطأ في تحديث حالة العميل المميز');
        return false;
      }
    } catch (e) {
      _setError('خطأ غير متوقع: ${e.toString()}');
      return false;
    }
  }

  /// تحديث نقاط العميل
  Future<bool> updateCustomerPoints(int customerId, int points) async {
    try {
      final result = await _customerRepository.updateCustomerPoints(
        customerId,
        points,
      );

      if (result.isSuccess) {
        await loadCustomers(); // إعادة تحميل القائمة
        return true;
      } else {
        _setError(result.error ?? 'خطأ في تحديث نقاط العميل');
        return false;
      }
    } catch (e) {
      _setError('خطأ غير متوقع: ${e.toString()}');
      return false;
    }
  }

  /// الحصول على أفضل العملاء
  Future<List<CustomerModel>> getTopCustomers({int limit = 10}) async {
    try {
      final result = await _customerRepository.getTopCustomers(limit: limit);
      return result.isSuccess ? (result.data ?? []) : [];
    } catch (e) {
      _setError('خطأ في استرجاع أفضل العملاء: ${e.toString()}');
      return [];
    }
  }

  /// الحصول على العملاء المميزين
  Future<List<CustomerModel>> getVipCustomers() async {
    try {
      final result = await _customerRepository.getVipCustomers();
      return result.isSuccess ? (result.data ?? []) : [];
    } catch (e) {
      _setError('خطأ في استرجاع العملاء المميزين: ${e.toString()}');
      return [];
    }
  }

  /// تحميل إحصائيات العملاء
  Future<void> _loadCustomerStats() async {
    try {
      final result = await _customerRepository.getCustomersStats();
      if (result.isSuccess) {
        _customerStats = result.data ?? {};
      }
    } catch (e) {
      // تجاهل الأخطاء في الإحصائيات
    }
  }

  /// تصفية العملاء حسب النوع
  List<CustomerModel> getCustomersByType(CustomerType type) {
    switch (type) {
      case CustomerType.all:
        return _filteredCustomers;
      case CustomerType.vip:
        return _filteredCustomers.where((c) => c.isVip).toList();
      case CustomerType.regular:
        return _filteredCustomers.where((c) => !c.isVip).toList();
      case CustomerType.withPurchases:
        return _filteredCustomers.where((c) => c.totalPurchases > 0).toList();
      case CustomerType.withoutPurchases:
        return _filteredCustomers.where((c) => c.totalPurchases == 0).toList();
    }
  }

  /// مسح البحث
  void clearSearch() {
    _searchQuery = '';
    _applySearch();
    notifyListeners();
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

  /// مسح جميع البيانات
  void clear() {
    _customers.clear();
    _filteredCustomers.clear();
    _customerStats.clear();
    _searchQuery = '';
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}

/// أنواع العملاء للتصفية
enum CustomerType {
  all, // جميع العملاء
  vip, // العملاء المميزون
  regular, // العملاء العاديون
  withPurchases, // العملاء الذين لديهم مشتريات
  withoutPurchases, // العملاء الذين ليس لديهم مشتريات
}
