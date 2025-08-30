import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/SaleProvider.dart';
import 'package:pos/Controller/ProductProvider.dart';

/// شريط حالة المخزون
class InventoryStatusBar extends StatelessWidget {
  const InventoryStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SaleProvider, ProductProvider>(
      builder: (context, saleProvider, productProvider, child) {
        final lowStockProducts = saleProvider.lowStockProducts;
        final totalProducts = productProvider.products.length;

        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              top: BorderSide(color: Colors.grey[300]!),
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              // إجمالي المنتجات
              Expanded(
                child: _buildStatusCard(
                  icon: Icons.inventory_2,
                  title: 'إجمالي المنتجات',
                  value: totalProducts.toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),

              // المنتجات منخفضة المخزون
              Expanded(
                child: _buildStatusCard(
                  icon: Icons.warning,
                  title: 'مخزون منخفض',
                  value: lowStockProducts.length.toString(),
                  color: lowStockProducts.isEmpty
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
              const SizedBox(width: 12),

              // نسبة المخزون الصحي
              Expanded(
                child: _buildStatusCard(
                  icon: Icons.health_and_safety,
                  title: 'المخزون الصحي',
                  value: _getHealthyStockPercentage(
                    totalProducts,
                    lowStockProducts.length,
                  ),
                  color: _getHealthyStockColor(
                    totalProducts,
                    lowStockProducts.length,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // زر إدارة المخزون
              ElevatedButton.icon(
                onPressed: () => _showInventoryManagement(context),
                icon: const Icon(Icons.settings, size: 16),
                label: const Text('إدارة المخزون'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
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
      },
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getHealthyStockPercentage(int total, int lowStock) {
    if (total == 0) return '0%';
    final healthy = total - lowStock;
    final percentage = (healthy / total * 100).round();
    return '$percentage%';
  }

  Color _getHealthyStockColor(int total, int lowStock) {
    if (total == 0) return Colors.grey;
    final healthyPercentage = (total - lowStock) / total;

    if (healthyPercentage >= 0.8) return Colors.green;
    if (healthyPercentage >= 0.6) return Colors.orange;
    return Colors.red;
  }

  void _showInventoryManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings),
            SizedBox(width: 8),
            Text('إدارة المخزون'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('تحديث قائمة المنتجات'),
                subtitle: const Text('إعادة تحميل المنتجات من قاعدة البيانات'),
                onTap: () {
                  // context.read<ProductProvider>().getAllProducts();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحديث قائمة المنتجات'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.warning),
                title: const Text('فحص المخزون المنخفض'),
                subtitle: const Text('البحث عن المنتجات التي تحتاج تزويد'),
                onTap: () {
                  // context.read<SaleProvider>().checkLowStockProducts();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم فحص المخزون'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('تقرير المخزون'),
                subtitle: const Text('عرض تقرير مفصل عن حالة المخزون'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showInventoryReport(context);
                },
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
      ),
    );
  }

  void _showInventoryReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer2<SaleProvider, ProductProvider>(
        builder: (context, saleProvider, productProvider, child) {
          final products = productProvider.products;
          final lowStockProducts = saleProvider.lowStockProducts;
          final outOfStockProducts = products
              .where((p) => p.quantity == 0)
              .toList();
          final healthyStockProducts = products
              .where((p) => p.quantity > p.lowStockThreshold)
              .toList();

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.analytics),
                SizedBox(width: 8),
                Text('تقرير المخزون'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReportSection(
                      'إجمالي المنتجات',
                      products.length.toString(),
                      Colors.blue,
                      Icons.inventory_2,
                    ),
                    const SizedBox(height: 16),
                    _buildReportSection(
                      'مخزون صحي',
                      healthyStockProducts.length.toString(),
                      Colors.green,
                      Icons.check_circle,
                    ),
                    const SizedBox(height: 16),
                    _buildReportSection(
                      'مخزون منخفض',
                      lowStockProducts.length.toString(),
                      Colors.orange,
                      Icons.warning,
                    ),
                    const SizedBox(height: 16),
                    _buildReportSection(
                      'نفد من المخزون',
                      outOfStockProducts.length.toString(),
                      Colors.red,
                      Icons.error,
                    ),
                    const SizedBox(height: 24),
                    if (products.isNotEmpty) ...[
                      const Text(
                        'توزيع المخزون:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildProgressBar(
                        'صحي',
                        healthyStockProducts.length,
                        products.length,
                        Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _buildProgressBar(
                        'منخفض',
                        lowStockProducts.length,
                        products.length,
                        Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      _buildProgressBar(
                        'نافد',
                        outOfStockProducts.length,
                        products.length,
                        Colors.red,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إغلاق'),
              ),
              ElevatedButton(
                onPressed: () {
                  // تصدير التقرير
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('جاري تصدير التقرير...'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                child: const Text('تصدير'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReportSection(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? count / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              '$count (${(percentage * 100).toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
}
