import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/POSProvider.dart';
import 'package:pos/Model/ProductModel.dart';
import 'package:pos/View/Widgets/ProductGridWidget.dart';
import 'package:pos/View/Widgets/SaleItemWidget.dart';
import 'package:pos/View/Widgets/PaymentDialog.dart';
import 'package:pos/Helper/Constants/AppConstants.dart';

/// شاشة نقطة البيع الرئيسية
class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<POSProvider>().refreshData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWideScreen = screenWidth > 1200;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: Consumer<POSProvider>(
        builder: (context, posProvider, child) {
          if (posProvider.isLoading && posProvider.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return isWideScreen
              ? _buildWideScreenLayout(posProvider, screenWidth, screenHeight)
              : _buildNarrowScreenLayout(
                  posProvider,
                  screenWidth,
                  screenHeight,
                );
        },
      ),
    );
  }

  /// بناء شريط التطبيق
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'نقطة البيع',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: Colors.green[700],
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        Consumer<POSProvider>(
          builder: (context, provider, child) {
            return IconButton(
              icon: Badge(
                label: Text('${provider.totalItems}'),
                isLabelVisible: provider.hasItems,
                child: const Icon(Icons.shopping_cart, color: Colors.white),
              ),
              onPressed: provider.hasItems
                  ? () => _showCartBottomSheet(context, provider)
                  : null,
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            context.read<POSProvider>().refreshData();
          },
        ),
      ],
    );
  }

  /// تخطيط الشاشات الواسعة
  Widget _buildWideScreenLayout(
    POSProvider provider,
    double screenWidth,
    double screenHeight,
  ) {
    return Row(
      children: [
        // قسم المنتجات (الجانب الأيسر)
        Expanded(
          flex: 2,
          child: _buildProductsSection(
            provider,
            screenWidth * 0.6,
            screenHeight,
          ),
        ),

        // فاصل
        Container(width: 1, color: Colors.grey[300]),

        // قسم الفاتورة (الجانب الأيمن)
        SizedBox(
          width: screenWidth * 0.4,
          child: _buildInvoiceSection(
            provider,
            screenWidth * 0.4,
            screenHeight,
          ),
        ),
      ],
    );
  }

  /// تخطيط الشاشات الضيقة
  Widget _buildNarrowScreenLayout(
    POSProvider provider,
    double screenWidth,
    double screenHeight,
  ) {
    return Column(
      children: [
        // شريط البحث والباركود
        _buildSearchSection(provider, screenWidth),

        // قسم المنتجات
        Expanded(
          child: _buildProductsSection(
            provider,
            screenWidth,
            screenHeight * 0.7,
          ),
        ),

        // شريط الفاتورة السريع
        if (provider.hasItems) _buildQuickInvoiceBar(provider, screenWidth),
      ],
    );
  }

  /// بناء قسم البحث
  Widget _buildSearchSection(POSProvider provider, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      color: Colors.white,
      child: Column(
        children: [
          // شريط البحث
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'البحث في المنتجات...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[700]!),
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),

          const SizedBox(height: 12),

          // شريط الباركود
          TextField(
            controller: _barcodeController,
            focusNode: _barcodeFocusNode,
            decoration: InputDecoration(
              hintText: 'مسح الباركود أو إدخال الكود...',
              prefixIcon: const Icon(Icons.qr_code_scanner),
              suffixIcon: IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: () {
                  // TODO: فتح كاميرا الباركود
                  _showBarcodeScanner();
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[700]!),
              ),
            ),
            onSubmitted: (code) {
              _addProductByCode(provider, code);
              _barcodeController.clear();
            },
          ),
        ],
      ),
    );
  }

  /// بناء قسم المنتجات
  Widget _buildProductsSection(
    POSProvider provider,
    double width,
    double height,
  ) {
    final searchQuery = _searchController.text;
    final filteredProducts = provider.searchProducts(searchQuery);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // عنوان القسم
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'المنتجات (${filteredProducts.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),

          // شبكة المنتجات
          Expanded(
            child: ProductGridWidget(
              products: filteredProducts,
              onProductTap: (product) => _addProductToSale(provider, product),
              crossAxisCount: _calculateCrossAxisCount(width),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء قسم الفاتورة
  Widget _buildInvoiceSection(
    POSProvider provider,
    double width,
    double height,
  ) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // رأس الفاتورة
          _buildInvoiceHeader(provider, width),

          // عناصر الفاتورة
          Expanded(child: _buildInvoiceItems(provider, width)),

          // ملخص الفاتورة
          _buildInvoiceSummary(provider, width),

          // أزرار العمليات
          _buildInvoiceActions(provider, width),
        ],
      ),
    );
  }

  /// بناء رأس الفاتورة
  Widget _buildInvoiceHeader(POSProvider provider, double width) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                'الفاتورة الحالية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const Spacer(),
              if (provider.hasItems)
                IconButton(
                  icon: const Icon(Icons.clear_all, color: Colors.red),
                  onPressed: () => _showCancelConfirmation(provider),
                  tooltip: 'إلغاء الفاتورة',
                ),
            ],
          ),

          const SizedBox(height: 12),

          // معلومات العميل
          _buildCustomerSection(provider, width),
        ],
      ),
    );
  }

  /// بناء قسم العميل
  Widget _buildCustomerSection(POSProvider provider, double width) {
    return InkWell(
      onTap: () => _showCustomerSelection(provider),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              provider.selectedCustomer != null
                  ? Icons.person
                  : Icons.person_add,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                provider.selectedCustomer?.name ?? 'اختيار عميل (اختياري)',
                style: TextStyle(
                  color: provider.selectedCustomer != null
                      ? Colors.black
                      : Colors.grey[600],
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  /// بناء عناصر الفاتورة
  Widget _buildInvoiceItems(POSProvider provider, double width) {
    if (!provider.hasItems) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد منتجات في الفاتورة',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على المنتجات لإضافتها',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: provider.currentSaleItems.length,
      itemBuilder: (context, index) {
        final item = provider.currentSaleItems[index];
        return SaleItemWidget(
          item: item,
          onQuantityChanged: (quantity) {
            provider.updateItemQuantity(item.productId, quantity);
          },
          onRemove: () {
            provider.removeItemFromSale(item.productId);
          },
          onDiscountApplied: (discount) {
            provider.applyItemDiscount(item.productId, discount);
          },
        );
      },
    );
  }

  /// بناء ملخص الفاتورة
  Widget _buildInvoiceSummary(POSProvider provider, double width) {
    if (!provider.hasItems) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('المجموع الفرعي:', provider.subtotal),
          if (provider.tax > 0)
            _buildSummaryRow('الضريبة (${provider.tax}%):', provider.taxAmount),
          if (provider.discount > 0)
            _buildSummaryRow(
              'الخصم (${provider.discount}%):',
              -provider.discountAmount,
            ),
          const Divider(),
          _buildSummaryRow('الإجمالي:', provider.total, isTotal: true),
        ],
      ),
    );
  }

  /// بناء صف الملخص
  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
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
              color: isTotal ? Colors.green[700] : Colors.black,
            ),
          ),
          Text(
            AppConstants.formatCurrency(amount),
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green[700] : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء أزرار العمليات
  Widget _buildInvoiceActions(POSProvider provider, double width) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // أزرار الخصم والضريبة
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: provider.hasItems
                      ? () => _showDiscountDialog(provider)
                      : null,
                  icon: const Icon(Icons.percent),
                  label: const Text('خصم'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: provider.hasItems
                      ? () => _showTaxDialog(provider)
                      : null,
                  icon: const Icon(Icons.receipt),
                  label: const Text('ضريبة'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // زر الدفع
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: provider.hasItems && !provider.isLoading
                  ? () => _showPaymentDialog(provider)
                  : null,
              icon: provider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.payment),
              label: Text(
                provider.isLoading
                    ? 'جاري المعالجة...'
                    : 'دفع (${AppConstants.formatCurrency(provider.total)})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
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

  /// بناء شريط الفاتورة السريع
  Widget _buildQuickInvoiceBar(POSProvider provider, double width) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${provider.totalItems} منتج',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  AppConstants.formatCurrency(provider.total),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showPaymentDialog(provider),
            icon: const Icon(Icons.payment),
            label: const Text('دفع'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// حساب عدد الأعمدة في الشبكة
  int _calculateCrossAxisCount(double width) {
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 2;
  }

  /// إضافة منتج للفاتورة
  void _addProductToSale(POSProvider provider, ProductModel product) {
    provider.addProductToSale(product);

    if (provider.errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// إضافة منتج بالكود
  void _addProductByCode(POSProvider provider, String code) {
    final product = provider.getProductByCode(code);
    if (product != null) {
      _addProductToSale(provider, product);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم العثور على منتج بهذا الكود'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// عرض نافذة الدفع
  void _showPaymentDialog(POSProvider provider) {
    showDialog(
      context: context,
      builder: (context) => PaymentDialog(
        total: provider.total,
        onPaymentCompleted:
            (paymentMethod, paidAmount, customerName, customerPhone) async {
              // تحديث بيانات الدفع
              provider.setPaymentMethod(paymentMethod);
              if (customerName != null) {
                provider.setCustomerName(customerName);
              }
              if (customerPhone != null) {
                provider.setCustomerPhone(customerPhone);
              }

              final success = await provider.completeSale(paidAmount);

              if (success && mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إتمام البيع بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      provider.errorMessage.isNotEmpty
                          ? provider.errorMessage
                          : 'حدث خطأ أثناء إتمام البيع',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
      ),
    );
  }

  /// عرض نافذة الخصم
  void _showDiscountDialog(POSProvider provider) {
    final controller = TextEditingController(
      text: provider.discount.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تطبيق خصم'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'نسبة الخصم (%)',
            suffixText: '%',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final discount = double.tryParse(controller.text) ?? 0;
              provider.setDiscount(discount);
              Navigator.of(context).pop();
            },
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  /// عرض نافذة الضريبة
  void _showTaxDialog(POSProvider provider) {
    final controller = TextEditingController(text: provider.tax.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تطبيق ضريبة'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'نسبة الضريبة (%)',
            suffixText: '%',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final tax = double.tryParse(controller.text) ?? 0;
              provider.setTax(tax);
              Navigator.of(context).pop();
            },
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  /// عرض اختيار العميل
  void _showCustomerSelection(POSProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختيار عميل'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: provider.customers.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: const Icon(Icons.person_off),
                  title: const Text('بدون عميل'),
                  onTap: () {
                    provider.setCustomer(null);
                    Navigator.of(context).pop();
                  },
                );
              }

              final customer = provider.customers[index - 1];
              return ListTile(
                leading: Icon(
                  customer.isVip ? Icons.star : Icons.person,
                  color: customer.isVip ? Colors.amber : null,
                ),
                title: Text(customer.name),
                subtitle: Text(customer.phone ?? ''),
                onTap: () {
                  provider.setCustomer(customer);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  /// عرض تأكيد الإلغاء
  void _showCancelConfirmation(POSProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الإلغاء'),
        content: const Text('هل أنت متأكد من إلغاء الفاتورة الحالية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لا'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.cancelCurrentSale();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'نعم، إلغاء',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// عرض قائمة السلة
  void _showCartBottomSheet(BuildContext context, POSProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart),
                    const SizedBox(width: 8),
                    Text(
                      'سلة المشتريات (${provider.totalItems})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildInvoiceItems(
                  provider,
                  MediaQuery.of(context).size.width,
                ),
              ),
              _buildInvoiceSummary(provider, MediaQuery.of(context).size.width),
              _buildInvoiceActions(provider, MediaQuery.of(context).size.width),
            ],
          ),
        ),
      ),
    );
  }

  /// عرض ماسح الباركود
  void _showBarcodeScanner() {
    // TODO: تنفيذ ماسح الباركود
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ماسح الباركود قيد التطوير'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
