import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/ProductProvider.dart';
import 'package:pos/Model/ProductModel.dart';
import 'package:pos/View/Widgets/ProductCard.dart';
import 'package:pos/Helper/Constants/AppConstants.dart';

/// شاشة المنتجات المؤرشفة المحسنة
class EnhancedArchivedProductsScreen extends StatefulWidget {
  const EnhancedArchivedProductsScreen({super.key});

  @override
  State<EnhancedArchivedProductsScreen> createState() =>
      _EnhancedArchivedProductsScreenState();
}

class _EnhancedArchivedProductsScreenState
    extends State<EnhancedArchivedProductsScreen> {
  List<ProductModel> _archivedProducts = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadArchivedProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArchivedProducts() async {
    setState(() => _isLoading = true);

    try {
      final provider = context.read<ProductProvider>();
      final archivedProducts = await provider.getArchivedProducts();

      setState(() {
        _archivedProducts = archivedProducts;
        _filteredProducts = archivedProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المنتجات المؤرشفة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProducts = _archivedProducts;
      } else {
        _filteredProducts = _archivedProducts.where((product) {
          return product.name.toLowerCase().contains(query.toLowerCase()) ||
              product.code.toLowerCase().contains(query.toLowerCase()) ||
              product.company.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'المنتجات المؤرشفة',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.grey[700],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadArchivedProducts,
          ),
          if (_archivedProducts.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'restore_all':
                    _showRestoreAllConfirmation();
                    break;
                  case 'delete_all':
                    _showDeleteAllConfirmation();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'restore_all',
                  child: Row(
                    children: [
                      Icon(Icons.restore, color: Colors.green),
                      SizedBox(width: 8),
                      Text('استرجاع الكل'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever, color: Colors.red),
                      SizedBox(width: 8),
                      Text('حذف نهائي للكل'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث والإحصائيات
          _buildSearchAndStats(),

          // قائمة المنتجات
          Expanded(child: _buildProductsList()),
        ],
      ),
    );
  }

  /// بناء شريط البحث والإحصائيات
  Widget _buildSearchAndStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          // شريط البحث
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'البحث في المنتجات المؤرشفة...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterProducts('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
            ),
            onChanged: _filterProducts,
          ),

          const SizedBox(height: 12),

          // الإحصائيات
          if (_archivedProducts.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'المجموع',
                    '${_archivedProducts.length}',
                    Icons.archive,
                    Colors.grey[700]!,
                  ),
                  _buildStatItem(
                    'المعروض',
                    '${_filteredProducts.length}',
                    Icons.visibility,
                    Colors.blue[700]!,
                  ),
                  _buildStatItem(
                    'القيمة الإجمالية',
                    AppConstants.formatCurrency(_calculateTotalValue()),
                    Icons.attach_money,
                    Colors.green[700]!,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// بناء عنصر الإحصائية
  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  /// بناء قائمة المنتجات
  Widget _buildProductsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_archivedProducts.isEmpty) {
      return _buildEmptyState();
    }

    if (_filteredProducts.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoSearchResults();
    }

    return RefreshIndicator(
      onRefresh: _loadArchivedProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  // شريط الأرشيف
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.archive, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'مؤرشف',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'تاريخ الأرشفة: ${product.date}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // بطاقة المنتج
                  ProductCard(
                    product: product,
                    onEdit: null, // لا يمكن تعديل المنتجات المؤرشفة
                    onDelete: () => _showDeleteConfirmation(product),
                  ),

                  // أزرار الإجراءات
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _restoreProduct(product),
                            icon: const Icon(Icons.restore, size: 16),
                            label: const Text('استرجاع'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showDeleteConfirmation(product),
                            icon: const Icon(Icons.delete_forever, size: 16),
                            label: const Text('حذف نهائي'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
          Icon(Icons.archive_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد منتجات مؤرشفة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
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

  /// بناء حالة عدم وجود نتائج بحث
  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم العثور على منتجات تطابق البحث "$_searchQuery"',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              _filterProducts('');
            },
            child: const Text('مسح البحث'),
          ),
        ],
      ),
    );
  }

  /// حساب القيمة الإجمالية
  double _calculateTotalValue() {
    return _archivedProducts.fold<double>(
      0,
      (sum, product) => sum + (product.salePrice * product.quantity),
    );
  }

  /// استرجاع منتج
  Future<void> _restoreProduct(ProductModel product) async {
    try {
      final success = await context.read<ProductProvider>().restoreProduct(
        product.id!,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم استرجاع "${product.name}" بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _loadArchivedProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في استرجاع المنتج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            Text('هل أنت متأكد من الحذف النهائي للمنتج "${product.name}"؟'),
            const SizedBox(height: 8),
            const Text(
              '⚠️ تحذير: لا يمكن التراجع عن هذا الإجراء!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
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
              // هنا يمكن إضافة دالة الحذف النهائي في المستقبل
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('الحذف النهائي غير متاح حالياً'),
                  backgroundColor: Colors.orange,
                ),
              );
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

  /// عرض تأكيد استرجاع الكل
  void _showRestoreAllConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استرجاع جميع المنتجات'),
        content: Text(
          'هل تريد استرجاع جميع المنتجات المؤرشفة (${_archivedProducts.length} منتج)؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _restoreAllProducts();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'استرجاع الكل',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// عرض تأكيد حذف الكل
  void _showDeleteAllConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف جميع المنتجات نهائياً'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل تريد حذف جميع المنتجات المؤرشفة نهائياً (${_archivedProducts.length} منتج)؟',
            ),
            const SizedBox(height: 8),
            const Text(
              '⚠️ تحذير: لا يمكن التراجع عن هذا الإجراء!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
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
              // هنا يمكن إضافة دالة الحذف النهائي للكل في المستقبل
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('الحذف النهائي غير متاح حالياً'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'حذف نهائي للكل',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// استرجاع جميع المنتجات
  Future<void> _restoreAllProducts() async {
    try {
      final provider = context.read<ProductProvider>();
      int successCount = 0;

      for (final product in _archivedProducts) {
        final success = await provider.restoreProduct(product.id!);
        if (success) successCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم استرجاع $successCount من ${_archivedProducts.length} منتج',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadArchivedProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في استرجاع المنتجات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
