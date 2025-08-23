import 'package:flutter/material.dart';
import 'package:pos/Model/SaleModel.dart';

/// حوار نموذج العميل للإضافة والتعديل
class CustomerFormDialog extends StatefulWidget {
  final String title;
  final CustomerModel? customer;
  final Function(CustomerModel) onSave;

  const CustomerFormDialog({
    super.key,
    required this.title,
    this.customer,
    required this.onSave,
  });

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _pointsController = TextEditingController();

  bool _isVip = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  /// تهيئة النموذج
  void _initializeForm() {
    if (widget.customer != null) {
      final customer = widget.customer!;
      _nameController.text = customer.name;
      _phoneController.text = customer.phone ?? '';
      _emailController.text = customer.email ?? '';
      _addressController.text = customer.address ?? '';
      _pointsController.text = customer.points.toString();
      _isVip = customer.isVip;
    } else {
      _pointsController.text = '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // رأس الحوار
            _buildDialogHeader(),

            // محتوى النموذج
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildForm(),
              ),
            ),

            // أزرار الحوار
            _buildDialogActions(),
          ],
        ),
      ),
    );
  }

  /// بناء رأس الحوار
  Widget _buildDialogHeader() {
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
          Icon(
            widget.customer == null ? Icons.person_add : Icons.edit,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
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

  /// بناء النموذج
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اسم العميل
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'اسم العميل *',
              hintText: 'أدخل اسم العميل',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[700]!),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'اسم العميل مطلوب';
              }
              if (value.trim().length < 2) {
                return 'اسم العميل يجب أن يكون أكثر من حرف واحد';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 16),

          // رقم الهاتف
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'رقم الهاتف',
              hintText: 'أدخل رقم الهاتف',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[700]!),
              ),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (value.length < 10) {
                  return 'رقم الهاتف يجب أن يكون 10 أرقام على الأقل';
                }
                if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(value)) {
                  return 'رقم الهاتف غير صحيح';
                }
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 16),

          // البريد الإلكتروني
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'البريد الإلكتروني',
              hintText: 'أدخل البريد الإلكتروني',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[700]!),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'البريد الإلكتروني غير صحيح';
                }
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 16),

          // العنوان
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'العنوان',
              hintText: 'أدخل العنوان',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[700]!),
              ),
            ),
            maxLines: 2,
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 16),

          // النقاط
          TextFormField(
            controller: _pointsController,
            decoration: InputDecoration(
              labelText: 'النقاط',
              hintText: 'أدخل عدد النقاط',
              prefixIcon: const Icon(Icons.stars),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[700]!),
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final points = int.tryParse(value);
                if (points == null || points < 0) {
                  return 'النقاط يجب أن تكون رقم صحيح موجب';
                }
              }
              return null;
            },
            textInputAction: TextInputAction.done,
          ),

          const SizedBox(height: 20),

          // حالة العميل المميز
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.star,
                  color: _isVip ? Colors.amber[700] : Colors.grey[400],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'عميل مميز (VIP)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'العملاء المميزون يحصلون على مزايا خاصة',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isVip,
                  onChanged: (value) {
                    setState(() {
                      _isVip = value;
                    });
                  },
                  activeColor: Colors.amber[700],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء أزرار الحوار
  Widget _buildDialogActions() {
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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveCustomer,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(widget.customer == null ? 'إضافة' : 'تحديث'),
          ),
        ],
      ),
    );
  }

  /// حفظ العميل
  void _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final customer = CustomerModel(
        id: widget.customer?.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        points: int.tryParse(_pointsController.text) ?? 0,
        totalPurchases: widget.customer?.totalPurchases ?? 0.0,
        isVip: _isVip,
        createdAt: widget.customer?.createdAt ?? DateTime.now(),
      );

      widget.onSave(customer);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ البيانات: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
