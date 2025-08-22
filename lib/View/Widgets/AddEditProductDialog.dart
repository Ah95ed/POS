import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/ProductProvider.dart';
import 'package:pos/Model/ProductModel.dart';

/// نافذة إضافة/تعديل المنتج
class AddEditProductDialog extends StatefulWidget {
  final ProductModel? product;

  const AddEditProductDialog({super.key, this.product});

  @override
  State<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _companyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lowStockThresholdController = TextEditingController();

  DateTime? _selectedExpiryDate;
  bool _isLoading = false;
  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _salePriceController.dispose();
    _buyPriceController.dispose();
    _quantityController.dispose();
    _companyController.dispose();
    _descriptionController.dispose();
    _lowStockThresholdController.dispose();
    super.dispose();
  }

  /// تهيئة الحقول
  void _initializeFields() {
    if (_isEditing) {
      final product = widget.product!;
      _nameController.text = product.name;
      _codeController.text = product.code;
      _salePriceController.text = product.salePrice.toString();
      _buyPriceController.text = product.buyPrice.toString();
      _quantityController.text = product.quantity.toString();
      _companyController.text = product.company;
      _descriptionController.text = product.description;
      _lowStockThresholdController.text = product.lowStockThreshold.toString();
      _selectedExpiryDate = product.expiryDate;
    } else {
      // القيم الافتراضية للمنتج الجديد
      _lowStockThresholdController.text = '5';
    }
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
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildForm(),
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
        color: Colors.blue[700],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isEditing ? Icons.edit : Icons.add,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isEditing ? 'تعديل المنتج' : 'إضافة منتج جديد',
              style: const TextStyle(
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

  /// بناء النموذج
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اسم المنتج
          _buildTextField(
            controller: _nameController,
            label: 'اسم المنتج',
            icon: Icons.inventory_2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'اسم المنتج مطلوب';
              }
              if (value.trim().length < 2) {
                return 'اسم المنتج يجب أن يكون أكثر من حرفين';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // كود المنتج
          _buildTextField(
            controller: _codeController,
            label: 'كود المنتج',
            icon: Icons.qr_code,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'كود المنتج مطلوب';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // الأسعار في صف واحد
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _buyPriceController,
                  label: 'سعر الشراء',
                  icon: Icons.shopping_cart,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'سعر الشراء مطلوب';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'سعر غير صحيح';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _salePriceController,
                  label: 'سعر البيع',
                  icon: Icons.sell,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'سعر البيع مطلوب';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'سعر غير صحيح';
                    }

                    // التحقق من أن سعر البيع أكبر من سعر الشراء
                    final buyPrice = double.tryParse(_buyPriceController.text);
                    if (buyPrice != null && price <= buyPrice) {
                      return 'سعر البيع يجب أن يكون أكبر من سعر الشراء';
                    }

                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // الكمية وحد التنبيه في صف واحد
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _quantityController,
                  label: 'الكمية',
                  icon: Icons.numbers,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الكمية مطلوبة';
                    }
                    final quantity = int.tryParse(value);
                    if (quantity == null || quantity < 0) {
                      return 'كمية غير صحيحة';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _lowStockThresholdController,
                  label: 'حد التنبيه',
                  icon: Icons.warning,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'حد التنبيه مطلوب';
                    }
                    final threshold = int.tryParse(value);
                    if (threshold == null || threshold < 0) {
                      return 'حد تنبيه غير صحيح';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // الشركة
          _buildTextField(
            controller: _companyController,
            label: 'الشركة (اختياري)',
            icon: Icons.business,
          ),

          const SizedBox(height: 16),

          // الوصف
          _buildTextField(
            controller: _descriptionController,
            label: 'وصف المنتج (اختياري)',
            icon: Icons.description,
            maxLines: 3,
          ),

          const SizedBox(height: 16),

          // تاريخ انتهاء الصلاحية
          _buildExpiryDateField(),

          const SizedBox(height: 24),

          // معاينة الربح
          _buildProfitPreview(),
        ],
      ),
    );
  }

  /// بناء حقل النص
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}), // لتحديث معاينة الربح
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[700]!),
        ),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }

  /// بناء حقل تاريخ انتهاء الصلاحية
  Widget _buildExpiryDateField() {
    return InkWell(
      onTap: () => _selectExpiryDate(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تاريخ انتهاء الصلاحية (اختياري)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedExpiryDate != null
                        ? '${_selectedExpiryDate!.day}/${_selectedExpiryDate!.month}/${_selectedExpiryDate!.year}'
                        : 'اختر تاريخ انتهاء الصلاحية',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedExpiryDate != null
                          ? Colors.black87
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedExpiryDate != null)
              IconButton(
                onPressed: () => setState(() => _selectedExpiryDate = null),
                icon: const Icon(Icons.clear, color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  /// اختيار تاريخ انتهاء الصلاحية
  Future<void> _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedExpiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 سنوات
      locale: const Locale('ar'),
    );

    if (date != null) {
      setState(() => _selectedExpiryDate = date);
    }
  }

  /// بناء معاينة الربح
  Widget _buildProfitPreview() {
    final buyPrice = double.tryParse(_buyPriceController.text) ?? 0;
    final salePrice = double.tryParse(_salePriceController.text) ?? 0;
    final quantity = int.tryParse(_quantityController.text) ?? 0;

    final profitPerUnit = salePrice - buyPrice;
    final totalProfit = profitPerUnit * quantity;

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
              Icon(Icons.calculate, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'معاينة الربح',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildProfitItem(
                  'الربح للوحدة',
                  '${profitPerUnit.toStringAsFixed(2)} ر.س',
                  profitPerUnit > 0 ? Colors.green : Colors.red,
                ),
              ),
              Expanded(
                child: _buildProfitItem(
                  'إجمالي الربح',
                  '${totalProfit.toStringAsFixed(2)} ر.س',
                  totalProfit > 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء عنصر الربح
  Widget _buildProfitItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  /// بناء أزرار العمليات
  Widget _buildActions() {
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
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
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
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_isEditing ? 'تحديث' : 'إضافة'),
            ),
          ),
        ],
      ),
    );
  }

  /// حفظ المنتج
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final product = ProductModel(
        id: _isEditing ? widget.product!.id : null,
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        salePrice: double.parse(_salePriceController.text),
        buyPrice: double.parse(_buyPriceController.text),
        quantity: int.parse(_quantityController.text),
        company: _companyController.text.trim(),
        date: _isEditing
            ? widget.product!.date
            : DateTime.now().toString().split(' ')[0],
        description: _descriptionController.text.trim(),
        expiryDate: _selectedExpiryDate,
        lowStockThreshold: int.parse(_lowStockThresholdController.text),
        isArchived: _isEditing ? widget.product!.isArchived : false,
      );

      final provider = context.read<ProductProvider>();
      bool success;

      if (_isEditing) {
        success = await provider.updateProduct(product);
      } else {
        success = await provider.addProduct(product);
      }

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'تم تحديث المنتج بنجاح' : 'تم إضافة المنتج بنجاح',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage.isNotEmpty
                  ? provider.errorMessage
                  : 'حدث خطأ غير متوقع',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
