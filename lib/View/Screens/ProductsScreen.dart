import 'package:flutter/material.dart';
import 'package:pos/Helper/Locale/Language.dart';
import 'package:pos/Helper/Service/Service.dart';
import 'package:pos/View/style/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/ProductProvider.dart';
import 'package:pos/Model/ProductModel.dart';
import 'package:pos/View/Screens/EnhancedAlertsScreen.dart';
import 'package:pos/View/Screens/EnhancedArchivedProductsScreen.dart';
import 'package:pos/View/Screens/InventoryReportsScreen.dart';
import 'package:pos/View/Widgets/ProductCard.dart';
import 'package:pos/View/Widgets/AddEditProductDialog.dart';
import 'package:pos/View/Widgets/EnhancedInventorySummaryCard.dart';
import 'package:pos/View/Widgets/InventoryAlertsWidget.dart';
import 'package:pos/View/Widgets/QuickFiltersWidget.dart';
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
  String _selectedFilter = 'all';

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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: DeviceUtils.isMobile(context) ? null : _buildAppBar(),
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
          
              // الفلاتر السريعة
              QuickFiltersWidget(
                selectedFilter: _selectedFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  _applyFilter(productProvider, filter);
                },
              ),
          
              // تنبيهات المخزون
              InventoryAlertsWidget(products: productProvider.products),
          
              // ملخص المخزون
              EnhancedInventorySummaryCard(
                products: productProvider.products,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InventoryReportsScreen(),
                  ),
                ),
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

  /// تطبيق الفلتر
  void _applyFilter(ProductProvider provider, String filter) {
    switch (filter) {
      case 'all':
        provider.clearFilters();
        break;
      case 'active':
        provider.filterByStatus(isActive: true);
        break;
      case 'out_of_stock':
        provider.filterByStock(isOutOfStock: true);
        break;
      case 'low_stock':
        provider.filterByStock(isLowStock: true);
        break;
      case 'expired':
        provider.filterByExpiry(isExpired: true);
        break;
      case 'near_expiry':
        provider.filterByExpiry(isNearExpiry: true);
        break;
      case 'archived':
        provider.filterByStatus(isArchived: true);
        break;
    }
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
        // زر التنبيهات
        Consumer<ProductProvider>(
          builder: (context, provider, child) {
            final alerts = provider.getAlerts();
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EnhancedAlertsScreen(),
                    ),
                  ),
                ),
                if (alerts.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${alerts.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        // زر التقارير
        IconButton(
          icon: const Icon(Icons.analytics, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InventoryReportsScreen(),
            ),
          ),
        ),

        // زر الأرشيف
        IconButton(
          icon: const Icon(Icons.archive, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EnhancedArchivedProductsScreen(),
            ),
          ),
        ),
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
      child: Column(
        children: [
          // الصف الأول
          Row(
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
          SizedBox(height: screenWidth * 0.02),
          // الصف الثاني
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'قريب الانتهاء',
                  stats.nearExpiryProducts.toString(),
                  Icons.schedule,
                  Colors.amber[700]!,
                  screenWidth,
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: _buildStatCard(
                  'منتهي الصلاحية',
                  stats.expiredProducts.toString(),
                  Icons.dangerous,
                  Colors.red[800]!,
                  screenWidth,
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: _buildStatCard(
                  'مؤرشف',
                  stats.archivedProducts.toString(),
                  Icons.archive,
                  Colors.grey[600]!,
                  screenWidth,
                ),
              ),
            ],
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
            onArchive: () => _showArchiveConfirmation(product),
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

  /// عرض تأكيد الأرشفة
  void _showArchiveConfirmation(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الأرشفة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من أرشفة المنتج "${product.name}"؟'),
            const SizedBox(height: 8),
            const Text(
              'سيتم نقل المنتج إلى الأرشيف ويمكن استرجاعه لاحقاً.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
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
                  .archiveProduct(product.id!);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('تم أرشفة المنتج بنجاح'),
                    backgroundColor: Colors.green,
                    action: SnackBarAction(
                      label: 'تراجع',
                      onPressed: () async {
                        await context.read<ProductProvider>().restoreProduct(
                          product.id!,
                        );
                      },
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('أرشفة', style: TextStyle(color: Colors.white)),
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
                    content: Text('تم حذف المنتج نهائياً'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'حذف نهائي',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// عرض تأكيد الحذف النهائي
  void _showDeleteConfirmation(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف النهائي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من حذف المنتج "${product.name}" نهائياً؟'),
            const SizedBox(height: 8),
            const Text(
              '⚠️ تحذير: لا يمكن التراجع عن هذا الإجراء!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
                    content: Text('تم حذف المنتج نهائياً'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'حذف نهائي',
              style: TextStyle(color: Colors.white),
            ),
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
        title: Row(
          children: [
            Expanded(child: Text(product.name)),
            if (product.isLowStock)
              Icon(Icons.warning, color: Colors.orange, size: 20),
            if (product.isOutOfStock)
              Icon(Icons.error, color: Colors.red, size: 20),
            if (product.isNearExpiry)
              Icon(Icons.schedule, color: Colors.amber, size: 20),
            if (product.isExpired)
              Icon(Icons.dangerous, color: Colors.red[800], size: 20),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('الكود/الباركود', product.code),
              _buildDetailRow(
                'الوصف',
                product.description.isEmpty ? 'غير محدد' : product.description,
              ),
              _buildDetailRow('الكمية', '${product.quantity}'),
              _buildDetailRow('حد التنبيه', '${product.lowStockThreshold}'),
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
              _buildDetailRow(
                'إجمالي قيمة المخزون',
                '${product.totalBuyValue.toStringAsFixed(2)} ريال',
              ),
              _buildDetailRow(
                'إجمالي الربح المتوقع',
                '${product.totalProfit.toStringAsFixed(2)} ريال',
              ),
              _buildDetailRow('الشركة', product.company),
              _buildDetailRow('تاريخ الإضافة', product.date),
              if (product.expiryDate != null)
                _buildDetailRow(
                  'تاريخ الانتهاء',
                  '${product.expiryDate!.day}/${product.expiryDate!.month}/${product.expiryDate!.year}',
                ),
              if (product.daysUntilExpiry != null)
                _buildDetailRow(
                  'الأيام المتبقية',
                  '${product.daysUntilExpiry} يوم',
                ),
              if (product.isArchived)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.archive, color: Colors.grey, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'هذا المنتج مؤرشف',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
          if (product.isArchived)
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await context
                    .read<ProductProvider>()
                    .restoreProduct(product.id!);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم استرجاع المنتج من الأرشيف'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                'استرجاع',
                style: TextStyle(color: Colors.white),
              ),
            ),
          if (!product.isArchived)
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

  /// عرض نافذة التنبيهات
  void _showAlertsDialog(List<ProductAlert> alerts) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.notifications, color: Colors.orange),
            const SizedBox(width: 8),
            Text('التنبيهات (${alerts.length})'),
          ],
        ),
        content: alerts.isEmpty
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 48),
                  SizedBox(height: 16),
                  Text('لا توجد تنبيهات حالياً'),
                ],
              )
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(alert.type.icon, color: alert.type.color),
                        title: Text(
                          alert.type.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: alert.type.color,
                          ),
                        ),
                        subtitle: Text(alert.message),
                        trailing: IconButton(
                          icon: const Icon(Icons.visibility),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showProductDetails(alert.product);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
          if (alerts.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showInventorySummary();
              },
              child: const Text('ملخص المخزون'),
            ),
        ],
      ),
    );
  }

  /// عرض ملخص المخزون
  void _showInventorySummary() {
    showDialog(
      context: context,
      builder: (context) => Consumer<ProductProvider>(
        builder: (context, provider, child) {
          final stats = provider.inventoryStats;
          if (stats == null) {
            return const AlertDialog(
              title: Text('ملخص المخزون'),
              content: Text('لا توجد بيانات متاحة'),
            );
          }

          return AlertDialog(
            title: const Text('ملخص المخزون'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow('عدد المنتجات', '${stats.totalProducts}'),
                  _buildSummaryRow('مخزون منخفض', '${stats.lowStockProducts}'),
                  _buildSummaryRow(
                    'نافد المخزون',
                    '${stats.outOfStockProducts}',
                  ),
                  _buildSummaryRow(
                    'قريب الانتهاء',
                    '${stats.nearExpiryProducts}',
                  ),
                  _buildSummaryRow(
                    'منتهي الصلاحية',
                    '${stats.expiredProducts}',
                  ),
                  _buildSummaryRow('مؤرشف', '${stats.archivedProducts}'),
                  const Divider(),
                  _buildSummaryRow(
                    'إجمالي قيمة المخزون',
                    '${stats.totalInventoryValue.toStringAsFixed(2)} ريال',
                  ),
                  _buildSummaryRow(
                    'إجمالي قيمة البيع',
                    '${stats.totalSaleValue.toStringAsFixed(2)} ريال',
                  ),
                  _buildSummaryRow(
                    'إجمالي الربح المتوقع',
                    '${stats.totalProfitPotential.toStringAsFixed(2)} ريال',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إغلاق'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// بناء صف الملخص
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
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
