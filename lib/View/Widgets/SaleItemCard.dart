import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/Model/SaleModel.dart';

/// بطاقة عنصر البيع في الفاتورة
class SaleItemCard extends StatelessWidget {
  final SaleItem item;
  final Function(int) onQuantityChanged;
  final Function(double) onDiscountApplied;
  final VoidCallback onRemove;

  const SaleItemCard({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onDiscountApplied,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  icon: Icon(Icons.delete, color: Colors.red[600]),
                  tooltip: 'حذف المنتج',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // الصف الثاني: السعر والكمية
            Row(
              children: [
                // السعر
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),

                // الكمية
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // الصف الثالث: الخصم (إذا كان موجود)
            if (item.discount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.percent, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    Text(
                      'خصم: ${item.discount.toStringAsFixed(2)} ر.س',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _showDiscountDialog,
                      child: Text(
                        'تعديل',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // الصف الرابع: أزرار العمليات
            const SizedBox(height: 8),
            Row(
              children: [
                if (item.discount == 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showDiscountDialog,
                      icon: const Icon(Icons.percent, size: 16),
                      label: const Text('خصم', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange[700],
                        side: BorderSide(color: Colors.orange[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                if (item.discount == 0) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showQuantityDialog,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text(
                      'تعديل الكمية',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                      side: BorderSide(color: Colors.blue[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 8),
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

  /// بناء عناصر التحكم في الكمية
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
            onTap: () {
              if (item.quantity > 1) {
                onQuantityChanged(item.quantity - 1);
              }
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.remove,
                size: 16,
                color: item.quantity > 1 ? Colors.red[600] : Colors.grey[400],
              ),
            ),
          ),

          // عرض الكمية
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // زر زيادة الكمية
          InkWell(
            onTap: () => onQuantityChanged(item.quantity + 1),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.add, size: 16, color: Colors.green[600]),
            ),
          ),
        ],
      ),
    );
  }

  /// عرض نافذة تعديل الكمية
  void _showQuantityDialog() {
    showDialog(
      context: NavigationService.navigatorKey.currentContext!,
      builder: (context) => _QuantityDialog(
        currentQuantity: item.quantity,
        productName: item.productName,
        onQuantityChanged: onQuantityChanged,
      ),
    );
  }

  /// عرض نافذة الخصم
  void _showDiscountDialog() {
    showDialog(
      context: NavigationService.navigatorKey.currentContext!,
      builder: (context) =>
          _ItemDiscountDialog(item: item, onDiscountApplied: onDiscountApplied),
    );
  }
}

/// نافذة تعديل الكمية
class _QuantityDialog extends StatefulWidget {
  final int currentQuantity;
  final String productName;
  final Function(int) onQuantityChanged;

  const _QuantityDialog({
    required this.currentQuantity,
    required this.productName,
    required this.onQuantityChanged,
  });

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  late TextEditingController _quantityController;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.currentQuantity;
    _quantityController = TextEditingController(text: _quantity.toString());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل الكمية'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.productName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // عناصر التحكم في الكمية
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // زر تقليل
              IconButton(
                onPressed: _quantity > 1 ? _decreaseQuantity : null,
                icon: const Icon(Icons.remove_circle),
                iconSize: 32,
                color: Colors.red[600],
              ),

              // حقل الكمية
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _quantityController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (value) {
                    final newQuantity = int.tryParse(value);
                    if (newQuantity != null && newQuantity > 0) {
                      setState(() {
                        _quantity = newQuantity;
                      });
                    }
                  },
                ),
              ),

              // زر زيادة
              IconButton(
                onPressed: _increaseQuantity,
                icon: const Icon(Icons.add_circle),
                iconSize: 32,
                color: Colors.green[600],
              ),
            ],
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
            widget.onQuantityChanged(_quantity);
            Navigator.of(context).pop();
          },
          child: const Text('تأكيد'),
        ),
      ],
    );
  }

  void _increaseQuantity() {
    setState(() {
      _quantity++;
      _quantityController.text = _quantity.toString();
    });
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
        _quantityController.text = _quantity.toString();
      });
    }
  }
}

/// نافذة خصم العنصر
class _ItemDiscountDialog extends StatefulWidget {
  final SaleItem item;
  final Function(double) onDiscountApplied;

  const _ItemDiscountDialog({
    required this.item,
    required this.onDiscountApplied,
  });

  @override
  State<_ItemDiscountDialog> createState() => _ItemDiscountDialogState();
}

class _ItemDiscountDialogState extends State<_ItemDiscountDialog> {
  final TextEditingController _discountController = TextEditingController();
  bool _isPercentage = false;
  late double _maxDiscount;

  @override
  void initState() {
    super.initState();
    _maxDiscount = widget.item.unitPrice * widget.item.quantity;
    _discountController.text = widget.item.discount.toString();
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تطبيق خصم على المنتج'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.item.productName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'السعر: ${widget.item.unitPrice.toStringAsFixed(2)} ر.س × ${widget.item.quantity}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            'الإجمالي: ${_maxDiscount.toStringAsFixed(2)} ر.س',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _discountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              labelText: _isPercentage ? 'نسبة الخصم (%)' : 'مبلغ الخصم (ر.س)',
              border: const OutlineInputBorder(),
              helperText: _isPercentage
                  ? 'أدخل نسبة من 0 إلى 100'
                  : 'الحد الأقصى: ${_maxDiscount.toStringAsFixed(2)} ر.س',
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Checkbox(
                value: _isPercentage,
                onChanged: (value) {
                  setState(() {
                    _isPercentage = value ?? false;
                    _discountController.clear();
                  });
                },
              ),
              const Text('خصم بالنسبة المئوية'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        if (widget.item.discount > 0)
          TextButton(
            onPressed: () {
              widget.onDiscountApplied(0);
              Navigator.of(context).pop();
            },
            child: Text(
              'إزالة الخصم',
              style: TextStyle(color: Colors.red[600]),
            ),
          ),
        ElevatedButton(
          onPressed: () {
            final input = double.tryParse(_discountController.text) ?? 0;
            double discount;

            if (_isPercentage) {
              if (input > 100) {
                _showErrorDialog('نسبة الخصم لا يمكن أن تتجاوز 100%');
                return;
              }
              discount = _maxDiscount * (input / 100);
            } else {
              discount = input;
            }

            if (discount > _maxDiscount) {
              _showErrorDialog('مبلغ الخصم لا يمكن أن يتجاوز إجمالي المنتج');
              return;
            }

            widget.onDiscountApplied(discount);
            Navigator.of(context).pop();
          },
          child: const Text('تطبيق'),
        ),
      ],
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطأ'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}

/// خدمة التنقل العامة
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
