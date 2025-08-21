import 'package:flutter/material.dart';
import 'package:pos/Helper/Locale/Language.dart';
import 'package:pos/Helper/Service/Service.dart';
import 'package:pos/View/style/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/ProductProvider.dart';
import 'package:pos/Model/ProductModel.dart';
import 'package:pos/View/Widgets/ProductCard.dart';
import 'package:pos/View/Widgets/AddEditProductDialog.dart';
import 'package:smart_sizer/smart_sizer.dart';

/// شاشة إدارة المنتجات
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final screenWidth = MediaQuery.of(context).size.width;
    // final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: DeviceUtils.isMobile(context) ? null: _buildAppBar(),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading && productProvider.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (productProvider.errorMessage.isNotEmpty) {
            return _buildErrorWidget(productProvider);
          }

          return Column(
            children: [
              // شريط البحث والفلاتر
              _buildSearchAndFilters(productProvider, context.screenWidth),

              // إحصائيات سريعة
              _buildQuickStats(
                productProvider,
                context.screenWidth,
                context.screenHeight,
              ),

              // قائمة المنتجات
              Expanded(
                child: _buildProductsList(productProvider, context.screenWidth),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// بناء شريط التطبيق
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'إدارة المنتجات',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
            backgroundColor: AppColors.accent,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        Consumer<ProductProvider>(
          builder: (context, provider, child) {
            return PopupMenuButton<ProductSortType>(
              icon: const Icon(Icons.sort, color: Colors.white),
              onSelected: (sortType) {
                provider.sortProducts(sortType);
              },
              itemBuilder: (context) => ProductSortType.values
                  .map(
                    (type) => PopupMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(
                            _getSortIcon(type),
                            size: 20,
                            color: provider.sortType == type
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).iconTheme.color,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type.displayName,
                            style: TextStyle(
                              color: provider.sortType == type
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).iconTheme.color,
                              fontWeight: provider.sortType == type
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            context.read<ProductProvider>().refreshProducts();
          },
        ),
      ],
    );
  }

  /// بناء شريط البحث والفلاتر
  Widget _buildSearchAndFilters(ProductProvider provider, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(context.getMinSize(4)),
      color: Colors.white,
      child: Column(
        children: [
          // شريط البحث
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: trans[Language.search],
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        provider.searchProducts('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[700]!),
              ),
            ),
            onChanged: (value) {
              provider.searchProducts(value);
            },
          ),

          SizedBox(height: context.getHeight(8)),

          // معلومات الترتيب
          Row(
            children: [
              Icon(Icons.sort, size: 16, color: Colors.grey[600]),
              SizedBox(width: context.getWidth(3)),
              Text(
                '${trans[Language.sortby]} ${provider.sortType.displayName}',
                style: TextStyle(
                  fontSize: context.getFontSize(6),
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(width: context.getWidth(3)),
              Icon(
                provider.sortAscending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 16,
                color: Colors.grey[600],
              ),
              const Spacer(),
              Text(
                '${provider.products.length} ${trans[Language.from]} ${provider.totalProducts}} ${provider.totalProducts} ${trans[Language.product]}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء الإحصائيات السريعة
  Widget _buildQuickStats(
    ProductProvider provider,
    double screenWidth,
    double screenHeight,
  ) {
    final stats = provider.inventoryStats;
    if (stats == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(screenWidth * 0.04),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'إجمالي المنتجات',
              stats.totalProducts.toString(),
              Icons.inventory_2,
              Colors.blue[700]!,
              screenWidth,
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          Expanded(
            child: _buildStatCard(
              'مخزون منخفض',
              stats.lowStockProducts.toString(),
              Icons.warning,
              Colors.orange[700]!,
              screenWidth,
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          Expanded(
            child: _buildStatCard(
              'نافد المخزون',
              stats.outOfStockProducts.toString(),
              Icons.error,
              Colors.red[700]!,
              screenWidth,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة إحصائية
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    double screenWidth,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// بناء قائمة المنتجات
  Widget _buildProductsList(ProductProvider provider, double screenWidth) {
    if (provider.products.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: provider.refreshProducts,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(screenWidth * 0.04),
        itemCount: provider.products.length,
        itemBuilder: (context, index) {
          final product = provider.products[index];
          return ProductCard(
            product: product,
            onEdit: () => _showAddEditDialog(product),
            onDelete: () => _showDeleteConfirmation(product),
            onTap: () => _showProductDetails(product),
          );
        },
      ),
    );
  }

  /// بناء حالة القائمة الفارغة
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد منتجات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة منتجات جديدة',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEditDialog(null),
            icon: const Icon(Icons.add),
            label: const Text('إضافة منتج'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء widget الخطأ
  Widget _buildErrorWidget(ProductProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            provider.errorMessage,
            style: TextStyle(fontSize: 16, color: Colors.red[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              provider.clearError();
              provider.refreshProducts();
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  /// بناء زر الإضافة العائم
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _showAddEditDialog(null),
      backgroundColor: Colors.blue[700],
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  /// عرض نافذة إضافة/تعديل منتج
  void _showAddEditDialog(ProductModel? product) {
    showDialog(
      context: context,
      builder: (context) => AddEditProductDialog(product: product),
    );
  }

  /// عرض تأكيد الحذف
  void _showDeleteConfirmation(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المنتج "${product.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await context
                  .read<ProductProvider>()
                  .deleteProduct(product.id!);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف المنتج بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// عرض تفاصيل المنتج
  void _showProductDetails(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('الكود', product.code),
            _buildDetailRow('الكمية', '${product.quantity}'),
            _buildDetailRow(
              'سعر الشراء',
              '${product.buyPrice.toStringAsFixed(2)} ريال',
            ),
            _buildDetailRow(
              'سعر البيع',
              '${product.salePrice.toStringAsFixed(2)} ريال',
            ),
            _buildDetailRow(
              'الربح للوحدة',
              '${product.profitPerUnit.toStringAsFixed(2)} ريال',
            ),
            _buildDetailRow('الشركة', product.company),
            _buildDetailRow('التاريخ', product.date),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showAddEditDialog(product);
            },
            child: const Text('تعديل'),
          ),
        ],
      ),
    );
  }

  /// بناء صف التفاصيل
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// الحصول على أيقونة الترتيب
  IconData _getSortIcon(ProductSortType type) {
    switch (type) {
      case ProductSortType.name:
        return Icons.sort_by_alpha;
      case ProductSortType.code:
        return Icons.qr_code;
      case ProductSortType.quantity:
        return Icons.numbers;
      case ProductSortType.salePrice:
      case ProductSortType.buyPrice:
        return Icons.attach_money;
      case ProductSortType.profit:
        return Icons.trending_up;
      case ProductSortType.company:
        return Icons.business;
      case ProductSortType.date:
        return Icons.date_range;
    }
  }
}
