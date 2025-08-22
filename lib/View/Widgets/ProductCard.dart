import 'package:flutter/material.dart';
import 'package:pos/Model/ProductModel.dart';
import 'package:pos/View/Widgets/ProductDetailsBottomSheet.dart';

/// بطاقة عرض المنتج
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final VoidCallback? onTap;
  final bool showDetailsOnTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
    this.onArchive,
    this.onTap,
    this.showDetailsOnTap = true,
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
          onTap: showDetailsOnTap
              ? () => ProductDetailsBottomSheet.show(
                  context,
                  product,
                  onEdit: onEdit,
                  onDelete: onDelete,
                  onArchive: onArchive,
                )
              : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              children: [
                // الصف الأول: الاسم والحالة مع التنبيهات
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                              // تنبيهات بصرية
                              if (product.isOutOfStock)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'نفد',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else if (product.isLowStock)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'منخفض',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (product.isExpired)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red[800],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'منتهي',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else if (product.isNearExpiry)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'قريب الانتهاء',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
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
                    _buildStatusChip('نشط', Colors.green, Icons.check_circle),
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

                // معلومات إضافية (تاريخ الانتهاء والوصف)
                if (product.expiryDate != null ||
                    product.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.expiryDate != null)
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: product.isExpired
                                    ? Colors.red[700]
                                    : product.isNearExpiry
                                    ? Colors.amber[700]
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'انتهاء الصلاحية: ${product.expiryDate!.day}/${product.expiryDate!.month}/${product.expiryDate!.year}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: product.isExpired
                                        ? Colors.red[700]
                                        : product.isNearExpiry
                                        ? Colors.amber[700]
                                        : Colors.grey[600],
                                    fontWeight:
                                        product.isExpired ||
                                            product.isNearExpiry
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (product.daysUntilExpiry != null &&
                                  product.daysUntilExpiry! >= 0)
                                Text(
                                  '(${product.daysUntilExpiry} يوم)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                            ],
                          ),
                        if (product.description.isNotEmpty) ...[
                          if (product.expiryDate != null)
                            const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.description,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  product.description,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

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
                        'أرشفة',
                        Icons.archive,
                        Colors.orange[700]!,
                        onDelete,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        'التفاصيل',
                        Icons.info,
                        Colors.grey[700]!,
                        () => _showProductDetails(context),
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
  Widget _buildStatusChip(String status, Color color, IconData icon) {
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

  /// عرض تفاصيل المنتج في نافذة منبثقة
  void _showProductDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.inventory_2, color: Colors.blue[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(product.name, style: const TextStyle(fontSize: 18)),
            ),
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
              _buildDetailRow('الكمية المتوفرة', '${product.quantity} قطعة'),
              _buildDetailRow(
                'حد التنبيه',
                '${product.lowStockThreshold} قطعة',
              ),
              _buildDetailRow(
                'سعر الشراء',
                '${product.buyPrice.toStringAsFixed(2)} ريال',
              ),
              _buildDetailRow(
                'سعر البيع',
                '${product.salePrice.toStringAsFixed(2)} ريال',
              ),
              _buildDetailRow(
                'هامش الربح',
                '${product.profitPerUnit.toStringAsFixed(2)} ريال (${product.profitMargin.toStringAsFixed(1)}%)',
              ),
              _buildDetailRow(
                'إجمالي قيمة المخزون',
                '${product.totalStockValue.toStringAsFixed(2)} ريال',
              ),
              _buildDetailRow(
                'الشركة المصنعة',
                product.company.isEmpty ? 'غير محدد' : product.company,
              ),
              _buildDetailRow('تاريخ الإضافة', product.date),
              if (product.expiryDate != null)
                _buildDetailRow(
                  'تاريخ انتهاء الصلاحية',
                  '${product.expiryDate!.day}/${product.expiryDate!.month}/${product.expiryDate!.year}',
                ),
              if (product.daysUntilExpiry != null)
                _buildDetailRow(
                  'الأيام المتبقية للانتهاء',
                  '${product.daysUntilExpiry} يوم',
                ),

              // حالة المنتج
              const SizedBox(height: 16),
              const Text(
                'حالة المنتج:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (product.isOutOfStock)
                    _buildStatusChip('نفد المخزون', Colors.red, Icons.error),
                  if (product.isLowStock && !product.isOutOfStock)
                    _buildStatusChip(
                      'مخزون منخفض',
                      Colors.orange,
                      Icons.warning,
                    ),
                  if (!product.isLowStock && !product.isOutOfStock)
                    _buildStatusChip('متوفر', Colors.green, Icons.check_circle),
                  if (product.isExpired)
                    _buildStatusChip(
                      'منتهي الصلاحية',
                      Colors.red[800]!,
                      Icons.dangerous,
                    ),
                  if (product.isNearExpiry && !product.isExpired)
                    _buildStatusChip(
                      'قريب الانتهاء',
                      Colors.amber,
                      Icons.schedule,
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
          if (onEdit != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onEdit!();
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
            width: 120,
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
