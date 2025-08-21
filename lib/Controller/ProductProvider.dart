import 'package:flutter/foundation.dart';
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

  /// البحث في المنتجات
  Future<void> searchProducts(String query) async {
    _searchQuery = query.trim();

    if (_searchQuery.isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      _setLoading(true);

      try {
        final result = await _repository.searchProductsByName(_searchQuery);

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
