import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/ProductProvider.dart';
import 'package:pos/Model/ProductModel.dart';
import 'package:pos/View/Widgets/ProductCard.dart';
import 'package:pos/View/Widgets/AddEditProductDialog.dart';
import 'package:pos/Helper/Constants/AppConstants.dart';

/// شاشة التنبيهات المحسنة
class EnhancedAlertsScreen extends StatefulWidget {
  const EnhancedAlertsScreen({super.key});

  @override
  State<EnhancedAlertsScreen> createState() => _EnhancedAlertsScreenState();
}

class _EnhancedAlertsScreenState extends State<EnhancedAlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    await context.read<ProductProvider>().loadProducts();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تنبيهات المخزون',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.red[700],
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.error), text: 'نافد المخزون'),
            Tab(icon: Icon(Icons.warning), text: 'مخزون منخفض'),
            Tab(icon: Icon(Icons.dangerous), text: 'منتهي الصلاحية'),
            Tab(icon: Icon(Icons.schedule), text: 'قريب الانتهاء'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAlerts),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage.isNotEmpty) {
            return _buildErrorWidget(provider.errorMessage);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOutOfStockTab(provider),
              _buildLowStockTab(provider),
              _buildExpiredTab(provider),
              _buildNearExpiryTab(provider),
            ],
          );
        },
      ),
    );
  }

  /// تبويب المنتجات نافدة المخزون
  Widget _buildOutOfStockTab(ProductProvider provider) {
    final outOfStockProducts = provider.products
        .where((product) => product.isOutOfStock && !product.isArchived)
        .toList();

    return _buildProductsList(
      products: outOfStockProducts,
      emptyMessage: 'لا توجد منتجات نافدة المخزون',
      emptyIcon: Icons.check_circle,
      emptyColor: Colors.green,
      alertType: AlertType.outOfStock,
    );
  }

  /// تبويب المنتجات منخفضة المخزون
  Widget _buildLowStockTab(ProductProvider provider) {
    final lowStockProducts = provider.products
        .where(
          (product) =>
              product.isLowStock &&
              !product.isOutOfStock &&
              !product.isArchived,
        )
        .toList();

    return _buildProductsList(
      products: lowStockProducts,
      emptyMessage: 'لا توجد منتجات منخفضة المخزون',
      emptyIcon: Icons.check_circle,
      emptyColor: Colors.green,
      alertType: AlertType.lowStock,
    );
  }

  /// تبويب المنتجات منتهية الصلاحية
  Widget _buildExpiredTab(ProductProvider provider) {
    final expiredProducts = provider.products
        .where((product) => product.isExpired && !product.isArchived)
        .toList();

    return _buildProductsList(
      products: expiredProducts,
      emptyMessage: 'لا توجد منتجات منتهية الصلاحية',
      emptyIcon: Icons.check_circle,
      emptyColor: Colors.green,
      alertType: AlertType.expired,
    );
  }

  /// تبويب المنتجات قريبة الانتهاء
  Widget _buildNearExpiryTab(ProductProvider provider) {
    final nearExpiryProducts = provider.products
        .where(
          (product) =>
              product.isNearExpiry && !product.isExpired && !product.isArchived,
        )
        .toList();

    return _buildProductsList(
      products: nearExpiryProducts,
      emptyMessage: 'لا توجد منتجات قريبة الانتهاء',
      emptyIcon: Icons.check_circle,
      emptyColor: Colors.green,
      alertType: AlertType.nearExpiry,
    );
  }

  /// بناء قائمة المنتجات
  Widget _buildProductsList({
    required List<ProductModel> products,
    required String emptyMessage,
    required IconData emptyIcon,
    required Color emptyColor,
    required AlertType alertType,
  }) {
    if (products.isEmpty) {
      return _buildEmptyState(emptyMessage, emptyIcon, emptyColor);
    }

    return Column(
      children: [
        // إحصائيات سريعة
        _buildQuickStats(products, alertType),

        // قائمة المنتجات
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAlerts,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  onEdit: () => _showEditDialog(product),
                  onDelete: () => _showArchiveConfirmation(product),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// بناء الإحصائيات السريعة
  Widget _buildQuickStats(List<ProductModel> products, AlertType alertType) {
    final totalQuantity = products.fold<int>(
      0,
      (sum, product) => sum + product.quantity,
    );
    final totalValue = products.fold<double>(
      0,
      (sum, product) => sum + (product.salePrice * product.quantity),
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alertType.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alertType.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(alertType.icon, color: alertType.color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alertType.displayName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: alertType.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${products.length} منتج • $totalQuantity قطعة',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  'القيمة الإجمالية: ${AppConstants.formatCurrency(totalValue)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (alertType == AlertType.lowStock ||
              alertType == AlertType.outOfStock)
            ElevatedButton.icon(
              onPressed: () => _showBulkUpdateDialog(products),
              icon: const Icon(Icons.add_shopping_cart, size: 16),
              label: const Text('تجديد المخزون'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// بناء حالة القائمة الفارغة
  Widget _buildEmptyState(String message, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: color),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'جميع المنتجات في حالة جيدة',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// بناء widget الخطأ
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAlerts,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  /// عرض نافذة تعديل المنتج
  void _showEditDialog(ProductModel product) {
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
        content: Text('هل أنت متأكد من أرشفة المنتج "${product.name}"؟'),
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
                  const SnackBar(
                    content: Text('تم أرشفة المنتج بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadAlerts();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('أرشفة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// عرض نافذة التحديث المجمع للمخزون
  void _showBulkUpdateDialog(List<ProductModel> products) {
    showDialog(
      context: context,
      builder: (context) => BulkStockUpdateDialog(products: products),
    );
  }
}

/// نافذة التحديث المجمع للمخزون
class BulkStockUpdateDialog extends StatefulWidget {
  final List<ProductModel> products;

  const BulkStockUpdateDialog({super.key, required this.products});

  @override
  State<BulkStockUpdateDialog> createState() => _BulkStockUpdateDialogState();
}

class _BulkStockUpdateDialogState extends State<BulkStockUpdateDialog> {
  final Map<int, int> _quantityUpdates = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // تهيئة الكميات الحالية
    for (final product in widget.products) {
      _quantityUpdates[product.id!] = product.quantity;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تجديد المخزون'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            Text(
              'تحديث كميات ${widget.products.length} منتج',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.products.length,
                itemBuilder: (context, index) {
                  final product = widget.products[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'الحالي: ${product.quantity}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              initialValue: _quantityUpdates[product.id!]
                                  .toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'الكمية الجديدة',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (value) {
                                final quantity = int.tryParse(value) ?? 0;
                                _quantityUpdates[product.id!] = quantity;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateQuantities,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('تحديث'),
        ),
      ],
    );
  }

  Future<void> _updateQuantities() async {
    setState(() => _isLoading = true);

    try {
      final provider = context.read<ProductProvider>();
      int successCount = 0;

      for (final product in widget.products) {
        final newQuantity = _quantityUpdates[product.id!] ?? product.quantity;
        if (newQuantity != product.quantity) {
          final updatedProduct = product.copyWith(quantity: newQuantity);
          final success = await provider.updateProduct(updatedProduct);
          if (success) successCount++;
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث $successCount منتج بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التحديث: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
