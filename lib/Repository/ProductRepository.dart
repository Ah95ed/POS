import 'package:pos/Helper/DataBase/DataBaseSqflite.dart';
import 'package:pos/Model/ProductModel.dart';
import 'package:pos/Helper/Result.dart';

/// مستودع المنتجات - Product Repository
/// يحتوي على جميع العمليات المتعلقة بقاعدة البيانات للمنتجات
class ProductRepository {
  final DataBaseSqflite _database;

  ProductRepository(this._database);

  /// إضافة منتج جديد
  Future<Result<int>> addProduct(ProductModel product) async {
    try {
      // التحقق من صحة البيانات
      if (!product.isValid) {
        return Result.error('بيانات المنتج غير صحيحة');
      }

      // التحقق من عدم تكرار الكود
      final existingProduct = await getProductByCode(product.code);
      if (existingProduct.isSuccess && existingProduct.data != null) {
        return Result.error('كود المنتج موجود مسبقاً');
      }

      final id = await _database.insert(product.toMap());
      return Result.success(id);
    } catch (e) {
      return Result.error('خطأ في إضافة المنتج: ${e.toString()}');
    }
  }

  /// تحديث منتج موجود
  Future<Result<bool>> updateProduct(ProductModel product) async {
    try {
      if (product.id == null) {
        return Result.error('معرف المنتج مطلوب للتحديث');
      }

      if (!product.isValid) {
        return Result.error('بيانات المنتج غير صحيحة');
      }

      final rowsAffected = await _database.updateItem(
        product.toMap(),
        product.id.toString(),
      );

      if (rowsAffected > 0) {
        return Result.success(true);
      } else {
        return Result.error('لم يتم العثور على المنتج للتحديث');
      }
    } catch (e) {
      return Result.error('خطأ في تحديث المنتج: ${e.toString()}');
    }
  }

  /// حذف منتج
  Future<Result<bool>> deleteProduct(int productId) async {
    try {
      final rowsAffected = await _database.delete(productId.toString());

      if (rowsAffected > 0) {
        return Result.success(true);
      } else {
        return Result.error('لم يتم العثور على المنتج للحذف');
      }
    } catch (e) {
      return Result.error('خطأ في حذف المنتج: ${e.toString()}');
    }
  }

  /// الحصول على جميع المنتجات (بما في ذلك المؤرشفة)
  Future<Result<List<ProductModel>>> getAllProducts({
    bool includeArchived = false,
  }) async {
    try {
      final data = await _database.getAllData();
      final products = data
          .where((item) => item != null)
          .map((item) => ProductModel.fromMap(item!))
          .where((product) => includeArchived || !product.isArchived)
          .toList();

      return Result.success(products);
    } catch (e) {
      return Result.error('خطأ في استرجاع المنتجات: ${e.toString()}');
    }
  }

  /// الحصول على المنتجات مع التصفح (Pagination)
  Future<Result<List<ProductModel>>> getProducts({
    required int skip,
    required int limit,
  }) async {
    try {
      final data = await _database.getAllUser(skip, limit);
      final products = data
          .where((item) => item != null)
          .map((item) => ProductModel.fromMap(item!))
          .toList();

      return Result.success(products);
    } catch (e) {
      return Result.error('خطأ في استرجاع المنتجات: ${e.toString()}');
    }
  }

  /// البحث عن منتج بالاسم
  Future<Result<List<ProductModel>>> searchProductsByName(String name) async {
    try {
      if (name.trim().isEmpty) {
        return getAllProducts();
      }

      final data = await _database.searchInDatabase(name.trim());
      final products = data.map((item) => ProductModel.fromMap(item)).toList();

      return Result.success(products);
    } catch (e) {
      return Result.error('خطأ في البحث عن المنتجات: ${e.toString()}');
    }
  }

  /// البحث عن منتج بالكود
  Future<Result<ProductModel?>> getProductByCode(String code) async {
    try {
      if (code.trim().isEmpty) {
        return Result.error('كود المنتج مطلوب');
      }

      final data = await _database.searchInDatabaseCode(code.trim());

      if (data.isNotEmpty) {
        final product = ProductModel.fromMap(data.first);
        return Result.success(product);
      } else {
        return Result.success(null);
      }
    } catch (e) {
      return Result.error('خطأ في البحث عن المنتج: ${e.toString()}');
    }
  }

  /// الحصول على المنتجات منخفضة المخزون
  Future<Result<List<ProductModel>>> getLowStockProducts() async {
    try {
      final allProductsResult = await getAllProducts();

      if (allProductsResult.isError) {
        return Result.error(allProductsResult.error!);
      }

      final lowStockProducts = allProductsResult.data!
          .where((product) => product.isLowStock)
          .toList();

      return Result.success(lowStockProducts);
    } catch (e) {
      return Result.error(
        'خطأ في استرجاع المنتجات منخفضة المخزون: ${e.toString()}',
      );
    }
  }

  /// الحصول على المنتجات نافدة المخزون
  Future<Result<List<ProductModel>>> getOutOfStockProducts() async {
    try {
      final allProductsResult = await getAllProducts();

      if (allProductsResult.isError) {
        return Result.error(allProductsResult.error!);
      }

      final outOfStockProducts = allProductsResult.data!
          .where((product) => product.isOutOfStock)
          .toList();

      return Result.success(outOfStockProducts);
    } catch (e) {
      return Result.error(
        'خطأ في استرجاع المنتجات نافدة المخزون: ${e.toString()}',
      );
    }
  }

  /// الحصول على إحصائيات المخزن
  Future<Result<InventoryStats>> getInventoryStats() async {
    try {
      final allProductsResult = await getAllProducts();

      if (allProductsResult.isError) {
        return Result.error(allProductsResult.error!);
      }

      final stats = InventoryStats.fromProducts(allProductsResult.data!);
      return Result.success(stats);
    } catch (e) {
      return Result.error('خطأ في حساب إحصائيات المخزن: ${e.toString()}');
    }
  }

  /// تحديث كمية منتج
  Future<Result<bool>> updateProductQuantity(
    int productId,
    int newQuantity,
  ) async {
    try {
      // الحصول على المنتج الحالي
      final allProductsResult = await getAllProducts();
      if (allProductsResult.isError) {
        return Result.error(allProductsResult.error!);
      }

      final product = allProductsResult.data!
          .where((p) => p.id == productId)
          .firstOrNull;

      if (product == null) {
        return Result.error('لم يتم العثور على المنتج');
      }

      // تحديث الكمية
      final updatedProduct = product.copyWith(quantity: newQuantity);
      return await updateProduct(updatedProduct);
    } catch (e) {
      return Result.error('خطأ في تحديث كمية المنتج: ${e.toString()}');
    }
  }

  /// تحديث أسعار جميع المنتجات (زيادة أو نقصان)
  Future<Result<bool>> updateAllSalePrices(double adjustment) async {
    try {
      await _database.updateCostCol(adjustment);
      return Result.success(true);
    } catch (e) {
      return Result.error('خطأ في تحديث أسعار البيع: ${e.toString()}');
    }
  }

  /// تحديث أسعار الشراء لجميع المنتجات
  Future<Result<bool>> updateAllBuyPrices(double adjustment) async {
    try {
      await _database.updateBuyCol(adjustment);
      return Result.success(true);
    } catch (e) {
      return Result.error('خطأ في تحديث أسعار الشراء: ${e.toString()}');
    }
  }

  /// أرشفة منتج (حذف ناعم)
  Future<Result<bool>> archiveProduct(int productId) async {
    try {
      // الحصول على المنتج الحالي
      final allProductsResult = await getAllProducts(includeArchived: true);
      if (allProductsResult.isError) {
        return Result.error(allProductsResult.error!);
      }

      final product = allProductsResult.data!
          .where((p) => p.id == productId)
          .firstOrNull;

      if (product == null) {
        return Result.error('لم يتم العثور على المنتج');
      }

      // أرشفة المنتج
      final archivedProduct = product.copyWith(isArchived: true);
      return await updateProduct(archivedProduct);
    } catch (e) {
      return Result.error('خطأ في أرشفة المنتج: ${e.toString()}');
    }
  }

  /// استرجاع منتج من الأرشيف
  Future<Result<bool>> restoreProduct(int productId) async {
    try {
      // الحصول على المنتج المؤرشف
      final allProductsResult = await getAllProducts(includeArchived: true);
      if (allProductsResult.isError) {
        return Result.error(allProductsResult.error!);
      }

      final product = allProductsResult.data!
          .where((p) => p.id == productId && p.isArchived)
          .firstOrNull;

      if (product == null) {
        return Result.error('لم يتم العثور على المنتج في الأرشيف');
      }

      // استرجاع المنتج
      final restoredProduct = product.copyWith(isArchived: false);
      return await updateProduct(restoredProduct);
    } catch (e) {
      return Result.error('خطأ في استرجاع المنتج: ${e.toString()}');
    }
  }

  /// الحصول على المنتجات المؤرشفة
  Future<Result<List<ProductModel>>> getArchivedProducts() async {
    try {
      final allProductsResult = await getAllProducts(includeArchived: true);
      if (allProductsResult.isError) {
        return Result.error(allProductsResult.error!);
      }

      final archivedProducts = allProductsResult.data!
          .where((product) => product.isArchived)
          .toList();

      return Result.success(archivedProducts);
    } catch (e) {
      return Result.error('خطأ في استرجاع المنتجات المؤرشفة: ${e.toString()}');
    }
  }

  /// الحصول على المنتجات قريبة الانتهاء
  Future<Result<List<ProductModel>>> getNearExpiryProducts() async {
    try {
      final allProductsResult = await getAllProducts();
      if (allProductsResult.isError) {
        return Result.error(allProductsResult.error!);
      }

      final nearExpiryProducts = allProductsResult.data!
          .where((product) => product.isNearExpiry)
          .toList();

      return Result.success(nearExpiryProducts);
    } catch (e) {
      return Result.error(
        'خطأ في استرجاع المنتجات قريبة الانتهاء: ${e.toString()}',
      );
    }
  }

  /// الحصول على المنتجات منتهية الصلاحية
  Future<Result<List<ProductModel>>> getExpiredProducts() async {
    try {
      final allProductsResult = await getAllProducts();
      if (allProductsResult.isError) {
        return Result.error(allProductsResult.error!);
      }

      final expiredProducts = allProductsResult.data!
          .where((product) => product.isExpired)
          .toList();

      return Result.success(expiredProducts);
    } catch (e) {
      return Result.error(
        'خطأ في استرجاع المنتجات منتهية الصلاحية: ${e.toString()}',
      );
    }
  }

  /// البحث في المنتجات بالاسم أو الباركود
  Future<Result<List<ProductModel>>> searchProducts(String query) async {
    try {
      if (query.trim().isEmpty) {
        return getAllProducts();
      }

      final searchTerm = query.trim().toLowerCase();

      // البحث بالاسم
      final nameResults = await searchProductsByName(searchTerm);
      if (nameResults.isError) {
        return Result.error(nameResults.error!);
      }

      // البحث بالكود
      final codeResult = await getProductByCode(searchTerm);
      if (codeResult.isError) {
        return Result.error(codeResult.error!);
      }

      // دمج النتائج وإزالة التكرار
      final allResults = <ProductModel>[];
      allResults.addAll(nameResults.data!);

      if (codeResult.data != null &&
          !allResults.any((p) => p.id == codeResult.data!.id)) {
        allResults.add(codeResult.data!);
      }

      return Result.success(allResults);
    } catch (e) {
      return Result.error('خطأ في البحث: ${e.toString()}');
    }
  }

  /// تحديث حد التنبيه لمنتج
  Future<Result<bool>> updateLowStockThreshold(
    int productId,
    int newThreshold,
  ) async {
    try {
      // الحصول على المنتج الحالي
      final allProductsResult = await getAllProducts();
      if (allProductsResult.isError) {
        return Result.error(allProductsResult.error!);
      }

      final product = allProductsResult.data!
          .where((p) => p.id == productId)
          .firstOrNull;

      if (product == null) {
        return Result.error('لم يتم العثور على المنتج');
      }

      // تحديث حد التنبيه
      final updatedProduct = product.copyWith(lowStockThreshold: newThreshold);
      return await updateProduct(updatedProduct);
    } catch (e) {
      return Result.error('خطأ في تحديث حد التنبيه: ${e.toString()}');
    }
  }

  /// تقليل كمية المنتج (للمبيعات)
  Future<Result<bool>> reduceProductQuantity(
    int productId,
    int quantityToReduce,
  ) async {
    try {
      // الحصول على المنتج الحالي
      final allProductsResult = await getAllProducts();
      if (allProductsResult.isError) {
        return Result.error(allProductsResult.error!);
      }

      final product = allProductsResult.data!
          .where((p) => p.id == productId)
          .firstOrNull;

      if (product == null) {
        return Result.error('لم يتم العثور على المنتج');
      }

      // التحقق من توفر الكمية
      if (product.quantity < quantityToReduce) {
        return Result.error(
          'الكمية المطلوبة ($quantityToReduce) أكبر من المتاح (${product.quantity})',
        );
      }

      // حساب الكمية الجديدة
      final newQuantity = product.quantity - quantityToReduce;

      // تحديث الكمية
      final updatedProduct = product.copyWith(quantity: newQuantity);
      return await updateProduct(updatedProduct);
    } catch (e) {
      return Result.error('خطأ في تقليل كمية المنتج: ${e.toString()}');
    }
  }

  /// زيادة كمية المنتج (للمرتجعات أو التزويد)
  Future<Result<bool>> increaseProductQuantity(
    int productId,
    int quantityToAdd,
  ) async {
    try {
      // الحصول على المنتج الحالي
      final allProductsResult = await getAllProducts();
      if (allProductsResult.isError) {
        return Result.error(allProductsResult.error!);
      }

      final product = allProductsResult.data!
          .where((p) => p.id == productId)
          .firstOrNull;

      if (product == null) {
        return Result.error('لم يتم العثور على المنتج');
      }

      // حساب الكمية الجديدة
      final newQuantity = product.quantity + quantityToAdd;

      // تحديث الكمية
      final updatedProduct = product.copyWith(quantity: newQuantity);
      return await updateProduct(updatedProduct);
    } catch (e) {
      return Result.error('خطأ في زيادة كمية المنتج: ${e.toString()}');
    }
  }
}
