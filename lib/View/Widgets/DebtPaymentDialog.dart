import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_sizer/smart_sizer.dart';

/// حوار إضافة دفعة على الدين
class DebtPaymentDialog extends StatefulWidget {
  final String title;
  final double maxAmount;
  final String currency;
  final Function(double amount, String? notes) onSave;

  const DebtPaymentDialog({
    super.key,
    required this.title,
    required this.maxAmount,
    required this.currency,
    required this.onSave,
  });

  @override
  State<DebtPaymentDialog> createState() => _DebtPaymentDialogState();
}

class _DebtPaymentDialogState extends State<DebtPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: context.getWidth(80),
        padding: EdgeInsets.all(context.getWidth(6)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: context.getFontSize(18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            SizedBox(height: context.getWidth(4)),

            // النموذج
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // المبلغ المتبقي
                  Container(
                    padding: EdgeInsets.all(context.getWidth(3)),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المبلغ المتبقي:',
                          style: TextStyle(
                            fontSize: context.getFontSize(14),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.maxAmount.toStringAsFixed(0)} ${widget.currency}',
                          style: TextStyle(
                            fontSize: context.getFontSize(16),
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: context.getWidth(4)),

                  // مبلغ الدفعة
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'مبلغ الدفعة (${widget.currency})',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.payment),
                      suffixText: widget.currency,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'مبلغ الدفعة مطلوب';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'مبلغ الدفعة يجب أن يكون أكبر من صفر';
                      }
                      if (amount > widget.maxAmount) {
                        return 'مبلغ الدفعة لا يمكن أن يتجاوز المبلغ المتبقي';
                      }
                      return null;
                    },
                    autofocus: true,
                  ),

                  SizedBox(height: context.getWidth(4)),

                  // أزرار المبالغ السريعة
                  Text(
                    'مبالغ سريعة:',
                    style: TextStyle(
                      fontSize: context.getFontSize(14),
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: context.getWidth(2)),
                  Wrap(
                    spacing: context.getWidth(2),
                    runSpacing: context.getWidth(1),
                    children: _getQuickAmounts().map((amount) {
                      return OutlinedButton(
                        onPressed: () {
                          _amountController.text = amount.toStringAsFixed(0);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.blue[700]!),
                          foregroundColor: Colors.blue[700],
                          padding: EdgeInsets.symmetric(
                            horizontal: context.getWidth(3),
                            vertical: context.getWidth(1),
                          ),
                        ),
                        child: Text(
                          '${amount.toStringAsFixed(0)} ${widget.currency}',
                          style: TextStyle(fontSize: context.getFontSize(12)),
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: context.getWidth(4)),

                  // الملاحظات
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            SizedBox(height: context.getWidth(6)),

            // أزرار الحفظ والإلغاء
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                SizedBox(width: context.getWidth(3)),
                ElevatedButton(
                  onPressed: _isLoading ? null : _savePayment,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('حفظ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// الحصول على المبالغ السريعة
  List<double> _getQuickAmounts() {
    final amounts = <double>[];

    // إضافة مبالغ مقترحة بناءً على المبلغ المتبقي
    if (widget.maxAmount >= 1000) {
      amounts.addAll([1000, 5000, 10000]);
    }
    if (widget.maxAmount >= 25000) {
      amounts.addAll([25000, 50000]);
    }
    if (widget.maxAmount >= 100000) {
      amounts.add(100000);
    }

    // إضافة نصف المبلغ والمبلغ كاملاً
    if (widget.maxAmount > 2) {
      amounts.add(widget.maxAmount / 2);
    }
    amounts.add(widget.maxAmount);

    // إزالة المكررات وترتيب تصاعدي
    final uniqueAmounts = amounts.toSet().toList();
    uniqueAmounts.sort();

    // أخذ أول 6 مبالغ فقط
    return uniqueAmounts.take(6).toList();
  }

  /// حفظ الدفعة
  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      widget.onSave(amount, notes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حفظ البيانات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
