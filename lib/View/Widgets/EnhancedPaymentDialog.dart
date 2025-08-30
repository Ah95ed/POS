import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/SaleProvider.dart';
import 'package:pos/Helper/Constants/AppConstants.dart';

/// نافذة دفع متطورة مع طرق دفع متعددة
class EnhancedPaymentDialog extends StatefulWidget {
  final double totalAmount;

  const EnhancedPaymentDialog({super.key, required this.totalAmount});

  @override
  State<EnhancedPaymentDialog> createState() => _EnhancedPaymentDialogState();
}

class _EnhancedPaymentDialogState extends State<EnhancedPaymentDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedPaymentMethod = 'نقدي';
  double _paidAmount = 0.0;
  bool _printReceipt = true;
  bool _sendSMS = false;

  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      name: 'نقدي',
      icon: Icons.money,
      color: Colors.green,
      description: 'دفع نقدي مباشر',
    ),
    PaymentMethod(
      name: 'بطاقة ائتمان',
      icon: Icons.credit_card,
      color: Colors.blue,
      description: 'فيزا، ماستركارد',
    ),
    PaymentMethod(
      name: 'محفظة رقمية',
      icon: Icons.account_balance_wallet,
      color: Colors.purple,
      description: 'ZainCash، آسيا هوك، فاست باي',
    ),
    PaymentMethod(
      name: 'تحويل بنكي',
      icon: Icons.account_balance,
      color: Colors.orange,
      description: 'تحويل مباشر',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cashController.text = widget.totalAmount.toStringAsFixed(2);
    _paidAmount = widget.totalAmount;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // العنوان
            _buildHeader(),

            const SizedBox(height: 20),

            // التبويبات
            _buildTabs(),

            const SizedBox(height: 20),

            // محتوى التبويبات
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPaymentTab(),
                  _buildCustomerTab(),
                  _buildSummaryTab(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // أزرار العمل
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.payment, color: Colors.blue[700], size: 28),
        const SizedBox(width: 12),
        Text(
          'إتمام الدفع',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.payment), text: 'الدفع'),
          Tab(icon: Icon(Icons.person), text: 'العميل'),
          Tab(icon: Icon(Icons.receipt), text: 'الملخص'),
        ],
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        indicator: BoxDecoration(
          color: Colors.blue[700],
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildPaymentTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // المبلغ الإجمالي
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[500]!],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'المبلغ الإجمالي',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.formatCurrency(widget.totalAmount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // طرق الدفع
          const Text(
            'اختر طريقة الدفع:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          ...(_paymentMethods.map((method) => _buildPaymentMethodCard(method))),

          const SizedBox(height: 20),

          // المبلغ المدفوع
          if (_selectedPaymentMethod == 'نقدي') _buildCashInput(),

          // الباقي
          if (_paidAmount != widget.totalAmount) _buildChangeAmount(),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    final isSelected = _selectedPaymentMethod == method.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method.name;
            if (method.name != 'نقدي') {
              _paidAmount = widget.totalAmount;
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? method.color.withOpacity(0.1) : Colors.grey[50],
            border: Border.all(
              color: isSelected ? method.color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: method.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(method.icon, color: method.color, size: 24),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? method.color : Colors.black,
                      ),
                    ),
                    Text(
                      method.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              if (isSelected)
                Icon(Icons.check_circle, color: method.color, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المبلغ المدفوع:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cashController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: 'د.ع',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _paidAmount = double.tryParse(value) ?? 0.0;
            });
          },
        ),
      ],
    );
  }

  Widget _buildChangeAmount() {
    final change = _paidAmount - widget.totalAmount;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: change >= 0 ? Colors.green[50] : Colors.red[50],
        border: Border.all(color: change >= 0 ? Colors.green : Colors.red),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            change >= 0 ? 'الباقي:' : 'النقص:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: change >= 0 ? Colors.green[700] : Colors.red[700],
            ),
          ),
          Text(
            AppConstants.formatCurrency(change.abs()),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: change >= 0 ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'معلومات العميل (اختيارية):',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: _customerNameController,
            decoration: InputDecoration(
              labelText: 'اسم العميل',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _customerPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'رقم الهاتف',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'ملاحظات',
              prefixIcon: const Icon(Icons.note),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // خيارات إضافية
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'خيارات إضافية:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  CheckboxListTile(
                    title: const Text('طباعة الفاتورة'),
                    subtitle: const Text('طباعة فاتورة ورقية'),
                    value: _printReceipt,
                    onChanged: (value) {
                      setState(() {
                        _printReceipt = value!;
                      });
                    },
                  ),

                  CheckboxListTile(
                    title: const Text('إرسال رسالة نصية'),
                    subtitle: const Text('إرسال الفاتورة عبر SMS'),
                    value: _sendSMS,
                    onChanged: (value) {
                      setState(() {
                        _sendSMS = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملخص العملية:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // ملخص الدفع
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow(
                    'المبلغ الإجمالي:',
                    AppConstants.formatCurrency(widget.totalAmount),
                  ),
                  _buildSummaryRow('طريقة الدفع:', _selectedPaymentMethod),
                  _buildSummaryRow(
                    'المبلغ المدفوع:',
                    AppConstants.formatCurrency(_paidAmount),
                  ),
                  if (_paidAmount != widget.totalAmount)
                    _buildSummaryRow(
                      _paidAmount > widget.totalAmount ? 'الباقي:' : 'النقص:',
                      AppConstants.formatCurrency(
                        (_paidAmount - widget.totalAmount).abs(),
                      ),
                      color: _paidAmount > widget.totalAmount
                          ? Colors.green
                          : Colors.red,
                    ),
                ],
              ),
            ),
          ),

          // معلومات العميل
          if (_customerNameController.text.isNotEmpty ||
              _customerPhoneController.text.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'معلومات العميل:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_customerNameController.text.isNotEmpty)
                      _buildSummaryRow('الاسم:', _customerNameController.text),
                    if (_customerPhoneController.text.isNotEmpty)
                      _buildSummaryRow(
                        'الهاتف:',
                        _customerPhoneController.text,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final canComplete =
        _selectedPaymentMethod != 'نقدي' || _paidAmount >= widget.totalAmount;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('إلغاء', style: TextStyle(fontSize: 16)),
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: canComplete ? _completeSale : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'إتمام البيع',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _completeSale() {
    final provider = context.read<SaleProvider>();

    // تحديث بيانات البيع
    provider.updatePaymentMethod(_selectedPaymentMethod);
    provider.updatePaidAmount(_paidAmount);
    provider.updateCustomerInfo(
      name: _customerNameController.text.trim().isEmpty
          ? null
          : _customerNameController.text.trim(),
      phone: _customerPhoneController.text.trim().isEmpty
          ? null
          : _customerPhoneController.text.trim(),
    );
    if (_notesController.text.trim().isNotEmpty) {
      provider.updateNotes(_notesController.text.trim());
    }

    // إتمام البيع
    provider.completeSale().then((success) {
      Navigator.of(context).pop();

      if (success) {
        // إظهار رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إتمام البيع بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );

        // طباعة الفاتورة إذا كان مطلوباً
        if (_printReceipt) {
          // TODO: تنفيذ طباعة الفاتورة
        }

        // إرسال SMS إذا كان مطلوباً
        if (_sendSMS && _customerPhoneController.text.isNotEmpty) {
          // TODO: تنفيذ إرسال SMS
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cashController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class PaymentMethod {
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  PaymentMethod({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}
