import 'package:flutter/material.dart';
import 'package:pos/Model/ProductModel.dart';

/// BottomSheet تفاصيل المنتج المحسن
class ProductDetailsBottomSheet extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;

  const ProductDetailsBottomSheet({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
    this.onArchive,
  });

  /// عرض BottomSheet
  static void show(
    BuildContext context,
    ProductModel product, {
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onArchive,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailsBottomSheet(
        product: product,
        onEdit: onEdit,
        onDelete: onDelete,
        onArchive: onArchive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // المقبض
          _buildHandle(),

          // الرأس
          _buildHeader(context),

          // المحتوى
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // معلومات أساسية
                  _buildBasicInfo(),

                  const SizedBox(height: 24),

                  // معلومات الأسعار
                  _buildPriceInfo(),

                  const SizedBox(height: 24),

                  // معلومات المخزون
                  _buildStockInfo(),

                  const SizedBox(height: 24),

                  // معلومات إضافية
                  _buildAdditionalInfo(),

                  const SizedBox(height: 24),

                  // التحليلات
                  _buildAnalytics(),

                  const SizedBox(height: 100), // مساحة للأزرار
                ],
              ),
            ),
          ),

          // أزرار الإجراءات
          _buildActionButtons(context),
        ],
      ),
    );
  }

  /// بناء المقبض
  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// بناء الرأس
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // صورة المنتج أو أيقونة
          // Container(
          //   width: 60,
          //   height: 60,
          //   decoration: BoxDecoration(
          //     color: Colors.blue[100],
          //     borderRadius: BorderRadius.circular(12),
          //   ),
          //   child: 
          //       ? ClipRRect(
          //           borderRadius: BorderRadius.circular(12),
          //           child: Image.network(
          //             product.image!,
          //             fit: BoxFit.cover,
          //             errorBuilder: (context, error, stackTrace) => Icon(
          //               Icons.inventory_2,
          //               color: Colors.blue[700],
          //               size: 30,
          //             ),
          //           ),
          //         )
          //       : Icon(Icons.inventory_2, color: Colors.blue[700], size: 30),
          // ),

          const SizedBox(width: 16),

          // معلومات المنتج
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'كود: ${product.code}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                if (product.company.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    product.company,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),

          // حالة المنتج
          _buildStatusBadge(),
        ],
      ),
    );
  }

  /// بناء شارة الحالة
  Widget _buildStatusBadge() {
    Color color;
    String text;
    IconData icon;

    if (product.isOutOfStock) {
      color = Colors.red;
      text = 'نافد';
      icon = Icons.error;
    } else if (product.isLowStock) {
      color = Colors.orange;
      text = 'منخفض';
      icon = Icons.warning;
    } else if (product.isExpired) {
      color = Colors.red[800]!;
      text = 'منتهي';
      icon = Icons.dangerous;
    } else if (product.isNearExpiry) {
      color = Colors.yellow[700]!;
      text = 'قريب الانتهاء';
      icon = Icons.schedule;
    } else {
      color = Colors.green;
      text = 'متوفر';
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
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء المعلومات الأساسية
  Widget _buildBasicInfo() {
    return _buildSection('المعلومات الأساسية', Icons.info, Colors.blue, [
      _buildInfoRow('الاسم', product.name),
      _buildInfoRow('الكود', product.code),
      if (product.barcode.isNotEmpty)
        _buildInfoRow('الباركود', product.barcode),
      if (product.company.isNotEmpty)
        _buildInfoRow('الشركة المصنعة', product.company),
      if (product.description.isNotEmpty)
        _buildInfoRow('الوصف', product.description, isMultiline: true),
    ]);
  }

  /// بناء معلومات الأسعار
  Widget _buildPriceInfo() {
    return _buildSection('معلومات الأسعار', Icons.attach_money, Colors.green, [
      _buildInfoRow('سعر الشراء', '${product.buyPrice.toStringAsFixed(2)} ر.س'),
      _buildInfoRow('سعر البيع', '${product.salePrice.toStringAsFixed(2)} ر.س'),
      _buildInfoRow(
        'ربح الوحدة',
        '${product.profitPerUnit.toStringAsFixed(2)} ر.س',
      ),
      _buildInfoRow(
        'هامش الربح',
        '${product.profitMargin.toStringAsFixed(1)}%',
      ),
      _buildInfoRow(
        'الربح الإجمالي',
        '${(product.profitPerUnit * product.quantity).toStringAsFixed(2)} ر.س',
      ),
    ]);
  }

  /// بناء معلومات المخزون
  Widget _buildStockInfo() {
    return _buildSection('معلومات المخزون', Icons.inventory, Colors.orange, [
      _buildInfoRow('الكمية المتوفرة', '${product.quantity} قطعة'),
      _buildInfoRow('حد التنبيه', '${product.lowStockThreshold} قطعة'),
      _buildInfoRow(
        'قيمة المخزون (شراء)',
        '${(product.buyPrice * product.quantity).toStringAsFixed(2)} ر.س',
      ),
      _buildInfoRow(
        'قيمة المخزون (بيع)',
        '${(product.salePrice * product.quantity).toStringAsFixed(2)} ر.س',
      ),
      if (product.expiryDate != null)
        _buildInfoRow('تاريخ الانتهاء', product.formattedExpiryDate),
    ]);
  }

  /// بناء المعلومات الإضافية
  Widget _buildAdditionalInfo() {
    return _buildSection('معلومات إضافية', Icons.more_horiz, Colors.purple, [
      _buildInfoRow('تاريخ الإضافة', product.date),
      _buildInfoRow('آخر تحديث', product.date), // يمكن إضافة حقل updatedAt
      _buildInfoRow('الحالة', product.isActive ? 'نشط' : 'غير نشط'),
      if (product.isArchived)
        _buildInfoRow('مؤرشف', 'نعم', valueColor: Colors.orange),
    ]);
  }

  /// بناء التحليلات
  Widget _buildAnalytics() {
    final daysToExpiry = product.daysUntilExpiry;
    final stockValue = product.salePrice * product.quantity;
    final turnoverRate = 12.0; // افتراض معدل دوران 12 مرة سنوياً
    final monthlyRevenue =
        stockValue * (turnoverRate / 12) * 0.1; // افتراض بيع 10% شهرياً

    return _buildSection(
      'التحليلات والتوقعات',
      Icons.analytics,
      Colors.indigo,
      [
        if (daysToExpiry != null)
          _buildInfoRow(
            'أيام حتى الانتهاء',
            '$daysToExpiry يوم',
            valueColor: daysToExpiry < 30
                ? Colors.red
                : daysToExpiry < 90
                ? Colors.orange
                : Colors.green,
          ),
        _buildInfoRow(
          'الإيراد الشهري المتوقع',
          '${monthlyRevenue.toStringAsFixed(2)} ر.س',
        ),
        _buildInfoRow(
          'معدل الدوران المقدر',
          '${turnoverRate.toStringAsFixed(1)} مرة/سنة',
        ),
        _buildInfoRow(
          'أيام المخزون',
          '${(365 / turnoverRate).toStringAsFixed(0)} يوم',
        ),
      ],
    );
  }

  /// بناء قسم
  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  /// بناء صف المعلومات
  Widget _buildInfoRow(
    String label,
    String value, {
    bool isMultiline = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.grey[800],
              ),
              maxLines: isMultiline ? null : 1,
              overflow: isMultiline ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء أزرار الإجراءات
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          if (onEdit != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onEdit!();
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('تعديل'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

          if (onEdit != null && (onArchive != null || onDelete != null))
            const SizedBox(width: 12),

          if (onArchive != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onArchive!();
                },
                icon: const Icon(Icons.archive, size: 18),
                label: const Text('أرشفة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

          if (onArchive != null && onDelete != null) const SizedBox(width: 12),

          if (onDelete != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onDelete!();
                },
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('حذف'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
