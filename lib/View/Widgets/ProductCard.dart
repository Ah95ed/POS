import 'package:flutter/material.dart';
import 'package:pos/Model/ProductModel.dart';

/// بطاقة عرض المنتج
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              children: [
                // الصف الأول: الاسم والحالة
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'كود: ${product.code}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(),
                  ],
                ),

                const SizedBox(height: 12),

                // الصف الثاني: المعلومات الأساسية
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'الكمية',
                        '${product.quantity}',
                        Icons.inventory,
                        _getQuantityColor(),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'سعر البيع',
                        '${product.salePrice.toStringAsFixed(2)} ر.س',
                        Icons.sell,
                        Colors.green[700]!,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'الربح',
                        '${product.profitPerUnit.toStringAsFixed(2)} ر.س',
                        Icons.trending_up,
                        product.profitPerUnit > 0
                            ? Colors.green[700]!
                            : Colors.red[700]!,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // الصف الثالث: الشركة والتاريخ
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.business,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.company.isEmpty
                                  ? 'غير محدد'
                                  : product.company,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.date_range,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // الصف الرابع: أزرار العمليات
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        'تعديل',
                        Icons.edit,
                        Colors.blue[700]!,
                        onEdit,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        'حذف',
                        Icons.delete,
                        Colors.red[700]!,
                        onDelete,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// بناء chip حالة المنتج
  Widget _buildStatusChip() {
    String status;
    Color color;
    IconData icon;

    if (product.isOutOfStock) {
      status = 'نافد';
      color = Colors.red;
      icon = Icons.error;
    } else if (product.isLowStock) {
      status = 'منخفض';
      color = Colors.orange;
      icon = Icons.warning;
    } else {
      status = 'متوفر';
      color = Colors.green;
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء عنصر معلومات
  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// بناء زر العملية
  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
  ) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  /// الحصول على لون الكمية حسب الحالة
  Color _getQuantityColor() {
    if (product.isOutOfStock) {
      return Colors.red[700]!;
    } else if (product.isLowStock) {
      return Colors.orange[700]!;
    } else {
      return Colors.blue[700]!;
    }
  }
}
