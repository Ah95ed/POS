import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/Model/DebtModel.dart';
import 'package:smart_sizer/smart_sizer.dart';

/// حوار إضافة/تعديل الدين
class DebtFormDialog extends StatefulWidget {
  final String title;
  final DebtModel? debt;
  final Function(DebtModel) onSave;

  const DebtFormDialog({
    super.key,
    required this.title,
    this.debt,
    required this.onSave,
  });

  @override
  State<DebtFormDialog> createState() => _DebtFormDialogState();
}

class _DebtFormDialogState extends State<DebtFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _partyNameController = TextEditingController();
  final _partyPhoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedPartyType = 'customer';
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _partyNameController.dispose();
    _partyPhoneController.dispose();
    _amountController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.debt != null) {
      // تعديل دين موجود
      final debt = widget.debt!;
      _partyNameController.text = debt.partyName;
      _partyPhoneController.text = debt.partyPhone ?? '';
      _amountController.text = debt.amount.toStringAsFixed(0);
      _paidAmountController.text = debt.paidAmount.toStringAsFixed(0);
      _notesController.text = debt.notes ?? '';
      _selectedPartyType = debt.partyType;
      _selectedDueDate = debt.dueDate;
    } else {
      // إضافة دين جديد
      _paidAmountController.text = '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: context.getWidth(300),
        height: context.getHeight(400),
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
                      // نوع الطرف
                      Text(
                        'نوع الطرف',
                        style: TextStyle(
                          fontSize: context.getFontSize(14),
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: context.getWidth(2)),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('عميل'),
                              value: 'customer',
                              groupValue: _selectedPartyType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedPartyType = value!;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('مورد'),
                              value: 'supplier',
                              groupValue: _selectedPartyType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedPartyType = value!;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: context.getWidth(4)),

                      // اسم العميل/المورد
                      TextFormField(
                        controller: _partyNameController,
                        decoration: InputDecoration(
                          labelText: _selectedPartyType == 'customer'
                              ? 'اسم العميل'
                              : 'اسم المورد',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(
                            _selectedPartyType == 'customer'
                                ? Icons.person
                                : Icons.business,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الاسم مطلوب';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: context.getWidth(4)),

                      // رقم الهاتف
                      TextFormField(
                        controller: _partyPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'رقم الهاتف (اختياري)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),

                      SizedBox(height: context.getWidth(4)),

                      // المبلغ الكلي
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'المبلغ الكلي (د.ع)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.money),
                          suffixText: 'د.ع',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'المبلغ مطلوب';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'المبلغ يجب أن يكون أكبر من صفر';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: context.getWidth(4)),

                      // المبلغ المدفوع
                      TextFormField(
                        controller: _paidAmountController,
                        decoration: const InputDecoration(
                          labelText: 'المبلغ المدفوع (د.ع)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.payment),
                          suffixText: 'د.ع',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'المبلغ المدفوع مطلوب';
                          }
                          final paidAmount = double.tryParse(value);
                          if (paidAmount == null || paidAmount < 0) {
                            return 'المبلغ المدفوع يجب أن يكون صفر أو أكبر';
                          }
                          final totalAmount =
                              double.tryParse(_amountController.text) ?? 0;
                          if (paidAmount > totalAmount) {
                            return 'المبلغ المدفوع لا يمكن أن يتجاوز المبلغ الكلي';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: context.getWidth(4)),

                      // تاريخ الاستحقاق
                      InkWell(
                        onTap: _selectDueDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'تاريخ الاستحقاق',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            '${_selectedDueDate.day}/${_selectedDueDate.month}/${_selectedDueDate.year}',
                          ),
                        ),
                      ),

                      SizedBox(height: context.getWidth(4)),

                      // المبلغ المتبقي (للعرض فقط)
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
                              '${_calculateRemainingAmount().toStringAsFixed(0)} د.ع',
                              style: TextStyle(
                                fontSize: context.getFontSize(14),
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
                          labelText: 'ملاحظات (اختياري)',
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
                  onPressed: _isLoading ? null : _saveDebt,
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

  /// اختيار تاريخ الاستحقاق
  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('ar'),
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  /// حساب المبلغ المتبقي
  double _calculateRemainingAmount() {
    final totalAmount = double.tryParse(_amountController.text) ?? 0;
    final paidAmount = double.tryParse(_paidAmountController.text) ?? 0;
    return totalAmount - paidAmount;
  }

  /// حفظ الدين
  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final totalAmount = double.parse(_amountController.text);
      final paidAmount = double.parse(_paidAmountController.text);
      final remainingAmount = totalAmount - paidAmount;

      // تحديد الحالة بناءً على المبلغ المدفوع
      String status;
      if (paidAmount <= 0) {
        status = 'unpaid';
      } else if (paidAmount >= totalAmount) {
        status = 'paid';
      } else {
        status = 'partiallyPaid';
      }

      final debt = DebtModel(
        id: widget.debt?.id,
        partyId: widget.debt?.partyId ?? 0, // سيتم تعيينه في المستودع
        partyType: _selectedPartyType,
        partyName: _partyNameController.text.trim(),
        partyPhone: _partyPhoneController.text.trim().isEmpty
            ? null
            : _partyPhoneController.text.trim(),
        amount: totalAmount,
        paidAmount: paidAmount,
        remainingAmount: remainingAmount,
        dueDate: _selectedDueDate,
        status: status,
        archived: widget.debt?.archived ?? false,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.debt?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(debt);
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
