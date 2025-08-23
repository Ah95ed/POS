import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/InvoiceProvider.dart';
import 'package:pos/Model/InvoiceModel.dart';
import 'package:smart_sizer/smart_sizer.dart';

/// حوار إضافة/تعديل الفاتورة
class InvoiceFormDialog extends StatefulWidget {
  final String title;
  final InvoiceModel? invoice;
  final Function(InvoiceModel) onSave;

  const InvoiceFormDialog({
    super.key,
    required this.title,
    this.invoice,
    required this.onSave,
  });

  @override
  State<InvoiceFormDialog> createState() => _InvoiceFormDialogState();
}

class _InvoiceFormDialogState extends State<InvoiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedStatus = 'pending';
  List<InvoiceItemModel> _items = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.invoice != null) {
      // تعديل فاتورة موجودة
      final invoice = widget.invoice!;
      _invoiceNumberController.text = invoice.invoiceNumber;
      _customerNameController.text = invoice.customerName ?? '';
      _customerPhoneController.text = invoice.customerPhone ?? '';
      _notesController.text = invoice.notes ?? '';
      _selectedDate = invoice.date;
      _selectedStatus = invoice.status;
      _items = List.from(invoice.items);
    } else {
      // إضافة فاتورة جديدة
      _generateInvoiceNumber();
    }
  }

  Future<void> _generateInvoiceNumber() async {
    final provider = context.read<InvoiceProvider>();
    final invoiceNumber = await provider.generateInvoiceNumber();
    if (invoiceNumber != null) {
      _invoiceNumberController.text = invoiceNumber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: context.getWidth(90),
        height: context.getHeight(85),
        padding: EdgeInsets.all(context.getWidth(6)),
        child: Column(
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
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // رقم الفاتورة
                      TextFormField(
                        controller: _invoiceNumberController,
                        decoration: const InputDecoration(
                          labelText: 'رقم الفاتورة',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.receipt),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'رقم الفاتورة مطلوب';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: context.getWidth(4)),

                      // معلومات العميل
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _customerNameController,
                              decoration: const InputDecoration(
                                labelText: 'اسم العميل',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                            ),
                          ),
                          SizedBox(width: context.getWidth(3)),
                          Expanded(
                            child: TextFormField(
                              controller: _customerPhoneController,
                              decoration: const InputDecoration(
                                labelText: 'رقم الهاتف',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: context.getWidth(4)),

                      // التاريخ والحالة
                      Row(
                        children: [
                          // التاريخ
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'تاريخ الفاتورة',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: context.getWidth(3)),
                          // الحالة
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'حالة الفاتورة',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.info),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'pending',
                                  child: Text('معلقة'),
                                ),
                                DropdownMenuItem(
                                  value: 'paid',
                                  child: Text('مدفوعة'),
                                ),
                                DropdownMenuItem(
                                  value: 'overdue',
                                  child: Text('متأخرة'),
                                ),
                                DropdownMenuItem(
                                  value: 'cancelled',
                                  child: Text('ملغية'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: context.getWidth(4)),

                      // عناصر الفاتورة
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'عناصر الفاتورة',
                            style: TextStyle(
                              fontSize: context.getFontSize(16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة عنصر'),
                          ),
                        ],
                      ),

                      SizedBox(height: context.getWidth(2)),

                      // قائمة العناصر
                      if (_items.isEmpty)
                        Container(
                          padding: EdgeInsets.all(context.getWidth(4)),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'لا توجد عناصر في الفاتورة',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: context.getFontSize(14),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: context.getHeight(30),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return _buildItemCard(item, index);
                            },
                          ),
                        ),

                      SizedBox(height: context.getWidth(4)),

                      // إجمالي المبلغ
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
                              'إجمالي المبلغ:',
                              style: TextStyle(
                                fontSize: context.getFontSize(16),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_calculateTotal().toStringAsFixed(2)} ر.س',
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

                      // الملاحظات
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: context.getWidth(4)),

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
                  onPressed: _isLoading ? null : _saveInvoice,
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

  /// بناء بطاقة العنصر
  Widget _buildItemCard(InvoiceItemModel item, int index) {
    return Card(
      margin: EdgeInsets.all(context.getWidth(2)),
      child: Padding(
        padding: EdgeInsets.all(context.getWidth(3)),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: TextStyle(
                      fontSize: context.getFontSize(14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.productCode.isNotEmpty)
                    Text(
                      'كود: ${item.productCode}',
                      style: TextStyle(
                        fontSize: context.getFontSize(12),
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Text(
                '${item.quantity}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: context.getFontSize(14)),
              ),
            ),
            Expanded(
              child: Text(
                item.price.toStringAsFixed(2),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: context.getFontSize(14)),
              ),
            ),
            Expanded(
              child: Text(
                item.total.toStringAsFixed(2),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.getFontSize(14),
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ),
            IconButton(
              onPressed: () => _removeItem(index),
              icon: Icon(Icons.delete, color: Colors.red[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// اختيار التاريخ
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// إضافة عنصر جديد
  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => _ItemFormDialog(
        onSave: (item) {
          setState(() {
            _items.add(item);
          });
        },
      ),
    );
  }

  /// حذف عنصر
  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  /// حساب الإجمالي
  double _calculateTotal() {
    return _items.fold(0.0, (sum, item) => sum + item.total);
  }

  /// حفظ الفاتورة
  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب إضافة عنصر واحد على الأقل'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final invoice = InvoiceModel(
        id: widget.invoice?.id,
        customerId: widget.invoice?.customerId,
        invoiceNumber: _invoiceNumberController.text.trim(),
        date: _selectedDate,
        totalAmount: _calculateTotal(),
        status: _selectedStatus,
        customerName: _customerNameController.text.trim().isEmpty
            ? null
            : _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim().isEmpty
            ? null
            : _customerPhoneController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        items: _items,
        createdAt: widget.invoice?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(invoice);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// حوار إضافة عنصر للفاتورة
class _ItemFormDialog extends StatefulWidget {
  final Function(InvoiceItemModel) onSave;

  const _ItemFormDialog({required this.onSave});

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _productCodeController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _productNameController.dispose();
    _productCodeController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة عنصر'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _productNameController,
              decoration: const InputDecoration(
                labelText: 'اسم المنتج',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'اسم المنتج مطلوب';
                }
                return null;
              },
            ),
            SizedBox(height: context.getWidth(3)),
            TextFormField(
              controller: _productCodeController,
              decoration: const InputDecoration(
                labelText: 'كود المنتج (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: context.getWidth(3)),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'الكمية',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الكمية مطلوبة';
                      }
                      if (int.tryParse(value) == null ||
                          int.parse(value) <= 0) {
                        return 'كمية غير صحيحة';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: context.getWidth(3)),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'السعر',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'السعر مطلوب';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'سعر غير صحيح';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(onPressed: _saveItem, child: const Text('إضافة')),
      ],
    );
  }

  void _saveItem() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantity = int.parse(_quantityController.text);
    final price = double.parse(_priceController.text);
    final total = quantity * price;

    final item = InvoiceItemModel(
      productId: 0, 
      productName: _productNameController.text.trim(),
      productCode: _productCodeController.text.trim(),
      quantity: quantity,
      price: price,
      total: total,
    );

    widget.onSave(item);
    Navigator.of(context).pop();
  }
}
