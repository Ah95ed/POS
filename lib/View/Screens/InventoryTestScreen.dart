import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/ProductProvider.dart';
import 'package:pos/View/Widgets/LowStockAlert.dart';
import 'package:pos/View/Widgets/InventoryStatusBar.dart';
import 'package:pos/Model/ProductModel.dart';

/// شاشة اختبار نظام إدارة المخزون
class InventoryTestScreen extends StatefulWidget {
  const InventoryTestScreen({super.key});

  @override
  State<InventoryTestScreen> createState() => _InventoryTestScreenState();
}

class _InventoryTestScreenState extends State<InventoryTestScreen> {
  @override
  void initState() {
    super.initState();
    // إضافة منتجات تجريبية عند بدء الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addSampleProducts();
    });
  }

  void _addSampleProducts() {
    final productProvider = context.read<ProductProvider>();

    // منتجات تجريبية مع مستويات مخزون مختلفة
    final sampleProducts = [
      ProductModel(
        id: 1,
        name: 'لابتوب ديل',
        code: 'DELL001',
        company: 'Dell',
        salePrice: 1500.0,
        buyPrice: 1200.0,
        quantity: 2, // مخزون منخفض
        date: DateTime.now().toString(),
        lowStockThreshold: 5,
      ),
      ProductModel(
        id: 2,
        name: 'ماوس لاسلكي',
        code: 'MOUSE001',
        company: 'Logitech',
        salePrice: 25.0,
        buyPrice: 18.0,
        quantity: 15, // مخزون طبيعي
        date: DateTime.now().toString(),
        lowStockThreshold: 10,
      ),
      ProductModel(
        id: 3,
        name: 'كيبورد ميكانيكي',
        code: 'KB001',
        company: 'Corsair',
        salePrice: 120.0,
        buyPrice: 90.0,
        quantity: 0, // نفد من المخزون
        date: DateTime.now().toString(),
        lowStockThreshold: 3,
      ),
      ProductModel(
        id: 4,
        name: 'شاشة 24 بوصة',
        code: 'MON001',
        company: 'Samsung',
        salePrice: 350.0,
        buyPrice: 280.0,
        quantity: 8, // مخزون منخفض
        date: DateTime.now().toString(),
        lowStockThreshold: 10,
      ),
      ProductModel(
        id: 5,
        name: 'سماعات بلوتوث',
        code: 'HEAD001',
        company: 'Sony',
        salePrice: 80.0,
        buyPrice: 60.0,
        quantity: 25, // مخزون طبيعي
        date: DateTime.now().toString(),
        lowStockThreshold: 15,
      ),
    ];

    // إضافة المنتجات للقائمة
    for (var product in sampleProducts) {
      productProvider.products.add(product);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار نظام إدارة المخزون'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط حالة المخزون
          const InventoryStatusBar(),

          // تنبيهات المخزون المنخفض
          const LowStockAlert(),

          // قائمة المنتجات
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.products.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد منتجات',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'اضغط على زر التحديث لإضافة منتجات تجريبية',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: productProvider.products.length,
                  itemBuilder: (context, index) {
                    final product = productProvider.products[index];
                    return _buildProductCard(product);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMessage('محاكاة البيع غير متاحة في وضع العرض'),
        icon: const Icon(Icons.shopping_cart),
        label: const Text('محاكاة بيع'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (product.quantity == 0) {
      statusColor = Colors.red;
      statusText = 'نفد';
      statusIcon = Icons.error;
    } else if (product.quantity <= product.lowStockThreshold) {
      statusColor = Colors.orange;
      statusText = 'منخفض';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.green;
      statusText = 'متوفر';
      statusIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                        'الكود: ${product.code} | الشركة: ${product.company}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'الكمية',
                    '${product.quantity} قطعة',
                    Icons.inventory,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'الحد الأدنى',
                    '${product.lowStockThreshold} قطعة',
                    Icons.trending_down,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'السعر',
                    '${product.salePrice.toStringAsFixed(2)} د.ل',
                    Icons.attach_money,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showMessage('بيع المنتج غير متاح في وضع العرض'),
                    icon: const Icon(Icons.remove, size: 16),
                    label: const Text('بيع قطعة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showMessage('تزويد المخزون غير متاح في وضع العرض'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('تزويد المخزون'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[100],
                      foregroundColor: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _refreshData() {
    setState(() {
      final productProvider = context.read<ProductProvider>();
      productProvider.products.clear();
    });

    _addSampleProducts();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تحديث البيانات التجريبية'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
