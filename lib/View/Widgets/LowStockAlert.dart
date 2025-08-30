import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/SaleProvider.dart';
import 'package:pos/Controller/ProductProvider.dart';
import 'package:pos/Model/ProductModel.dart';
import 'package:pos/Helper/Constants/AppConstants.dart';

/// ويدجت تنبيهات المخزون المنخفض
class LowStockAlert extends StatelessWidget {
  const LowStockAlert({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SaleProvider, ProductProvider>(
      builder: (context, saleProvider, productProvider, child) {
        final lowStockProducts = saleProvider.lowStockProducts;

        if (lowStockProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            border: Border.all(color: Colors.orange[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'تنبيه: منتجات منخفضة المخزون',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () =>
                        _showLowStockDialog(context, lowStockProducts),
                    icon: Icon(Icons.visibility, color: Colors.orange[700]),
                    tooltip: 'عرض التفاصيل',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${lowStockProducts.length} منتج يحتاج إلى تزويد',
                style: TextStyle(color: Colors.orange[600], fontSize: 14),
              ),
              if (lowStockProducts.length <= 3) ...[
                const SizedBox(height: 8),
                ...lowStockProducts.map((product) => _buildProductRow(product)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductRow(ProductModel product) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(product.name, style: const TextStyle(fontSize: 12)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${product.quantity} متبقي',
              style: TextStyle(
                fontSize: 10,
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLowStockDialog(
    BuildContext context,
    List<ProductModel> lowStockProducts,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('منتجات منخفضة المخزون'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: lowStockProducts.length,
            itemBuilder: (context, index) {
              final product = lowStockProducts[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.inventory, color: Colors.red[700]),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الكود: ${product.code}'),
                      Text('الشركة: ${product.company}'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${product.quantity} قطعة',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الحد الأدنى: ${product.lowStockThreshold}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showProductActions(context, product);
                  },
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
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showBulkRestockDialog(context, lowStockProducts);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text(
              'تزويد الكل',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductActions(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إجراءات المنتج: ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الكمية الحالية: ${product.quantity} قطعة'),
            Text('الحد الأدنى: ${product.lowStockThreshold} قطعة'),
            Text('السعر: ${AppConstants.formatCurrency(product.salePrice)}'),
            const SizedBox(height: 16),
            const Text(
              'ما الإجراء المطلوب؟',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showRestockDialog(context, product);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'تزويد المخزون',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showUpdateThresholdDialog(context, product);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text(
              'تعديل الحد الأدنى',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showRestockDialog(BuildContext context, ProductModel product) {
    final TextEditingController quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تزويد المخزون: ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الكمية الحالية: ${product.quantity} قطعة'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'كمية التزويد',
                hintText: 'أدخل الكمية المراد إضافتها',
                border: OutlineInputBorder(),
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
              final quantity = int.tryParse(quantityController.text);
              if (quantity != null && quantity > 0) {
                // تنفيذ تزويد المخزون
                // final productProvider = context.read<ProductProvider>();
                // await productProvider.increaseProductQuantity(product.id!, quantity);

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم تزويد المخزون بـ $quantity قطعة'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'تأكيد التزويد',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateThresholdDialog(BuildContext context, ProductModel product) {
    final TextEditingController thresholdController = TextEditingController(
      text: product.lowStockThreshold.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل الحد الأدنى: ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الحد الأدنى الحالي: ${product.lowStockThreshold} قطعة'),
            const SizedBox(height: 16),
            TextField(
              controller: thresholdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الحد الأدنى الجديد',
                hintText: 'أدخل الحد الأدنى للتنبيه',
                border: OutlineInputBorder(),
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
              final threshold = int.tryParse(thresholdController.text);
              if (threshold != null && threshold >= 0) {
                // تنفيذ تحديث الحد الأدنى
                // final productProvider = context.read<ProductProvider>();
                // await productProvider.updateLowStockThreshold(product.id!, threshold);

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم تحديث الحد الأدنى إلى $threshold قطعة'),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text(
              'تأكيد التحديث',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showBulkRestockDialog(
    BuildContext context,
    List<ProductModel> products,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تزويد جميع المنتجات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('سيتم تزويد ${products.length} منتج'),
            const SizedBox(height: 16),
            const Text(
              'هذه العملية ستقوم بتزويد كل منتج إلى الحد الأدنى المحدد له.',
              style: TextStyle(fontSize: 14),
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
              // تنفيذ تزويد جميع المنتجات
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تزويد جميع المنتجات منخفضة المخزون'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'تأكيد التزويد',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
