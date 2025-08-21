import 'package:flutter/material.dart';
import 'package:pos/Model/ProductModel.dart';

/// شبكة عرض المنتجات في نقطة البيع
class ProductGridWidget extends StatelessWidget {
  final List<ProductModel> products;
  final Function(ProductModel) onProductTap;
  final int crossAxisCount;

  const ProductGridWidget({
    super.key,
    required this.products,
    required this.onProductTap,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
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
              'تأكد من إضافة منتجات في قسم إدارة المنتجات',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductTile(
          product: product,
          onTap: () => onProductTap(product),
        );
      },
    );
  }
}

/// بطاقة المنتج في الشبكة
class ProductTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductTile({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: product.quantity > 0 ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: product.quantity <= 0 ? Colors.grey[100] : Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة المنتج أو أيقونة افتراضية
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildDefaultIcon(),
                ),
              ),

              const SizedBox(height: 8),

              // اسم المنتج
              Expanded(
                flex: 1,
                child: Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: product.quantity <= 0
                        ? Colors.grey[600]
                        : Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 4),

              // كود المنتج
              Text(
                product.code,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),

              const SizedBox(height: 8),

              // السعر والكمية
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // السعر
                  Text(
                    '${product.salePrice.toStringAsFixed(2)} ر.س',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: product.quantity <= 0
                          ? Colors.grey[600]
                          : Colors.green[700],
                    ),
                  ),

                  // حالة المخزون
                  _buildStockIndicator(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء الأيقونة الافتراضية
  Widget _buildDefaultIcon() {
    return Icon(Icons.inventory_2, size: 48, color: Colors.grey[400]);
  }

  /// بناء مؤشر حالة المخزون
  Widget _buildStockIndicator() {
    Color color;
    IconData icon;
    String tooltip;

    if (product.isOutOfStock) {
      color = Colors.red;
      icon = Icons.error;
      tooltip = 'نافد المخزون';
    } else if (product.isLowStock) {
      color = Colors.orange;
      icon = Icons.warning;
      tooltip = 'مخزون منخفض (${product.quantity})';
    } else {
      color = Colors.green;
      icon = Icons.check_circle;
      tooltip = 'متوفر (${product.quantity})';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              '${product.quantity}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
