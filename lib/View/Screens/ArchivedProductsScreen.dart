import 'package:flutter/material.dart';
import 'package:pos/View/style/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/ProductProvider.dart';
import 'package:pos/Model/ProductModel.dart';

/// شاشة المنتجات المؤرشفة
class ArchivedProductsScreen extends StatefulWidget {
  const ArchivedProductsScreen({super.key});

  @override
  State<ArchivedProductsScreen> createState() => _ArchivedProductsScreenState();
}

class _ArchivedProductsScreenState extends State<ArchivedProductsScreen> {
  List<ProductModel> _archivedProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArchivedProducts();
  }

  /// تحميل المنتجات المؤرشفة
  Future<void> _loadArchivedProducts() async {
    setState(() => _isLoading = true);

    final products = await context
        .read<ProductProvider>()
        .getArchivedProducts();

    setState(() {
      _archivedProducts = products;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _archivedProducts.isEmpty
          ? _buildEmptyState()
          : _buildProductsList(screenWidth),
    );
  }

  /// بناء شريط التطبيق
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'الأرشيف',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: AppColors.accent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadArchivedProducts,
        ),
      ],
    );
  }

  /// بناء حالة فارغة
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.archive_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد منتجات مؤرشفة',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'المنتجات المؤرشفة ستظهر هنا',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// بناء قائمة المنتجات
  Widget _buildProductsList(double screenWidth) {
    return RefreshIndicator(
      onRefresh: _loadArchivedProducts,
      child: ListView.builder(
        padding: EdgeInsets.all(screenWidth * 0.04),
        itemCount: _archivedProducts.length,
        itemBuilder: (context, index) {
          final product = _archivedProducts[index];
          return _buildProductCard(product, screenWidth);
        },
      ),
    );
  }

  /// بناء بطاقة المنتج
  Widget _buildProductCard(ProductModel product, double screenWidth) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس البطاقة
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.archive, color: Colors.grey[600], size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الكود: ${product.code}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, product),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'restore',
                      child: Row(
                        children: [
                          Icon(Icons.restore, color: Colors.green),
                          SizedBox(width: 8),
                          Text('استرجاع'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, color: Colors.red),
                          SizedBox(width: 8),
                          Text('حذف نهائي'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('التفاصيل'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // معلومات المنتج
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'الكمية',
                    '${product.quantity}',
                    Icons.numbers,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'سعر البيع',
                    '${product.salePrice.toStringAsFixed(2)} ر.س',
                    Icons.sell,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'الشركة',
                    product.company.isEmpty ? 'غير محدد' : product.company,
                    Icons.business,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'تاريخ الإضافة',
                    product.date,
                    Icons.date_range,
                  ),
                ),
              ],
            ),

            if (product.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  product.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// بناء عنصر المعلومات
  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// التعامل مع إجراءات القائمة
  void _handleMenuAction(String action, ProductModel product) {
    switch (action) {
      case 'restore':
        _showRestoreConfirmation(product);
        break;
      case 'delete':
        _showDeleteConfirmation(product);
        break;
      case 'details':
        _showProductDetails(product);
        break;
    }
  }

  /// عرض تأكيد الاسترجاع
  void _showRestoreConfirmation(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الاسترجاع'),
        content: Text('هل أنت متأكد من استرجاع المنتج "${product.name}"؟'),
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
                  .restoreProduct(product.id!);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم استرجاع المنتج بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadArchivedProducts();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('استرجاع', style: TextStyle(color: Colors.white)),
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
              'تحذير: لا يمكن التراجع عن هذا الإجراء!',
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
                _loadArchivedProducts();
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
            const Icon(Icons.archive, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text(product.name)),
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
              _buildDetailRow('الشركة', product.company),
              _buildDetailRow('تاريخ الإضافة', product.date),
              if (product.expiryDate != null)
                _buildDetailRow(
                  'تاريخ الانتهاء',
                  '${product.expiryDate!.day}/${product.expiryDate!.month}/${product.expiryDate!.year}',
                ),
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
                _loadArchivedProducts();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('استرجاع', style: TextStyle(color: Colors.white)),
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
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }
}
