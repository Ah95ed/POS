import 'package:flutter/foundation.dart';
import 'package:pos/Helper/DataBase/DataBaseSqflite.dart';
import 'package:pos/Helper/DataBase/POSDatabase.dart';
import 'package:pos/Model/ProductModel.dart';
import 'package:pos/Model/SaleModel.dart';
import 'package:pos/Repository/CustomerRepository.dart';
import 'package:pos/Repository/ProductRepository.dart';
import 'package:pos/Repository/SalesRepository.dart';

/// مزود حالة نقطة البيع - POS Provider
/// يدير جميع العمليات والحالات المتعلقة بنقطة البيع
class POSProvider extends ChangeNotifier {
  final SalesRepository _salesRepository;
  final ProductRepository _productRepository;
  final CustomerRepository _customerRepository;

  // حالة التحميل والأخطاء
  bool _isLoading = false;
  String _errorMessage = '';

  // بيانات الفاتورة الحالية
  final List<SaleItemModel> _currentSaleItems = [];
  CustomerModel? _selectedCustomer;
  String _paymentMethod = 'cash';
  double _discount = 0.0;
  double _tax = 0.0;
  String _notes = '';
  String _customerName = '';
  String _customerPhone = '';

  // بيانات المنتجات والعملاء
  List<ProductModel> _products = [];
  List<CustomerModel> _customers = [];
  List<PaymentMethodModel> _paymentMethods = [];

  // إحصائيات
  SalesStats? _todayStats;

  POSProvider()
    : _salesRepository = SalesRepository(),
      _productRepository = ProductRepository(DataBaseSqflite()),
      _customerRepository = CustomerRepository() {
    _initializeData();
  }

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<SaleItemModel> get currentSaleItems => _currentSaleItems;
  CustomerModel? get selectedCustomer => _selectedCustomer;
  String get paymentMethod => _paymentMethod;
  double get discount => _discount;
  double get tax => _tax;
  String get notes => _notes;
  List<ProductModel> get products => _products;
  List<CustomerModel> get customers => _customers;
  List<PaymentMethodModel> get paymentMethods => _paymentMethods;
  SalesStats? get todayStats => _todayStats;

  // حسابات الفاتورة
  double get subtotal {
    return _currentSaleItems.fold(0.0, (sum, item) => sum + item.total);
  }

  double get taxAmount {
    return subtotal * (_tax / 100);
  }

  double get discountAmount {
    return subtotal * (_discount / 100);
  }

  double get total {
    return subtotal + taxAmount - discountAmount;
  }

  int get totalItems {
    return _currentSaleItems.fold(0, (sum, item) => sum + item.quantity);
  }

  bool get hasItems => _currentSaleItems.isNotEmpty;

  /// تهيئة البيانات الأولية
  Future<void> _initializeData() async {
    await loadProducts();
    await loadCustomers();
    await loadPaymentMethods();
    await loadTodayStats();
  }

  /// تحميل المنتجات
  Future<void> loadProducts() async {
    _setLoading(true);
    try {
      final result = await _productRepository.getAllProducts();
      if (result.isSuccess) {
        _products = result.data!;
      } else {
        _setError(result.error!);
      }
    } catch (e) {
      _setError('خطأ في تحميل المنتجات: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// تحميل العملاء
  Future<void> loadCustomers() async {
    try {
      final result = await _customerRepository.getAllCustomers();
      if (result.isSuccess) {
        _customers = result.data!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('خطأ في تحميل العملاء: ${e.toString()}');
    }
  }

  /// تحميل طرق الدفع
  Future<void> loadPaymentMethods() async {
    try {
      final db = await POSDatabase.database;
      if (db != null) {
        final data = await db.query(
          POSDatabase.paymentMethodsTable,
          where: '${POSDatabase.paymentIsActive} = ?',
          whereArgs: [1],
        );
        _paymentMethods = data
            .map((item) => PaymentMethodModel.fromMap(item))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('خطأ في تحميل طرق الدفع: ${e.toString()}');
    }
  }

  /// تحميل إحصائيات اليوم
  Future<void> loadTodayStats() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final result = await _salesRepository.getSalesStats(
        startDate: startOfDay,
        endDate: endOfDay,
      );

      if (result.isSuccess) {
        _todayStats = result.data;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('خطأ في تحميل إحصائيات اليوم: ${e.toString()}');
    }
  }

  /// إضافة منتج للفاتورة
  void addProductToSale(ProductModel product, {int quantity = 1}) {
    if (product.quantity < quantity) {
      _setError('الكمية المطلوبة غير متوفرة في المخزون');
      return;
    }

    final existingItemIndex = _currentSaleItems.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingItemIndex != -1) {
      // تحديث الكمية للمنتج الموجود
      final existingItem = _currentSaleItems[existingItemIndex];
      final newQuantity = existingItem.quantity + quantity;

      if (product.quantity < newQuantity) {
        _setError('الكمية المطلوبة تتجاوز المتوفر في المخزون');
        return;
      }

      final updatedItem = existingItem.copyWith(
        quantity: newQuantity,
        total: product.salePrice * newQuantity,
      );

      _currentSaleItems[existingItemIndex] = updatedItem;
    } else {
      // إضافة منتج جديد
      final saleItem = SaleItemModel(
        productId: product.id!,
        productName: product.name,
        productCode: product.code,
        quantity: quantity,
        unitPrice: product.salePrice,
        discount: 0.0,
        total: product.salePrice * quantity,
      );

      _currentSaleItems.add(saleItem);
    }

    _clearError();
    notifyListeners();
  }

  /// تحديث كمية منتج في الفاتورة
  void updateItemQuantity(int productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItemFromSale(productId);
      return;
    }

    final itemIndex = _currentSaleItems.indexWhere(
      (item) => item.productId == productId,
    );

    if (itemIndex != -1) {
      final item = _currentSaleItems[itemIndex];
      final product = _products.firstWhere((p) => p.id == productId);

      if (product.quantity < newQuantity) {
        _setError('الكمية المطلوبة تتجاوز المتوفر في المخزون');
        return;
      }

      final updatedItem = item.copyWith(
        quantity: newQuantity,
        total: item.unitPrice * newQuantity - item.discount,
      );

      _currentSaleItems[itemIndex] = updatedItem;
      _clearError();
      notifyListeners();
    }
  }

  /// إزالة منتج من الفاتورة
  void removeItemFromSale(int productId) {
    _currentSaleItems.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  /// تطبيق خصم على منتج
  void applyItemDiscount(int productId, double discountAmount) {
    final itemIndex = _currentSaleItems.indexWhere(
      (item) => item.productId == productId,
    );

    if (itemIndex != -1) {
      final item = _currentSaleItems[itemIndex];
      final maxDiscount = item.unitPrice * item.quantity;

      if (discountAmount > maxDiscount) {
        _setError('قيمة الخصم تتجاوز قيمة المنتج');
        return;
      }

      final updatedItem = item.copyWith(
        discount: discountAmount,
        total: (item.unitPrice * item.quantity) - discountAmount,
      );

      _currentSaleItems[itemIndex] = updatedItem;
      _clearError();
      notifyListeners();
    }
  }

  /// تحديد العميل
  void setCustomer(CustomerModel? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  /// تحديد طريقة الدفع
  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  /// تحديد اسم العميل
  void setCustomerName(String name) {
    _customerName = name;
    notifyListeners();
  }

  /// تحديد رقم هاتف العميل
  void setCustomerPhone(String phone) {
    _customerPhone = phone;
    notifyListeners();
  }

  /// تحديد الخصم العام
  void setDiscount(double discountPercentage) {
    if (discountPercentage < 0 || discountPercentage > 100) {
      _setError('نسبة الخصم يجب أن تكون بين 0 و 100');
      return;
    }
    _discount = discountPercentage;
    _clearError();
    notifyListeners();
  }

  /// تحديد الضريبة
  void setTax(double taxPercentage) {
    if (taxPercentage < 0 || taxPercentage > 100) {
      _setError('نسبة الضريبة يجب أن تكون بين 0 و 100');
      return;
    }
    _tax = taxPercentage;
    _clearError();
    notifyListeners();
  }

  /// تحديد الملاحظات
  void setNotes(String notes) {
    _notes = notes;
    notifyListeners();
  }

  /// إتمام البيع
  Future<bool> completeSale(double paidAmount) async {
    if (!hasItems) {
      _setError('لا توجد منتجات في الفاتورة');
      return false;
    }

    if (paidAmount < total) {
      _setError('المبلغ المدفوع أقل من إجمالي الفاتورة');
      return false;
    }

    _setLoading(true);

    try {
      // إنشاء رقم فاتورة
      final invoiceResult = await _salesRepository.generateInvoiceNumber();
      if (invoiceResult.isError) {
        _setError(invoiceResult.error!);
        return false;
      }

      // إنشاء المبيعة
      final sale = SaleModel(
        invoiceNumber: invoiceResult.data!,
        customerId: _selectedCustomer?.id,
        subtotal: subtotal,
        tax: taxAmount,
        discount: discountAmount,
        total: total,
        paidAmount: paidAmount,
        changeAmount: paidAmount - total,
        paymentMethod: _paymentMethod,
        status: 'completed',
        notes: _notes.isEmpty ? null : _notes,
        createdAt: DateTime.now(),
        items: _currentSaleItems,
      );

      final result = await _salesRepository.createSale(sale);

      if (result.isSuccess) {
        // إعادة تعيين الفاتورة
        _resetCurrentSale();

        // تحديث البيانات
        await loadProducts();
        await loadTodayStats();

        return true;
      } else {
        _setError(result.error!);
        return false;
      }
    } catch (e) {
      _setError('خطأ في إتمام البيع: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// إلغاء الفاتورة الحالية
  void cancelCurrentSale() {
    _resetCurrentSale();
  }

  /// إعادة تعيين الفاتورة الحالية
  void _resetCurrentSale() {
    _currentSaleItems.clear();
    _selectedCustomer = null;
    _paymentMethod = 'cash';
    _discount = 0.0;
    _tax = 0.0;
    _notes = '';
    _customerName = '';
    _customerPhone = '';
    _clearError();
    notifyListeners();
  }

  /// البحث في المنتجات
  List<ProductModel> searchProducts(String query) {
    if (query.isEmpty) return _products;

    return _products.where((product) {
      return product.name.toLowerCase().contains(query.toLowerCase()) ||
          product.code.toLowerCase().contains(query.toLowerCase()) ||
          product.company.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// البحث في العملاء
  List<CustomerModel> searchCustomers(String query) {
    if (query.isEmpty) return _customers;

    return _customers.where((customer) {
      return customer.name.toLowerCase().contains(query.toLowerCase()) ||
          (customer.phone?.contains(query) ?? false);
    }).toList();
  }

  /// الحصول على منتج بالكود
  ProductModel? getProductByCode(String code) {
    try {
      return _products.firstWhere((product) => product.code == code);
    } catch (e) {
      return null;
    }
  }

  /// تحديث البيانات
  Future<void> refreshData() async {
    await loadProducts();
    await loadCustomers();
    await loadTodayStats();
  }

  /// مسح رسالة الخطأ
  void clearError() {
    _clearError();
    notifyListeners();
  }

  /// دوال مساعدة لإدارة الحالة
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }
}
