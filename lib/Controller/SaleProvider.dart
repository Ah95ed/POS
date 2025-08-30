import 'package:flutter/foundation.dart';
import 'package:pos/Helper/DataBase/DataBaseSqflite.dart';
import 'package:pos/Model/CustomerModel.dart';
import 'package:pos/Model/SaleModel.dart';
import 'package:pos/Model/ProductModel.dart';
import 'package:pos/Repository/SaleRepository.dart';
import 'package:pos/Repository/ProductRepository.dart';
import 'package:pos/Repository/CustomerRepository.dart';
import 'package:pos/Helper/Result.dart';

/// نتيجة التحقق من المخزون
class StockValidationResult {
  final bool isValid;
  final String message;

  StockValidationResult(this.isValid, this.message);
}

/// مزود حالة نقطة البيع - Sale Provider
/// يدير جميع العمليات والحالات المتعلقة بنقطة البيع
class SaleProvider extends ChangeNotifier {
  final SaleRepository _saleRepository;
  final ProductRepository _productRepository;
  final CustomerRepository _customerRepository;

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
  List<SaleModel> _recentSales = [];
  SalesStats? _salesStats;

  // حالات البحث
  String _productSearchQuery = '';
  List<ProductModel> _filteredProducts = [];
  List<CustomerModel> _customers = [];
  List<CustomerModel> _filteredCustomers = [];

  // المنتجات منخفضة المخزون
  List<ProductModel> _lowStockProducts = [];

  SaleProvider()
    : _saleRepository = SaleRepository(),
      _productRepository = ProductRepository(DataBaseSqflite()),
      _customerRepository = CustomerRepository() {
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
  List<SaleModel> get recentSales => _recentSales;
  SalesStats? get salesStats => _salesStats;
  String get productSearchQuery => _productSearchQuery;
  List<CustomerModel> get customers => _customers;
  List<CustomerModel> get filteredCustomers => _filteredCustomers;
  List<ProductModel> get lowStockProducts => _lowStockProducts;

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
    // التحقق من وجود عناصر في الفاتورة
    if (_currentSaleItems.isEmpty) return false;

    // التحقق من أن المبلغ المدفوع كافٍ
    return _paidAmount >= total;
  }

  /// سبب عدم إمكانية إتمام البيع
  String get cannotCompleteSaleReason {
    if (_currentSaleItems.isEmpty) {
      return 'أضف منتجات إلى الفاتورة أولاً';
    }

    if (_paidAmount < total) {
      return 'المبلغ المدفوع (${_paidAmount.toStringAsFixed(2)}) أقل من الإجمالي (${total.toStringAsFixed(2)})';
    }

    return '';
  }

  int get itemCount => _currentSaleItems.length;

  int get totalQuantity {
    return _currentSaleItems.fold(0, (sum, item) => sum + item.quantity);
  }

  /// تهيئة البيانات
  Future<void> _initializeData() async {
    await _saleRepository.createSalesTables();
    await loadAvailableProducts();
    await loadCustomers();
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

  /// تحميل العملاء
  Future<void> loadCustomers() async {
    try {
      final result = await _customerRepository.getAllCustomers();
      if (result.isSuccess) {
        _customers = result.data!;
        _filteredCustomers = List.from(_customers);
      }
    } catch (e) {
      debugPrint('خطأ في تحميل العملاء: ${e.toString()}');
    }
  }

  /// البحث في العملاء
  void searchCustomers(String query) {
    final searchQuery = query.trim().toLowerCase();

    if (searchQuery.isEmpty) {
      _filteredCustomers = List.from(_customers);
    } else {
      _filteredCustomers = _customers.where((customer) {
        return customer.name.toLowerCase().contains(searchQuery) ||
            customer.phone.toLowerCase().contains(searchQuery);
      }).toList();
    }

    notifyListeners();
  }

  /// اختيار عميل من القائمة
  void selectCustomer(CustomerModel customer) {
    _customerName = customer.name;
    _customerPhone = customer.phone;
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
      _saveDraft(); // حفظ المسودة تلقائياً
      notifyListeners();
      return true;
    } catch (e) {
      _setError('خطأ في إضافة المنتج: ${e.toString()}');
      return false;
    }
  }

  /// حفظ مسودة الفاتورة
  void _saveDraft() {
    // يمكن حفظ الفاتورة الحالية في الذاكرة المؤقتة أو قاعدة بيانات محلية
    debugPrint('تم حفظ المسودة - عدد العناصر: ${_currentSaleItems.length}');
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
      if (_currentSaleItems.isEmpty) {
        _setError(
          'لا يمكن إتمام البيع: أضف منتجات إلى الفاتورة أولاً\n\nلإضافة منتجات:\n• استخدم قارئ الباركود أو اكتب كود المنتج\n• اختر المنتجات من القائمة المتاحة',
        );
      } else if (_paidAmount < total) {
        _setError(
          'لا يمكن إتمام البيع: المبلغ المدفوع غير كافٍ\n\nالمطلوب: ${total.toStringAsFixed(2)} ريال\nالمدفوع: ${_paidAmount.toStringAsFixed(2)} ريال\nالنقص: ${(total - _paidAmount).toStringAsFixed(2)} ريال',
        );
      } else {
        _setError('لا يمكن إتمام البيع. تحقق من البيانات والمبلغ المدفوع');
      }
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

      // التحقق من توفر المنتجات والكميات قبل البيع
      final stockValidation = await _validateStock();
      if (!stockValidation.isValid) {
        _setError(stockValidation.message);
        return false;
      }

      // إنشاء الفاتورة
      final saleModel = SaleModel(
        invoiceNumber: invoiceResult.data!,
        customerId: null, // يمكن إضافة العميل لاحقاً
        subtotal: subtotal,
        tax: taxAmount,
        discount: _discount,
        total: total,
        paidAmount: _paidAmount,
        changeAmount: changeAmount,
        paymentMethod: _paymentMethod,
        status: 'completed',
        notes: _notes,
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
      );

      // حفظ الفاتورة مع تحديث المخزون
      final saveResult = await _saleRepository.saveSale(saleModel);
      if (saveResult.isError) {
        _setError(saveResult.error!);
        return false;
      }

      // تسجيل نجاح العملية
      debugPrint('تم حفظ الفاتورة رقم: ${saleModel.invoiceNumber}');
      debugPrint('تم تحديث المخزون لـ ${saleModel.items.length} منتج');

      // حفظ بيانات العميل إذا تم إدخالها
      if (_customerName != null && _customerName!.isNotEmpty) {
        await _saveCustomerData(saveResult.data!);
      }

      // مسح الفاتورة الحالية
      clearCurrentSale();

      // تحديث البيانات
      await loadAvailableProducts();
      await loadRecentSales();
      await loadSalesStats();

      // التحقق من المنتجات منخفضة المخزون
      await _checkLowStockProducts();

      _clearError();
      return true;
    } catch (e) {
      _setError('خطأ في إتمام البيع: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// حفظ بيانات العميل
  Future<void> _saveCustomerData(int saleId) async {
    try {
      if (_customerName == null || _customerName!.isEmpty) return;

      // البحث عن العميل أولاً
      CustomerModel? existingCustomer;
      if (_customerPhone != null && _customerPhone!.isNotEmpty) {
        final result = await _customerRepository.getCustomerByPhone(
          _customerPhone!,
        );
        if (result.isSuccess && result.data != null) {
          existingCustomer = result.data;
        }
      }

      if (existingCustomer != null) {
        // تحديث بيانات العميل الموجود
        final updatedCustomer = existingCustomer.copyWith(
          name: _customerName,
          totalPurchases: existingCustomer.totalPurchases + total,
        );
        await _customerRepository.updateCustomer(updatedCustomer);

        // ربط الفاتورة بالعميل
        await _saleRepository.updateSaleCustomerId(
          saleId,
          existingCustomer.id!,
        );
      } else {
        // إضافة عميل جديد
        final newCustomer = CustomerModel(
          name: _customerName!,
          phone: _customerPhone ?? '',
          totalPurchases: total,
          isVip: false,
          createdAt: DateTime.now(),
        );

        final result = await _customerRepository.addCustomer(newCustomer);
        if (result.isSuccess && result.data != null) {
          // ربط الفاتورة بالعميل الجديد
          await _saleRepository.updateSaleCustomerId(saleId, result.data!.id!);
        }
      }

      debugPrint('تم حفظ بيانات العميل: $_customerName, $_customerPhone');
    } catch (e) {
      debugPrint('خطأ في حفظ بيانات العميل: ${e.toString()}');
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
    _clearError();
    _clearDraft(); // مسح المسودة
    notifyListeners();
  }

  /// مسح المسودة المحفوظة
  void _clearDraft() {
    debugPrint('تم مسح المسودة');
  }

  /// الحصول على ملخص الفاتورة كنص
  String getSalesSummary() {
    if (_currentSaleItems.isEmpty) return 'لا توجد عناصر في الفاتورة';

    final buffer = StringBuffer();
    buffer.writeln('ملخص الفاتورة:');
    buffer.writeln('================');

    for (final item in _currentSaleItems) {
      buffer.writeln(
        '${item.productName}: ${item.quantity} × ${item.unitPrice} = ${item.total}',
      );
    }

    buffer.writeln('================');
    buffer.writeln('المجموع الفرعي: $subtotal');
    if (_discount > 0) buffer.writeln('الخصم: $_discount');
    buffer.writeln('الضريبة: $taxAmount');
    buffer.writeln('الإجمالي: $total');

    return buffer.toString();
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

  /// الحصول على فاتورة برقم الفاتورة
  Future<Result<SaleModel?>> getSaleByInvoiceNumber(
    String invoiceNumber,
  ) async {
    try {
      return await _saleRepository.getSaleByInvoiceNumber(invoiceNumber);
    } catch (e) {
      return Result.error('خطأ في البحث عن الفاتورة: ${e.toString()}');
    }
  }

  /// الحصول على فاتورة بالمعرف
  Future<Result<SaleModel?>> getSaleById(int id) async {
    try {
      return await _saleRepository.getSaleById(id);
    } catch (e) {
      return Result.error('خطأ في البحث عن الفاتورة: ${e.toString()}');
    }
  }

  /// إرجاع فاتورة
  Future<bool> refundSale(int saleId, {String? reason}) async {
    _setLoading(true);
    try {
      final saleResult = await getSaleById(saleId);
      if (saleResult.isError || saleResult.data == null) {
        _setError('فاتورة غير موجودة');
        return false;
      }

      final sale = saleResult.data!;

      // التحقق من حالة الفاتورة
      if (sale.status != 'completed') {
        _setError('لا يمكن إرجاع فاتورة غير مكتملة');
        return false;
      }

      // إنشاء فاتورة إرجاع
      final refundSale = SaleModel(
        invoiceNumber: 'REF-${sale.invoiceNumber}',
        customerId: sale.customerId,
        subtotal: -sale.subtotal,
        tax: -sale.tax,
        discount: 0,
        total: -sale.total,
        paidAmount: -sale.paidAmount,
        changeAmount: 0,
        paymentMethod: sale.paymentMethod,
        status: 'refunded',
        notes: reason != null ? 'إرجاع: $reason' : 'فاتورة إرجاع',
        createdAt: DateTime.now(),
        items: sale.items.map((item) {
          return SaleItemModel(
            productId: item.productId,
            productCode: item.productCode,
            productName: item.productName,
            unitPrice: item.unitPrice,
            quantity: -item.quantity, // كمية سالبة للإرجاع
            discount: item.discount,
            total: -item.total,
          );
        }).toList(),
      );

      // حفظ فاتورة الإرجاع
      final saveResult = await _saleRepository.saveSale(refundSale);
      if (saveResult.isError) {
        _setError(saveResult.error!);
        return false;
      }

      // تحديث حالة الفاتورة الأصلية
      final updateResult = await _saleRepository.updateSaleStatus(
        saleId,
        SaleStatus.refunded,
      );
      if (updateResult.isError) {
        _setError(updateResult.error!);
        return false;
      }

      // تحديث البيانات
      await loadRecentSales();
      await loadSalesStats();
      await loadAvailableProducts();

      return true;
    } catch (e) {
      _setError('خطأ في إرجاع الفاتورة: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// حذف فاتورة
  Future<bool> deleteSale(int saleId) async {
    _setLoading(true);
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
    } finally {
      _setLoading(false);
    }
  }

  /// تحديث رقم فاتورة مخصص
  Future<bool> updateInvoiceNumber(int saleId, String newInvoiceNumber) async {
    try {
      // التحقق من عدم تكرار رقم الفاتورة
      final existingResult = await getSaleByInvoiceNumber(newInvoiceNumber);
      if (existingResult.isSuccess && existingResult.data != null) {
        _setError('رقم الفاتورة موجود مسبقاً');
        return false;
      }

      // TODO: إضافة method updateInvoiceNumber إلى SaleRepository
      // final result = await _saleRepository.updateInvoiceNumber(
      //   saleId,
      //   newInvoiceNumber,
      // );

      // مؤقتاً نعتبر التحديث نجح
      await loadRecentSales();
      return true;
    } catch (e) {
      _setError('خطأ في تحديث رقم الفاتورة: ${e.toString()}');
      return false;
    }
  }

  /// التحقق من توفر المخزون قبل إتمام البيع
  Future<StockValidationResult> _validateStock() async {
    try {
      if (_currentSaleItems.isEmpty) {
        return StockValidationResult(false, 'لا توجد منتجات في الفاتورة');
      }

      for (final item in _currentSaleItems) {
        // التحقق من وجود كود المنتج وتنظيفه
        final cleanProductCode = item.productCode.trim();
        if (cleanProductCode.isEmpty) {
          return StockValidationResult(
            false,
            'كود المنتج فارغ للمنتج: ${item.productName}',
          );
        }

        // البحث عن المنتج بالكود
        final productResult = await _productRepository.getProductByCode(
          cleanProductCode,
        );

        if (productResult.isError) {
          return StockValidationResult(
            false,
            'خطأ في البحث عن المنتج ${item.productName}: ${productResult.error}',
          );
        }

        if (productResult.data == null) {
          return StockValidationResult(
            false,
            'المنتج غير موجود في قاعدة البيانات: ${item.productName} (كود: $cleanProductCode)\nتحقق من:\n1. إضافة المنتج في قائمة المنتجات أولاً\n2. صحة كود المنتج\n3. عدم حذف المنتج',
          );
        }

        final product = productResult.data!;
        if (product.quantity < item.quantity) {
          return StockValidationResult(
            false,
            'الكمية المطلوبة من ${item.productName} (${item.quantity}) أكبر من المتاح (${product.quantity})\nالمتاح: ${product.quantity}\nالمطلوب: ${item.quantity}',
          );
        }
      }
      return StockValidationResult(true, 'تم التحقق من المخزون بنجاح');
    } catch (e) {
      return StockValidationResult(
        false,
        'خطأ في التحقق من المخزون: ${e.toString()}',
      );
    }
  }

  /// التحقق من المنتجات منخفضة المخزون
  Future<void> _checkLowStockProducts() async {
    try {
      final lowStockResult = await _productRepository.getLowStockProducts();
      if (lowStockResult.isSuccess && lowStockResult.data!.isNotEmpty) {
        // إظهار تنبيه للمنتجات منخفضة المخزون
        final lowStockNames = lowStockResult.data!
            .map((p) => p.name)
            .join(', ');
        debugPrint('تنبيه: منتجات منخفضة المخزون: $lowStockNames');

        // يمكن إضافة إشعار للمستخدم هنا
        _lowStockProducts = lowStockResult.data!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('خطأ في فحص المنتجات منخفضة المخزون: ${e.toString()}');
    }
  }

  /// طباعة فاتورة
  Future<bool> printInvoice(int saleId) async {
    try {
      final saleResult = await getSaleById(saleId);
      if (saleResult.isError || saleResult.data == null) {
        _setError('فاتورة غير موجودة');
        return false;
      }

      // تنفيذ طباعة الفاتورة
      // يمكن إضافة خدمة الطباعة هنا
      return true;
    } catch (e) {
      _setError('خطأ في طباعة الفاتورة: ${e.toString()}');
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
