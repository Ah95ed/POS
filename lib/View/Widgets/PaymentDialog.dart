import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// نافذة الدفع
class PaymentDialog extends StatefulWidget {
  final double total;
  final Function(
    String paymentMethod,
    double paidAmount,
    String? customerName,
    String? customerPhone,
  )
  onPaymentCompleted;

  const PaymentDialog({
    super.key,
    required this.total,
    required this.onPaymentCompleted,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final TextEditingController _paidAmountController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();

  String _selectedPaymentMethod = 'نقدي';
  double _paidAmount = 0.0;
  double _changeAmount = 0.0;
  bool _isProcessing = false;

  final List<String> _paymentMethods = [
    'نقدي',
    'بطاقة ائتمان',
    'بطاقة مدى',
    'تحويل بنكي',
    'محفظة إلكترونية',
  ];

  @override
  void initState() {
    super.initState();
    _paidAmountController.text = widget.total.toStringAsFixed(2);
    _paidAmount = widget.total;
    _calculateChange();
  }

  @override
  void dispose() {
    _paidAmountController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isWideScreen ? 500 : null,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildContent(),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  /// بناء رأس النافذة
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green[700],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.payment, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'إتمام الدفع',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// بناء محتوى النافذة
  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ملخص الفاتورة
        _buildInvoiceSummary(),

        const SizedBox(height: 24),

        // طرق الدفع
        _buildPaymentMethods(),

        const SizedBox(height: 24),

        // المبلغ المدفوع
        _buildPaidAmountSection(),

        const SizedBox(height: 24),

        // الباقي من الدفع
        _buildChangeSection(),

        const SizedBox(height: 16),

        // أزرار المبالغ السريعة
        _buildQuickAmountButtons(),
      ],
    );
  }

  /// بناء ملخص الفاتورة
  Widget _buildInvoiceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                'ملخص الفاتورة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إجمالي المبلغ:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${widget.total.toStringAsFixed(2)} ر.س',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء طرق الدفع
  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'طريقة الدفع',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _paymentMethods.map((method) {
            final isSelected = _selectedPaymentMethod == method;
            return FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getPaymentIcon(method),
                    size: 16,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(method),
                ],
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPaymentMethod = method;
                  });
                }
              },
              selectedColor: Colors.green[700],
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// بناء قسم المبلغ المدفوع
  Widget _buildPaidAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المبلغ المدفوع',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _paidAmountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.attach_money),
            suffixText: 'ر.س',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green[700]!),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _paidAmount = double.tryParse(value) ?? 0.0;
              _calculateChange();
            });
          },
          autofocus: true,
        ),
      ],
    );
  }

  /// بناء قسم الباقي
  Widget _buildChangeSection() {
    final change = _paidAmount - widget.total;
    final isInsufficientPayment = change < 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isInsufficientPayment ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInsufficientPayment ? Colors.red[300]! : Colors.green[300]!,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isInsufficientPayment ? Icons.error : Icons.change_circle,
                color: isInsufficientPayment
                    ? Colors.red[700]
                    : Colors.green[700],
              ),
              const SizedBox(width: 8),
              Text(
                isInsufficientPayment ? 'المبلغ المتبقي:' : 'الباقي:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isInsufficientPayment
                      ? Colors.red[700]
                      : Colors.green[700],
                ),
              ),
            ],
          ),
          Text(
            '${change.abs().toStringAsFixed(2)} ر.س',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isInsufficientPayment
                  ? Colors.red[700]
                  : Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء أزرار المبالغ السريعة
  Widget _buildQuickAmountButtons() {
    final quickAmounts = [
      widget.total,
      widget.total + 10,
      widget.total + 20,
      widget.total + 50,
      widget.total + 100,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'مبالغ سريعة',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickAmounts.map((amount) {
            return OutlinedButton(
              onPressed: () {
                setState(() {
                  _paidAmount = amount;
                  _paidAmountController.text = amount.toStringAsFixed(2);
                });
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.green[700]!),
                foregroundColor: Colors.green[700],
              ),
              child: Text('${amount.toStringAsFixed(0)} ر.س'),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// بناء أزرار العمليات
  Widget _buildActions() {
    final change = _paidAmount - widget.total;
    final canProceed = change >= 0 && !_isProcessing;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isProcessing
                  ? null
                  : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('إلغاء'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: canProceed ? _processPayment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'إتمام الدفع',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// حساب الباقي
  void _calculateChange() {
    setState(() {
      _changeAmount = _paidAmount - widget.total;
    });
  }

  /// معالجة الدفع
  void _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    // محاكاة معالجة الدفع
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      widget.onPaymentCompleted(
        _selectedPaymentMethod,
        _paidAmount,
        _customerNameController.text.isEmpty
            ? null
            : _customerNameController.text,
        _customerPhoneController.text.isEmpty
            ? null
            : _customerPhoneController.text,
      );
      Navigator.of(context).pop();
    }
  }

  /// الحصول على أيقونة طريقة الدفع
  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'نقدي':
        return Icons.money;
      case 'بطاقة ائتمان':
        return Icons.credit_card;
      case 'بطاقة مدى':
        return Icons.credit_card;
      case 'تحويل بنكي':
        return Icons.account_balance;
      case 'محفظة إلكترونية':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }
}

/// Extension لتحديد النص بالكامل
extension TextEditingControllerExtension on TextEditingController {
  void selectAll() {
    if (text.isNotEmpty) {
      selection = TextSelection(baseOffset: 0, extentOffset: text.length);
    }
  }
}
