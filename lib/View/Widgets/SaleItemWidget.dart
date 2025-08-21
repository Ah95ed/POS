import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/Model/SaleModel.dart';

/// عنصر المنتج في الفاتورة
class SaleItemWidget extends StatelessWidget {
  final SaleItemModel item;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;
  final Function(double) onDiscountApplied;

  const SaleItemWidget({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onDiscountApplied,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // الصف الأول: اسم المنتج وزر الحذف
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'كود: ${item.productCode}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'حذف المنتج',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // الصف الثاني: السعر والكمية والإجمالي
            Row(
              children: [
                // السعر للوحدة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'السعر',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '${item.unitPrice.toStringAsFixed(2)} ر.س',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // تحكم الكمية
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'الكمية',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      _buildQuantityControls(),
                    ],
                  ),
                ),

                // الإجمالي
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'الإجمالي',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '${item.total.toStringAsFixed(2)} ر.س',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // الصف الثالث: الخصم (إذا كان موجوداً)
            if (item.discount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_offer,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'خصم: ${item.discount.toStringAsFixed(2)} ر.س',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showDiscountDialog(context),
                      child: const Text(
                        'تعديل',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _showDiscountDialog(context),
                icon: const Icon(Icons.local_offer, size: 16),
                label: const Text('إضافة خصم', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// بناء تحكم الكمية
  Widget _buildQuantityControls() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // زر تقليل الكمية
          InkWell(
            onTap: item.quantity > 1
                ? () => onQuantityChanged(item.quantity - 1)
                : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.remove,
                size: 16,
                color: item.quantity > 1 ? Colors.black : Colors.grey,
              ),
            ),
          ),

          // عرض الكمية
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // زر زيادة الكمية
          InkWell(
            onTap: () => onQuantityChanged(item.quantity + 1),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.add, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// عرض نافذة الخصم
  void _showDiscountDialog(BuildContext context) {
    final controller = TextEditingController(
      text: item.discount > 0 ? item.discount.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تطبيق خصم على المنتج'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المنتج: ${item.productName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'السعر الأصلي: ${(item.unitPrice * item.quantity).toStringAsFixed(2)} ر.س',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'قيمة الخصم (ر.س)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_offer),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          if (item.discount > 0)
            TextButton(
              onPressed: () {
                onDiscountApplied(0);
                Navigator.of(context).pop();
              },
              child: const Text('إزالة الخصم'),
            ),
          ElevatedButton(
            onPressed: () {
              final discount = double.tryParse(controller.text) ?? 0;
              final maxDiscount = item.unitPrice * item.quantity;

              if (discount > maxDiscount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('قيمة الخصم تتجاوز قيمة المنتج'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              onDiscountApplied(discount);
              Navigator.of(context).pop();
            },
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }
}
