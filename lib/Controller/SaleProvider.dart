import 'package:flutter/foundation.dart';
import 'package:pos/Helper/DataBase/DataBaseSqflite.dart';
import 'package:pos/Model/SaleModel.dart';
import 'package:pos/Model/ProductModel.dart';
import 'package:pos/Repository/SaleRepository.dart';
import 'package:pos/Repository/ProductRepository.dart';

/// مزود حالة نقطة البيع - Sale Provider
/// يدير جميع العمليات والحالات المتعلقة بنقطة البيع
class SaleProvider extends ChangeNotifier {
  final SaleRepository _saleRepository;
  final ProductRepository _productRepository;

  // حالة الفاتورة الحالية
  final List<SaleItem> _currentSaleItems = [];
  double _discount = 0.0;
  double _taxRate = 15.0; // 15% ضريبة القيمة المضافة
  String _paymentMethod = 'نقدي';
  double _paidAmount = 0.0;
  String? _customerName;
  String? _customerPhone;
  String? _notes;

  // حالات التطبيق
  bool _isLoading = false;
  String _errorMessage = '';
  List<ProductModel> _availableProducts = [];
  List<Sale> _recentSales = [];
  SalesStats? _salesStats;

  // حالات البحث
  String _productSearchQuery = '';
  List<ProductModel> _filteredProducts = [];

    SaleProvider()
    : _saleRepository = SaleRepository(DataBaseSqflite()),
      _productRepository = ProductRepository(DataBaseSqflite()) {
    _initializeData();
  }

  // Getters للفاتورة الحالية
  List<SaleItem> get currentSaleItems => _currentSaleItems;
  double get discount => _discount;
  double get taxRate => _taxRate;
  String get paymentMethod => _paymentMethod;
  double get paidAmount => _paidAmount;
  String? get customerName => _customerName;
  String? get customerPhone => _customerPhone;
  String? get notes => _notes;

  // Getters للحالات
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<ProductModel> get availableProducts => _availableProducts;
  List<ProductModel> get filteredProducts => _filteredProducts;
  List<Sale> get recentSales => _recentSales;
  SalesStats? get salesStats => _salesStats;
  String get productSearchQuery => _productSearchQuery;

  // حسابات الفاتورة
  double get subtotal {
    return _currentSaleItems.fold(
      0.0,
      (sum, item) => sum + item.calculateTotal(),
    );
  }

  double get taxAmount {
    final afterDiscount = subtotal - _discount;
    return afterDiscount * (_taxRate / 100);
  }

  double get total {
    return subtotal - _discount + taxAmount;
  }

  double get changeAmount {
    return _paidAmount > total ? _paidAmount - total : 0.0;
  }

  bool get canCompleteSale {
    return _currentSaleItems.isNotEmpty && _paidAmount >= total;
  }

  int get itemCount => _currentSaleItems.length;

  int get totalQuantity {
    return _currentSaleItems.fold(0, (sum, item) => sum + item.quantity);
  }

  /// تهيئة البيانات
  Future<void> _initializeData() async {
    await _saleRepository.createSalesTables();
    await loadAvailableProducts();
    await loadRecentSales();
    await loadSalesStats();
  }

  /// تحميل المنتجات المتاحة
  Future<void> loadAvailableProducts() async {
    _setLoading(true);
    try {
      final result = await _productRepository.getAllProducts();
      if (result.isSuccess) {
        _availableProducts = result.data!.where((p) => p.quantity > 0).toList();
        _filteredProducts = List.from(_availableProducts);
      } else {
        _setError(result.error!);
      }
    } catch (e) {
      _setError('خطأ في تحميل المنتجات: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// البحث في المنتجات
  void searchProducts(String query) {
    _productSearchQuery = query.trim();

    if (_productSearchQuery.isEmpty) {
      _filteredProducts = List.from(_availableProducts);
    } else {
      _filteredProducts = _availableProducts.where((product) {
        return product.name.toLowerCase().contains(
              _productSearchQuery.toLowerCase(),
            ) ||
            product.code.toLowerCase().contains(
              _productSearchQuery.toLowerCase(),
            );
      }).toList();
    }

    notifyListeners();
  }

  /// إضافة منتج للفاتورة
  Future<bool> addProductToSale(
    ProductModel product, {
    int quantity = 1,
  }) async {
    try {
      // التحقق من توفر الكمية
      if (product.quantity < quantity) {
        _setError('الكمية المطلوبة غير متوفرة. المتاح: ${product.quantity}');
        return false;
      }

      // البحث عن المنتج في الفاتورة الحالية
      final existingItemIndex = _currentSaleItems.indexWhere(
        (item) => item.productCode == product.code,
      );

      if (existingItemIndex != -1) {
        // تحديث الكمية للمنتج الموجود
        final existingItem = _currentSaleItems[existingItemIndex];
        final newQuantity = existingItem.quantity + quantity;

        if (product.quantity < newQuantity) {
          _setError(
            'الكمية الإجمالية تتجاوز المتاح. المتاح: ${product.quantity}',
          );
          return false;
        }

        final updatedItem = existingItem.copyWith(
          quantity: newQuantity,
          total: product.salePrice * newQuantity,
        );

        _currentSaleItems[existingItemIndex] = updatedItem;
      } else {
        // إضافة منتج جديد
        final saleItem = SaleItem(
          productId: product.id!,
          productCode: product.code,
          productName: product.name,
          unitPrice: product.salePrice,
          quantity: quantity,
          total: product.salePrice * quantity,
        );

        _currentSaleItems.add(saleItem);
      }

      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('خطأ في إضافة المنتج: ${e.toString()}');
      return false;
    }
  }

  /// إضافة منتج بالكود
  Future<bool> addProductByCode(String code, {int quantity = 1}) async {
    try {
      final result = await _productRepository.getProductByCode(code);

      if (result.isSuccess && result.data != null) {
        return await addProductToSale(result.data!, quantity: quantity);
      } else {
        _setError('لم يتم العثور على المنتج بالكود: $code');
        return false;
      }
    } catch (e) {
      _setError('خطأ في البحث عن المنتج: ${e.toString()}');
      return false;
    }
  }

  /// تحديث كمية منتج في الفاتورة
  void updateItemQuantity(int itemIndex, int newQuantity) {
    if (itemIndex < 0 || itemIndex >= _currentSaleItems.length) return;

    if (newQuantity <= 0) {
      removeItemFromSale(itemIndex);
      return;
    }

    final item = _currentSaleItems[itemIndex];
    final updatedItem = item.copyWith(
      quantity: newQuantity,
      total: item.unitPrice * newQuantity,
    );

    _currentSaleItems[itemIndex] = updatedItem;
    notifyListeners();
  }

  /// إزالة منتج من الفاتورة
  void removeItemFromSale(int itemIndex) {
    if (itemIndex >= 0 && itemIndex < _currentSaleItems.length) {
      _currentSaleItems.removeAt(itemIndex);
      notifyListeners();
    }
  }

  /// تطبيق خصم على منتج
  void applyItemDiscount(int itemIndex, double discount) {
    if (itemIndex < 0 || itemIndex >= _currentSaleItems.length) return;

    final item = _currentSaleItems[itemIndex];
    final maxDiscount = item.unitPrice * item.quantity;
    final finalDiscount = discount > maxDiscount ? maxDiscount : discount;

    final updatedItem = item.copyWith(
      discount: finalDiscount,
      total: (item.unitPrice * item.quantity) - finalDiscount,
    );

    _currentSaleItems[itemIndex] = updatedItem;
    notifyListeners();
  }

  /// تطبيق خصم عام على الفاتورة
  void applyGeneralDiscount(double discount) {
    final maxDiscount = subtotal;
    _discount = discount > maxDiscount ? maxDiscount : discount;
    notifyListeners();
  }

  /// تحديث معدل الضريبة
  void updateTaxRate(double rate) {
    _taxRate = rate;
    notifyListeners();
  }

  /// تحديث طريقة الدفع
  void updatePaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  /// تحديث المبلغ المدفوع
  void updatePaidAmount(double amount) {
    _paidAmount = amount;
    notifyListeners();
  }

  /// تحديث بيانات العميل
  void updateCustomerInfo({String? name, String? phone}) {
    _customerName = name;
    _customerPhone = phone;
    notifyListeners();
  }

  /// تحديث الملاحظات
  void updateNotes(String notes) {
    _notes = notes.isEmpty ? null : notes;
    notifyListeners();
  }

  /// إتمام البيع
  Future<bool> completeSale() async {
    if (!canCompleteSale) {
      _setError('لا يمكن إتمام البيع. تحقق من البيانات والمبلغ المدفوع');
      return false;
    }

    _setLoading(true);
    try {
      // توليد رقم فاتورة
      final invoiceResult = await _saleRepository.generateInvoiceNumber();
      if (invoiceResult.isError) {
        _setError(invoiceResult.error!);
        return false;
      }

      // إنشاء الفاتورة
      final saleModel = SaleModel(
        invoiceNumber: invoiceResult.data!,
        createdAt: DateTime.now(),
        items: _currentSaleItems.map((item) {
          return SaleItemModel(
            productId: item.productId,
            productCode: item.productCode,
            productName: item.productName,
            unitPrice: item.unitPrice,
            quantity: item.quantity,
            discount: item.discount,
            total: item.total,
          );
        }).toList(),
        subtotal: subtotal,
        discount: _discount,
        tax: taxAmount,
        total: total,
        paymentMethod: _paymentMethod,
        paidAmount: _paidAmount,
        changeAmount: changeAmount,
        notes: _notes,
        status: 'completed',
      );

      // حفظ الفاتورة
      final saveResult = await _saleRepository.saveSale(saleModel);
      if (saveResult.isError) {
        _setError(saveResult.error!);
        return false;
      }

      // مسح الفاتورة الحالية
      clearCurrentSale();

      // تحديث البيانات
      await loadAvailableProducts();
      await loadRecentSales();
      await loadSalesStats();

      _clearError();
      return true;
    } catch (e) {
      _setError('خطأ في إتمام البيع: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// مسح الفاتورة الحالية
  void clearCurrentSale() {
    _currentSaleItems.clear();
    _discount = 0.0;
    _paidAmount = 0.0;
    _customerName = null;
    _customerPhone = null;
    _notes = null;
    _paymentMethod = 'نقدي';
    notifyListeners();
  }

  /// تحميل المبيعات الأخيرة
  Future<void> loadRecentSales() async {
    try {
      final result = await _saleRepository.getAllSales(limit: 10);
      if (result.isSuccess) {
        _recentSales = result.data!;
      }
    } catch (e) {
      debugPrint('خطأ في تحميل المبيعات الأخيرة: ${e.toString()}');
    }
  }

  /// تحميل إحصائيات المبيعات
  Future<void> loadSalesStats() async {
    try {
      final result = await _saleRepository.getSalesStats();
      if (result.isSuccess) {
        _salesStats = result.data;
      }
    } catch (e) {
      debugPrint('خطأ في تحميل الإحصائيات: ${e.toString()}');
    }
  }

  /// البحث في المبيعات
  Future<List<Sale>> searchSales({
    String? invoiceNumber,
    String? customerName,
    String? customerPhone,
  }) async {
    try {
      final result = await _saleRepository.searchSales(
        invoiceNumber: invoiceNumber,
        customerName: customerName,
        customerPhone: customerPhone,
      );

      if (result.isSuccess) {
        return result.data!;
      } else {
        _setError(result.error!);
        return [];
      }
    } catch (e) {
      _setError('خطأ في البحث: ${e.toString()}');
      return [];
    }
  }

  /// حذف فاتورة
  Future<bool> deleteSale(int saleId) async {
    try {
      final result = await _saleRepository.deleteSale(saleId);

      if (result.isSuccess) {
        await loadRecentSales();
        await loadSalesStats();
        await loadAvailableProducts();
        return true;
      } else {
        _setError(result.error!);
        return false;
      }
    } catch (e) {
      _setError('خطأ في حذف الفاتورة: ${e.toString()}');
      return false;
    }
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
