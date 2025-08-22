import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pos/Helper/DataBase/DataBaseSqflite.dart';
import 'package:pos/Model/ProductModel.dart';
import 'package:pos/Repository/ProductRepository.dart';

/// مزود حالة المنتجات - Product Provider
/// يدير جميع العمليات والحالات المتعلقة بالمنتجات
class ProductProvider extends ChangeNotifier {
  final ProductRepository _repository;

  // الحالات الأساسية
  bool _isLoading = false;
  String _errorMessage = '';
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  InventoryStats? _inventoryStats;

  // حالات البحث والفلترة
  String _searchQuery = '';
  ProductSortType _sortType = ProductSortType.name;
  bool _sortAscending = true;

  // حالات التصفح
  int _currentPage = 0;
  final int _itemsPerPage = 20;
  bool _hasMoreData = true;

  ProductProvider() : _repository = ProductRepository(DataBaseSqflite()) {
    _initializeData();
  }

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<ProductModel> get products => _filteredProducts;
  List<ProductModel> get allProducts => _products;
  InventoryStats? get inventoryStats => _inventoryStats;
  String get searchQuery => _searchQuery;
  ProductSortType get sortType => _sortType;
  bool get sortAscending => _sortAscending;
  bool get hasMoreData => _hasMoreData;
  int get totalProducts => _products.length;

  /// تهيئة البيانات الأولية
  Future<void> _initializeData() async {
    await loadProducts();
    await _calculateStats();
  }

  /// تحميل جميع المنتجات
  Future<void> loadProducts() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _repository.getAllProducts();

      if (result.isSuccess) {
        _products = result.data!;
        _applyFiltersAndSort();
        await _calculateStats();
      } else {
        _setError(result.error!);
      }
    } catch (e) {
      _setError('خطأ غير متوقع: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// تحديث البيانات
  Future<void> refreshProducts() async {
    _currentPage = 0;
    _hasMoreData = true;
    await loadProducts();
  }

  /// إضافة منتج جديد
  Future<bool> addProduct(ProductModel product) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _repository.addProduct(product);

      if (result.isSuccess) {
        await loadProducts(); // إعادة تحميل البيانات
        return true;
      } else {
        _setError(result.error!);
        return false;
      }
    } catch (e) {
      _setError('خطأ في إضافة المنتج: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// تحديث منتج موجود
  Future<bool> updateProduct(ProductModel product) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _repository.updateProduct(product);

      if (result.isSuccess) {
        await loadProducts(); // إعادة تحميل البيانات
        return true;
      } else {
        _setError(result.error!);
        return false;
      }
    } catch (e) {
      _setError('خطأ في تحديث المنتج: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// حذف منتج
  Future<bool> deleteProduct(int productId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _repository.deleteProduct(productId);

      if (result.isSuccess) {
        await loadProducts(); // إعادة تحميل البيانات
        return true;
      } else {
        _setError(result.error!);
        return false;
      }
    } catch (e) {
      _setError('خطأ في حذف المنتج: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// البحث في المنتجات بالاسم أو الباركود
  Future<void> searchProducts(String query) async {
    _searchQuery = query.trim();

    if (_searchQuery.isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      _setLoading(true);

      try {
        final result = await _repository.searchProducts(_searchQuery);

        if (result.isSuccess) {
          _filteredProducts = result.data!;
        } else {
          _setError(result.error!);
        }
      } catch (e) {
        _setError('خطأ في البحث: ${e.toString()}');
      } finally {
        _setLoading(false);
      }
    }

    _applySort();
    notifyListeners();
  }

  /// البحث عن منتج بالكود
  Future<ProductModel?> getProductByCode(String code) async {
    try {
      final result = await _repository.getProductByCode(code);

      if (result.isSuccess) {
        return result.data;
      } else {
        _setError(result.error!);
        return null;
      }
    } catch (e) {
      _setError('خطأ في البحث عن المنتج: ${e.toString()}');
      return null;
    }
  }

  /// ترتيب المنتجات
  void sortProducts(ProductSortType sortType, {bool? ascending}) {
    _sortType = sortType;
    if (ascending != null) {
      _sortAscending = ascending;
    } else {
      _sortAscending = !_sortAscending;
    }

    _applySort();
    notifyListeners();
  }

  /// تطبيق الفلاتر والترتيب
  void _applyFiltersAndSort() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = List.from(_products);
    }
    _applySort();
  }

  /// تطبيق الترتيب
  void _applySort() {
    _filteredProducts.sort((a, b) {
      int comparison;

      switch (_sortType) {
        case ProductSortType.name:
          comparison = a.name.compareTo(b.name);
          break;
        case ProductSortType.code:
          comparison = a.code.compareTo(b.code);
          break;
        case ProductSortType.quantity:
          comparison = a.quantity.compareTo(b.quantity);
          break;
        case ProductSortType.salePrice:
          comparison = a.salePrice.compareTo(b.salePrice);
          break;
        case ProductSortType.buyPrice:
          comparison = a.buyPrice.compareTo(b.buyPrice);
          break;
        case ProductSortType.profit:
          comparison = a.profitPerUnit.compareTo(b.profitPerUnit);
          break;
        case ProductSortType.company:
          comparison = a.company.compareTo(b.company);
          break;
        case ProductSortType.date:
          comparison = a.date.compareTo(b.date);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });
  }

  /// الحصول على المنتجات منخفضة المخزون
  Future<List<ProductModel>> getLowStockProducts() async {
    try {
      final result = await _repository.getLowStockProducts();

      if (result.isSuccess) {
        return result.data!;
      } else {
        _setError(result.error!);
        return [];
      }
    } catch (e) {
      _setError('خطأ في استرجاع المنتجات منخفضة المخزون: ${e.toString()}');
      return [];
    }
  }

  /// الحصول على المنتجات نافدة المخزون
  Future<List<ProductModel>> getOutOfStockProducts() async {
    try {
      final result = await _repository.getOutOfStockProducts();

      if (result.isSuccess) {
        return result.data!;
      } else {
        _setError(result.error!);
        return [];
      }
    } catch (e) {
      _setError('خطأ في استرجاع المنتجات نافدة المخزون: ${e.toString()}');
      return [];
    }
  }

  /// تحديث كمية منتج
  Future<bool> updateProductQuantity(int productId, int newQuantity) async {
    try {
      final result = await _repository.updateProductQuantity(
        productId,
        newQuantity,
      );

      if (result.isSuccess) {
        await loadProducts();
        return true;
      } else {
        _setError(result.error!);
        return false;
      }
    } catch (e) {
      _setError('خطأ في تحديث الكمية: ${e.toString()}');
      return false;
    }
  }

  /// حساب الإحصائيات
  Future<void> _calculateStats() async {
    try {
      final result = await _repository.getInventoryStats();

      if (result.isSuccess) {
        _inventoryStats = result.data;
      }
    } catch (e) {
      // لا نعرض خطأ للإحصائيات لأنها ليست حرجة
      debugPrint('خطأ في حساب الإحصائيات: ${e.toString()}');
    }
  }

  /// أرشفة منتج (حذف ناعم)
  Future<bool> archiveProduct(int productId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _repository.archiveProduct(productId);

      if (result.isSuccess) {
        await loadProducts(); // إعادة تحميل البيانات
        return true;
      } else {
        _setError(result.error!);
        return false;
      }
    } catch (e) {
      _setError('خطأ في أرشفة المنتج: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// استرجاع منتج من الأرشيف
  Future<bool> restoreProduct(int productId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _repository.restoreProduct(productId);

      if (result.isSuccess) {
        await loadProducts(); // إعادة تحميل البيانات
        return true;
      } else {
        _setError(result.error!);
        return false;
      }
    } catch (e) {
      _setError('خطأ في استرجاع المنتج: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// الحصول على المنتجات المؤرشفة
  Future<List<ProductModel>> getArchivedProducts() async {
    try {
      final result = await _repository.getArchivedProducts();

      if (result.isSuccess) {
        return result.data!;
      } else {
        _setError(result.error!);
        return [];
      }
    } catch (e) {
      _setError('خطأ في استرجاع المنتجات المؤرشفة: ${e.toString()}');
      return [];
    }
  }

  /// الحصول على المنتجات قريبة الانتهاء
  Future<List<ProductModel>> getNearExpiryProducts() async {
    try {
      final result = await _repository.getNearExpiryProducts();

      if (result.isSuccess) {
        return result.data!;
      } else {
        _setError(result.error!);
        return [];
      }
    } catch (e) {
      _setError('خطأ في استرجاع المنتجات قريبة الانتهاء: ${e.toString()}');
      return [];
    }
  }

  /// الحصول على المنتجات منتهية الصلاحية
  Future<List<ProductModel>> getExpiredProducts() async {
    try {
      final result = await _repository.getExpiredProducts();

      if (result.isSuccess) {
        return result.data!;
      } else {
        _setError(result.error!);
        return [];
      }
    } catch (e) {
      _setError('خطأ في استرجاع المنتجات منتهية الصلاحية: ${e.toString()}');
      return [];
    }
  }

  /// تحديث حد التنبيه لمنتج
  Future<bool> updateLowStockThreshold(int productId, int newThreshold) async {
    try {
      final result = await _repository.updateLowStockThreshold(
        productId,
        newThreshold,
      );

      if (result.isSuccess) {
        await loadProducts();
        return true;
      } else {
        _setError(result.error!);
        return false;
      }
    } catch (e) {
      _setError('خطأ في تحديث حد التنبيه: ${e.toString()}');
      return false;
    }
  }

  /// التحقق من التنبيهات
  List<ProductAlert> getAlerts() {
    final alerts = <ProductAlert>[];

    for (final product in _products.where((p) => !p.isArchived)) {
      if (product.isOutOfStock) {
        alerts.add(
          ProductAlert(
            type: AlertType.outOfStock,
            product: product,
            message: 'المنتج "${product.name}" نافد المخزون',
          ),
        );
      } else if (product.isLowStock) {
        alerts.add(
          ProductAlert(
            type: AlertType.lowStock,
            product: product,
            message:
                'المنتج "${product.name}" منخفض المخزون (${product.quantity} متبقي)',
          ),
        );
      }

      if (product.isExpired) {
        alerts.add(
          ProductAlert(
            type: AlertType.expired,
            product: product,
            message: 'المنتج "${product.name}" منتهي الصلاحية',
          ),
        );
      } else if (product.isNearExpiry) {
        alerts.add(
          ProductAlert(
            type: AlertType.nearExpiry,
            product: product,
            message:
                'المنتج "${product.name}" قريب الانتهاء (${product.daysUntilExpiry} يوم متبقي)',
          ),
        );
      }
    }

    return alerts;
  }

  /// مسح رسالة الخطأ
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // ===== دوال الفلترة =====

  List<ProductModel> _allProducts = [];

  /// إزالة جميع الفلاتر
  void clearFilters() {
    loadProducts();
  }

  /// فلترة حسب الحالة
  void filterByStatus({bool? isActive, bool? isArchived}) {
    if (_allProducts.isEmpty) {
      _allProducts = List.from(_products);
    }

    List<ProductModel> filteredProducts = List.from(_allProducts);

    if (isActive != null) {
      filteredProducts = filteredProducts
          .where((p) => p.isActive == isActive)
          .toList();
    }

    if (isArchived != null) {
      filteredProducts = filteredProducts
          .where((p) => p.isArchived == isArchived)
          .toList();
    }

    _updateProductsList(filteredProducts);
  }

  /// فلترة حسب المخزون
  void filterByStock({bool? isOutOfStock, bool? isLowStock}) {
    if (_allProducts.isEmpty) {
      _allProducts = List.from(_products);
    }

    List<ProductModel> filteredProducts = List.from(_allProducts);

    if (isOutOfStock == true) {
      filteredProducts = filteredProducts
          .where((p) => p.isOutOfStock && !p.isArchived)
          .toList();
    } else if (isLowStock == true) {
      filteredProducts = filteredProducts
          .where((p) => p.isLowStock && !p.isOutOfStock && !p.isArchived)
          .toList();
    }

    _updateProductsList(filteredProducts);
  }

  /// فلترة حسب انتهاء الصلاحية
  void filterByExpiry({bool? isExpired, bool? isNearExpiry}) {
    if (_allProducts.isEmpty) {
      _allProducts = List.from(_products);
    }

    List<ProductModel> filteredProducts = List.from(_allProducts);

    if (isExpired == true) {
      filteredProducts = filteredProducts
          .where((p) => p.isExpired && !p.isArchived)
          .toList();
    } else if (isNearExpiry == true) {
      filteredProducts = filteredProducts
          .where((p) => p.isNearExpiry && !p.isExpired && !p.isArchived)
          .toList();
    }

    _updateProductsList(filteredProducts);
  }

  /// تحديث قائمة المنتجات
  void _updateProductsList(List<ProductModel> filteredProducts) {
    _products.clear();
    _products.addAll(filteredProducts);
    notifyListeners();
  }

  /// تنظيف الكاش
  void clearCache() {
    _allProducts.clear();
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

/// أنواع ترتيب المنتجات
enum ProductSortType {
  name,
  code,
  quantity,
  salePrice,
  buyPrice,
  profit,
  company,
  date,
}

/// Extension لتحويل نوع الترتيب إلى نص
extension ProductSortTypeExtension on ProductSortType {
  String get displayName {
    switch (this) {
      case ProductSortType.name:
        return 'الاسم';
      case ProductSortType.code:
        return 'الكود';
      case ProductSortType.quantity:
        return 'الكمية';
      case ProductSortType.salePrice:
        return 'سعر البيع';
      case ProductSortType.buyPrice:
        return 'سعر الشراء';
      case ProductSortType.profit:
        return 'الربح';
      case ProductSortType.company:
        return 'الشركة';
      case ProductSortType.date:
        return 'التاريخ';
    }
  }
}

/// نموذج التنبيه للمنتجات
class ProductAlert {
  final AlertType type;
  final ProductModel product;
  final String message;

  const ProductAlert({
    required this.type,
    required this.product,
    required this.message,
  });
}

/// أنواع التنبيهات
enum AlertType { lowStock, outOfStock, nearExpiry, expired }

/// Extension لتحويل نوع التنبيه إلى نص ولون
extension AlertTypeExtension on AlertType {
  String get displayName {
    switch (this) {
      case AlertType.lowStock:
        return 'مخزون منخفض';
      case AlertType.outOfStock:
        return 'نافد المخزون';
      case AlertType.nearExpiry:
        return 'قريب الانتهاء';
      case AlertType.expired:
        return 'منتهي الصلاحية';
    }
  }

  Color get color {
    switch (this) {
      case AlertType.lowStock:
        return Colors.orange;
      case AlertType.outOfStock:
        return Colors.red;
      case AlertType.nearExpiry:
        return Colors.amber;
      case AlertType.expired:
        return Colors.red[800]!;
    }
  }

  IconData get icon {
    switch (this) {
      case AlertType.lowStock:
        return Icons.warning;
      case AlertType.outOfStock:
        return Icons.error;
      case AlertType.nearExpiry:
        return Icons.schedule;
      case AlertType.expired:
        return Icons.dangerous;
    }
  }
}
