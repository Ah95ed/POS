import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/SaleProvider.dart';
import 'package:pos/Model/ProductModel.dart';

/// شاشة نقطة البيع الرئيسية
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadAvailableProducts();
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWideScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: buildAppBar(),
      body: Consumer<SaleProvider>(
        builder: (context, saleProvider, child) {
          if (saleProvider.isLoading && saleProvider.currentSaleItems.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return isWideScreen
              ? _buildWideScreenLayout(saleProvider, screenWidth, screenHeight)
              : _buildMobileLayout(saleProvider, screenWidth, screenHeight);
        },
      ),
    );
  }

  /// بناء شريط التطبيق
  PreferredSizeWidget buildAppBar() {
    return AppBar(
      centerTitle: true,
      title: const Text(
        'نقطة البيع',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        // زر إدارة الفواتير
        IconButton(
          icon: const Icon(Icons.receipt_long, color: Colors.white),
          onPressed: () => _showInvoiceControlDialog(),
          tooltip: 'إدارة الفواتير',
        ),
        Consumer<SaleProvider>(
          builder: (context, provider, child) {
            return IconButton(
              icon: Badge(
                label: Text('${provider.itemCount}'),
                child: const Icon(Icons.shopping_cart, color: Colors.white),
              ),
              onPressed: () => _showCartSummary(provider),
            );
          },
        ),
      ],
    );
  }

  /// بناء تخطيط الشاشة العريضة
  Widget _buildWideScreenLayout(
    SaleProvider provider,
    double width,
    double height,
  ) {
    return Row(
      children: [
        // قسم اختيار المنتجات
        Expanded(flex: 3, child: _buildProductSelection(provider, width * 0.6)),

        // قسم الفاتورة الحالية
        Expanded(
          flex: 2,
          child: _buildCurrentSaleSection(provider, width * 0.4),
        ),
      ],
    );
  }

  /// بناء تخطيط الشاشة المحمولة
  Widget _buildMobileLayout(
    SaleProvider provider,
    double width,
    double height,
  ) {
    return Column(
      children: [
        // شريط البحث والباركود
        _buildSearchBar(provider, width),

        // قائمة المنتجات في الفاتورة
        Expanded(flex: 2, child: _buildCurrentSaleItems(provider, width)),

        // ملخص الفاتورة
        _buildInvoiceSummary(provider, width),

        // أزرار العمليات
        _buildActionButtons(provider, width),
      ],
    );
  }

  /// بناء قسم اختيار المنتجات
  Widget _buildProductSelection(SaleProvider provider, double width) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // شريط البحث
          _buildSearchBar(provider, width),

          const SizedBox(height: 12),

          // قائمة المنتجات
          Expanded(child: _buildProductGrid(provider, width)),
        ],
      ),
    );
  }

  /// بناء شريط البحث والباركود
  Widget _buildSearchBar(SaleProvider provider, double width) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // حقل الباركود
          TextField(
            controller: _barcodeController,
            focusNode: _barcodeFocusNode,
            decoration: InputDecoration(
              hintText: 'امسح الباركود أو أدخل كود المنتج...',
              prefixIcon: const Icon(Icons.qr_code_scanner),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _addProductByCode(provider),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[700]!),
              ),
            ),
            onSubmitted: (_) => _addProductByCode(provider),
          ),

          const SizedBox(height: 12),

          // شريط البحث في المنتجات
          TextField(
            decoration: InputDecoration(
              hintText: 'البحث في المنتجات...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.grid_view),
                onPressed: () => _showProductSelectionDialog(provider),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[700]!),
              ),
            ),
            onChanged: provider.searchProducts,
          ),
        ],
      ),
    );
  }

  /// بناء شبكة المنتجات
  Widget _buildProductGrid(SaleProvider provider, double width) {
    if (provider.filteredProducts.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد منتجات متاحة',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: width > 1200 ? 4 : (width > 800 ? 3 : 2),
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: provider.filteredProducts.length,
      itemBuilder: (context, index) {
        final product = provider.filteredProducts[index];
        return _buildProductCard(product, provider);
      },
    );
  }

  /// بناء بطاقة المنتج
  Widget _buildProductCard(ProductModel product, SaleProvider provider) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => provider.addProductToSale(product),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Icon(Icons.inventory, size: 40, color: Colors.grey[600]),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.salePrice.toStringAsFixed(2)} دينار',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'متوفر: ${product.quantity}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء قسم الفاتورة الحالية
  Widget _buildCurrentSaleSection(SaleProvider provider, double width) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // رأس القسم
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[700],
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'الفاتورة الحالية',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${provider.itemCount} عنصر',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // قائمة العناصر
          Expanded(child: _buildCurrentSaleItems(provider, width)),

          // ملخص الفاتورة
          _buildInvoiceSummary(provider, width),

          // أزرار العمليات
          _buildActionButtons(provider, width),
        ],
      ),
    );
  }

  /// بناء قائمة عناصر الفاتورة الحالية
  Widget _buildCurrentSaleItems(SaleProvider provider, double width) {
    if (provider.currentSaleItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'لا توجد عناصر في الفاتورة',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'ابدأ بإضافة منتجات',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: provider.currentSaleItems.length,
      itemBuilder: (context, index) {
        final item = provider.currentSaleItems[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.inventory, color: Colors.blue[700]),
            ),
            title: Text(
              item.productName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'السعر: ${item.unitPrice.toStringAsFixed(2)} دينار',
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (item.quantity > 1) {
                      provider.updateItemQuantity(index, item.quantity - 1);
                    } else {
                      provider.removeItemFromSale(index);
                    }
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    provider.updateItemQuantity(index, item.quantity + 1);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => provider.removeItemFromSale(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// بناء ملخص الفاتورة
  Widget _buildInvoiceSummary(SaleProvider provider, double width) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'المجموع الفرعي:',
            '${provider.subtotal.toStringAsFixed(2)} دينار',
          ),
          if (provider.discount > 0)
            _buildSummaryRow(
              'الخصم:',
              '- ${provider.discount.toStringAsFixed(2)} دينار',
              color: Colors.red[700],
            ),
          _buildSummaryRow(
            'الضريبة (${provider.taxRate.toStringAsFixed(0)}%):',
            '${provider.taxAmount.toStringAsFixed(2)} دينار',
          ),
          const Divider(thickness: 2),
          _buildSummaryRow(
            'الإجمالي:',
            '${provider.total.toStringAsFixed(2)} دينار',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  /// بناء صف الملخص
  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? color,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: color ?? (isTotal ? Colors.green[700] : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء أزرار العمليات
  Widget _buildActionButtons(SaleProvider provider, double width) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // الصف الأول من الأزرار
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: provider.currentSaleItems.isNotEmpty
                      ? () => _showDiscountDialog(provider)
                      : null,
                  icon: const Icon(Icons.percent),
                  label: const Text('خصم'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: provider.currentSaleItems.isNotEmpty
                      ? () => provider.clearCurrentSale()
                      : null,
                  icon: const Icon(Icons.clear),
                  label: const Text('مسح'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // زر الدفع الرئيسي
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: provider.currentSaleItems.isNotEmpty
                  ? () => _showPaymentDialog(provider)
                  : null,
              icon: const Icon(Icons.payment, size: 24),
              label: Text(
                'دفع (${provider.total.toStringAsFixed(2)} دينار)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// إضافة منتج بالكود
  void _addProductByCode(SaleProvider provider) {
    final code = _barcodeController.text.trim();
    if (code.isNotEmpty) {
      provider.addProductByCode(code).then((success) {
        if (success) {
          _barcodeController.clear();
          _barcodeFocusNode.requestFocus();
        } else {
          _showErrorSnackBar(provider.errorMessage);
        }
      });
    }
  }

  /// عرض نافذة اختيار المنتجات
  void _showProductSelectionDialog(SaleProvider provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('نافذة اختيار المنتجات قيد التطوير')),
    );
  }

  /// عرض نافذة الخصم
  void _showDiscountDialog(SaleProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _DiscountDialog(
        currentDiscount: provider.discount,
        maxDiscount: provider.subtotal,
        onDiscountApplied: (discount) {
          provider.applyGeneralDiscount(discount);
        },
      ),
    );
  }

  /// عرض نافذة الدفع
  void _showPaymentDialog(SaleProvider provider) {
    final TextEditingController paidAmountController = TextEditingController();
    // تعيين المبلغ الافتراضي للإجمالي
    paidAmountController.text = provider.total.toStringAsFixed(2);
    // تحديث المبلغ المدفوع فوراً
    provider.updatePaidAmount(provider.total);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إتمام الدفع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'المبلغ الإجمالي: ${provider.total.toStringAsFixed(2)} دينار',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: paidAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ المدفوع',
                suffixText: 'دينار',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0.0;
                provider.updatePaidAmount(amount);
              },
            ),
            const SizedBox(height: 8),
            Consumer<SaleProvider>(
              builder: (context, provider, child) {
                final change = provider.changeAmount;
                return Text(
                  change > 0
                      ? 'المبلغ المتبقي: ${change.toStringAsFixed(2)} دينار'
                      : change < 0
                      ? 'نقص في المبلغ: ${(-change).toStringAsFixed(2)} دينار'
                      : 'المبلغ مطابق',
                  style: TextStyle(
                    color: change >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          Consumer<SaleProvider>(
            builder: (context, provider, child) {
              return ElevatedButton(
                onPressed: provider.canCompleteSale
                    ? () {
                        provider.completeSale().then((success) {
                          Navigator.of(context).pop();
                          if (success) {
                            _showSuccessSnackBar('تم إتمام البيع بنجاح');
                          } else {
                            _showErrorSnackBar(provider.errorMessage);
                          }
                        });
                      }
                    : null,
                child: const Text('دفع'),
              );
            },
          ),
        ],
      ),
    ).then((_) {
      // تنظيف المبلغ المدفوع عند إغلاق النافذة
      paidAmountController.dispose();
    });
  }

  /// عرض ملخص سريع للعربة
  void _showCartSummary(SaleProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ملخص الفاتورة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('العناصر:', '${provider.itemCount}'),
            _buildSummaryRow(
              'المجموع:',
              '${provider.total.toStringAsFixed(2)} دينار',
            ),
          ],
        ),
      ),
    );
  }

  /// عرض نافذة إدارة الفواتير
  void _showInvoiceControlDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('نافذة إدارة الفواتير قيد التطوير')),
    );
  }

  /// عرض رسالة خطأ
  void _showErrorSnackBar(String message) {
    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  /// عرض رسالة نجاح
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}

/// نافذة الخصم
class _DiscountDialog extends StatefulWidget {
  final double currentDiscount;
  final double maxDiscount;
  final Function(double) onDiscountApplied;

  const _DiscountDialog({
    required this.currentDiscount,
    required this.maxDiscount,
    required this.onDiscountApplied,
  });

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  final TextEditingController _discountController = TextEditingController();
  bool _isPercentage = false;

  @override
  void initState() {
    super.initState();
    _discountController.text = widget.currentDiscount.toString();
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تطبيق خصم'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _discountController,
            decoration: InputDecoration(
              labelText: _isPercentage ? 'نسبة الخصم (%)' : 'مبلغ الخصم',
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _isPercentage,
                onChanged: (value) {
                  setState(() {
                    _isPercentage = value ?? false;
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
        ElevatedButton(
          onPressed: () {
            final input = double.tryParse(_discountController.text) ?? 0;
            double discount;

            if (_isPercentage) {
              discount = widget.maxDiscount * (input / 100);
            } else {
              discount = input;
            }

            discount = discount.clamp(0, widget.maxDiscount);
            widget.onDiscountApplied(discount);
            Navigator.of(context).pop();
          },
          child: const Text('تطبيق'),
        ),
      ],
    );
  }
}
