import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/SaleProvider.dart';
import 'package:pos/Controller/ProductProvider.dart';

/// ويدجت بحث وفلترة متطورة للمنتجات
class EnhancedProductSearchWidget extends StatefulWidget {
  const EnhancedProductSearchWidget({super.key});

  @override
  State<EnhancedProductSearchWidget> createState() =>
      _EnhancedProductSearchWidgetState();
}

class _EnhancedProductSearchWidgetState
    extends State<EnhancedProductSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  String _selectedCategory = 'الكل';
  RangeValues _priceRange = const RangeValues(0, 1000);
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // شريط البحث الرئيسي
          Row(
            children: [
              // حقل البحث
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'البحث في المنتجات...',
                    prefixIcon: const Icon(Icons.search, color: Colors.blue),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showFilters
                            ? Icons.filter_list
                            : Icons.filter_list_off,
                        color: _showFilters ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    context.read<SaleProvider>().searchProducts(value);
                  },
                ),
              ),

              const SizedBox(width: 12),

              // حقل الباركود
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _barcodeController,
                  decoration: InputDecoration(
                    hintText: 'مسح الباركود',
                    prefixIcon: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.green,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.green),
                      onPressed: _addProductByBarcode,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _addProductByBarcode(),
                ),
              ),
            ],
          ),

          // فلاتر متقدمة
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilters ? 140 : 0,
            child: _showFilters ? _buildAdvancedFilters() : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
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
              const Icon(Icons.filter_alt, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'فلاتر متقدمة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              // فلتر الفئة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الفئة:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Consumer<ProductProvider>(
                      builder: (context, productProvider, child) {
                        // قائمة ثابتة من الفئات
                        final categories = [
                          'الكل',
                          'مأكولات',
                          'مشروبات',
                          'مواد تنظيف',
                          'أدوات مكتبية',
                          'إلكترونيات',
                        ];

                        return DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: categories
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                            _applyFilters();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // فلتر نطاق السعر
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نطاق السعر: ${_priceRange.start.toInt()} - ${_priceRange.end.toInt()} د.ع',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 1000,
                      divisions: 20,
                      activeColor: Colors.blue,
                      onChanged: (values) {
                        setState(() {
                          _priceRange = values;
                        });
                      },
                      onChangeEnd: (values) => _applyFilters(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addProductByBarcode() {
    final barcode = _barcodeController.text.trim();
    if (barcode.isNotEmpty) {
      context.read<SaleProvider>().addProductByCode(barcode);
      _barcodeController.clear();
    }
  }

  void _applyFilters() {
    // تطبيق البحث مع الفلاتر
    final searchQuery = _searchController.text.trim();
    context.read<SaleProvider>().searchProducts(searchQuery);

    // يمكن إضافة منطق فلترة إضافي هنا حسب الحاجة
    // مثل فلترة حسب الفئة ونطاق السعر
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }
}
