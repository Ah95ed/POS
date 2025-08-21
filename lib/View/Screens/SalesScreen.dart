import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/SaleProvider.dart';
import 'package:pos/Model/SaleModel.dart';
import 'package:pos/Model/ProductModel.dart';
import 'package:pos/View/Widgets/SaleItemCard.dart';
import 'package:pos/View/Widgets/ProductSelectionDialog.dart';
import 'package:pos/View/Widgets/PaymentDialog.dart';
import 'package:pos/Helper/Service/PrintService.dart';
import 'package:pos/Helper/Service/RefundService.dart';

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
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
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
        IconButton(
          icon: const Icon(Icons.print, color: Colors.white),
          onPressed: _showPrintOptions,
          tooltip: 'طباعة',
        ),
        IconButton(
          icon: const Icon(Icons.assignment_return, color: Colors.white),
          onPressed: _showRefundDialog,
          tooltip: 'إرجاع',
        ),
        IconButton(
          icon: const Icon(Icons.history, color: Colors.white),
          onPressed: _showSalesHistory,
          tooltip: 'السجل',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'settings':
                _showSettings();
                break;
              case 'reports':
                _showReports();
                break;
              case 'backup':
                _showBackupOptions();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('الإعدادات'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'reports',
              child: Row(
                children: [
                  Icon(Icons.analytics),
                  SizedBox(width: 8),
                  Text('التقارير'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'backup',
              child: Row(
                children: [
                  Icon(Icons.backup),
                  SizedBox(width: 8),
                  Text('النسخ الاحتياطي'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// تخطيط الشاشات الكبيرة
  Widget _buildWideScreenLayout(
    SaleProvider provider,
    double screenWidth,
    double screenHeight,
  ) {
    return Row(
      children: [
        // الجانب الأيسر - اختيار المنتجات
        Expanded(
          flex: 2,
          child: _buildProductSelection(provider, screenWidth * 0.6),
        ),

        // الجانب الأيمن - الفاتورة والدفع
        Expanded(
          flex: 1,
          child: _buildInvoicePanel(provider, screenWidth * 0.4, screenHeight),
        ),
      ],
    );
  }

  /// تخطيط الشاشات الصغيرة
  Widget _buildMobileLayout(
    SaleProvider provider,
    double screenWidth,
    double screenHeight,
  ) {
    return Column(
      children: [
        // شريط البحث والباركود
        _buildSearchBar(provider, screenWidth),

        // قائمة المنتجات في الفاتورة
        Expanded(flex: 2, child: _buildCurrentSaleItems(provider, screenWidth)),

        // ملخص الفاتورة
        _buildInvoiceSummary(provider, screenWidth),

        // أزرار العمليات
        _buildActionButtons(provider, screenWidth),
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

          const SizedBox(height: 16),

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
      return _buildEmptyProductsState();
    }

    final crossAxisCount = (width / 200).floor().clamp(2, 6);

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => provider.addProductToSale(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // اسم المنتج
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 8),

              // السعر والكمية
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${product.salePrice.toStringAsFixed(2)} ر.س',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: product.isLowStock
                          ? Colors.orange[100]
                          : Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${product.quantity}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: product.isLowStock
                            ? Colors.orange[700]
                            : Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // كود المنتج
              Text(
                product.code,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء حالة المنتجات الفارغة
  Widget _buildEmptyProductsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد منتجات متاحة',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'تأكد من وجود منتجات في المخزون',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// بناء لوحة الفاتورة
  Widget _buildInvoicePanel(
    SaleProvider provider,
    double width,
    double height,
  ) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // عنوان الفاتورة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[700],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'الفاتورة الحالية',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${provider.itemCount} صنف',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),

          // قائمة المنتجات في الفاتورة
          Expanded(child: _buildCurrentSaleItems(provider, width)),

          // ملخص الفاتورة
          _buildInvoiceSummary(provider, width),

          // أزرار العمليات
          _buildActionButtons(provider, width),
        ],
      ),
    );
  }

  /// بناء قائمة المنتجات في الفاتورة الحالية
  Widget _buildCurrentSaleItems(SaleProvider provider, double width) {
    if (provider.currentSaleItems.isEmpty) {
      return _buildEmptySaleState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.currentSaleItems.length,
      itemBuilder: (context, index) {
        final item = provider.currentSaleItems[index];
        return SaleItemCard(
          item: item,
          onQuantityChanged: (quantity) {
            provider.updateItemQuantity(index, quantity);
          },
          onDiscountApplied: (discount) {
            provider.applyItemDiscount(index, discount);
          },
          onRemove: () {
            provider.removeItemFromSale(index);
          },
        );
      },
    );
  }

  /// بناء حالة الفاتورة الفارغة
  Widget _buildEmptySaleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'الفاتورة فارغة',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة منتجات للفاتورة',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
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
            '${provider.subtotal.toStringAsFixed(2)} ر.س',
          ),
          if (provider.discount > 0)
            _buildSummaryRow(
              'الخصم:',
              '-${provider.discount.toStringAsFixed(2)} ر.س',
              color: Colors.red[700],
            ),
          _buildSummaryRow(
            'الضريبة (${provider.taxRate.toStringAsFixed(0)}%):',
            '${provider.taxAmount.toStringAsFixed(2)} ر.س',
          ),
          const Divider(thickness: 2),
          _buildSummaryRow(
            'الإجمالي:',
            '${provider.total.toStringAsFixed(2)} ر.س',
            isTotal: true,
          ),
          if (provider.paidAmount > 0) ...[
            _buildSummaryRow(
              'المدفوع:',
              '${provider.paidAmount.toStringAsFixed(2)} ر.س',
            ),
            if (provider.changeAmount > 0)
              _buildSummaryRow(
                'الباقي:',
                '${provider.changeAmount.toStringAsFixed(2)} ر.س',
                color: Colors.green[700],
              ),
          ],
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
                'دفع (${provider.total.toStringAsFixed(2)} ر.س)',
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
    showDialog(
      context: context,
      builder: (context) => ProductSelectionDialog(
        products: provider.filteredProducts,
        onProductSelected: (product) {
          provider.addProductToSale(product);
        },
      ),
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
    showDialog(
      context: context,
      builder: (context) => PaymentDialog(
        total: provider.total,
        onPaymentCompleted:
            (paymentMethod, paidAmount, customerName, customerPhone) {
              provider.updatePaymentMethod(paymentMethod);
              provider.updatePaidAmount(paidAmount);
              provider.updateCustomerInfo(
                name: customerName,
                phone: customerPhone,
              );

              provider.completeSale().then((success) {
                if (success) {
                  _showSuccessSnackBar('تم إتمام البيع بنجاح');
                } else {
                  _showErrorSnackBar(provider.errorMessage);
                }
              });
            },
      ),
    );
  }

  /// عرض ملخص السلة
  void _showCartSummary(SaleProvider provider) {
    // يمكن إضافة نافذة ملخص السلة هنا
  }

  /// عرض تاريخ المبيعات
  void _showSalesHistory() {
    // يمكن إضافة شاشة تاريخ المبيعات هنا
  }

  /// عرض الإعدادات
  void _showSettings() {
    // يمكن إضافة شاشة إعدادات نقطة البيع هنا
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

  /// عرض خيارات الطباعة
  void _showPrintOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'خيارات الطباعة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('طباعة آخر فاتورة'),
              onTap: () {
                Navigator.pop(context);
                _printLastInvoice();
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('طباعة فاتورة برقم'),
              onTap: () {
                Navigator.pop(context);
                _showPrintByNumberDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('إعادة طباعة إيصال حراري'),
              onTap: () {
                Navigator.pop(context);
                _printThermalReceipt();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// طباعة آخر فاتورة
  void _printLastInvoice() async {
    try {
      final provider = context.read<SaleProvider>();
      if (provider.recentSales.isNotEmpty) {
        final lastSale = provider.recentSales.first;
        await PrintService.printSaleInvoice(lastSale);
        _showSuccessSnackBar('تم طباعة الفاتورة بنجاح');
      } else {
        _showErrorSnackBar('لا توجد فواتير للطباعة');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في الطباعة: ${e.toString()}');
    }
  }

  /// عرض نافذة طباعة برقم الفاتورة
  void _showPrintByNumberDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('طباعة فاتورة'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'رقم الفاتورة',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _printInvoiceByNumber(controller.text);
            },
            child: const Text('طباعة'),
          ),
        ],
      ),
    );
  }

  /// طباعة فاتورة برقم
  void _printInvoiceByNumber(String invoiceNumber) async {
    if (invoiceNumber.isEmpty) {
      _showErrorSnackBar('يرجى إدخال رقم الفاتورة');
      return;
    }

    try {
      final provider = context.read<SaleProvider>();
      final sales = await provider.searchSales(invoiceNumber: invoiceNumber);

      if (sales.isNotEmpty) {
        await PrintService.printSaleInvoice(sales.first);
        _showSuccessSnackBar('تم طباعة الفاتورة بنجاح');
      } else {
        _showErrorSnackBar('لم يتم العثور على الفاتورة');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في الطباعة: ${e.toString()}');
    }
  }

  /// طباعة إيصال حراري
  void _printThermalReceipt() async {
    try {
      final provider = context.read<SaleProvider>();
      if (provider.recentSales.isNotEmpty) {
        final lastSale = provider.recentSales.first;
        await PrintService.printThermalReceipt(lastSale);
        _showSuccessSnackBar('تم طباعة الإيصال بنجاح');
      } else {
        _showErrorSnackBar('لا توجد فواتير للطباعة');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في الطباعة: ${e.toString()}');
    }
  }

  /// عرض نافذة الإرجاع
  void _showRefundDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إرجاع فاتورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'رقم الفاتورة',
                border: OutlineInputBorder(),
                hintText: 'أدخل رقم الفاتورة للإرجاع',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'يمكن إرجاع الفواتير خلال 30 يوماً من تاريخ الشراء',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processRefund(controller.text);
            },
            child: const Text('بحث'),
          ),
        ],
      ),
    );
  }

  /// معالجة الإرجاع
  void _processRefund(String invoiceNumber) async {
    if (invoiceNumber.isEmpty) {
      _showErrorSnackBar('يرجى إدخال رقم الفاتورة');
      return;
    }

    try {
      final refundService = RefundService();
      final result = await refundService.searchInvoiceForRefund(invoiceNumber);

      if (!result.found) {
        _showErrorSnackBar(result.message);
        return;
      }

      final sale = result.sale!;
      if (!result.canRefund) {
        _showErrorSnackBar(result.message);
        return;
      }

      _showRefundOptionsDialog(sale);
    } catch (e) {
      _showErrorSnackBar('خطأ في البحث: ${e.toString()}');
    }
  }

  /// عرض خيارات الإرجاع
  void _showRefundOptionsDialog(Sale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إرجاع الفاتورة ${sale.invoiceNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('التاريخ: ${_formatDate(sale.date)}'),
            Text('الإجمالي: ${sale.total.toStringAsFixed(2)} ر.س'),
            if (sale.customerName != null) Text('العميل: ${sale.customerName}'),
            const SizedBox(height: 16),
            const Text('نوع الإرجاع:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showFullRefundDialog(sale);
            },
            child: const Text('إرجاع كامل'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPartialRefundDialog(sale);
            },
            child: const Text('إرجاع جزئي'),
          ),
        ],
      ),
    );
  }

  /// عرض نافذة الإرجاع الكامل
  void _showFullRefundDialog(Sale sale) {
    final reasonController = TextEditingController();
    String selectedReason = RefundReasons.all.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إرجاع كامل'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                decoration: const InputDecoration(
                  labelText: 'سبب الإرجاع',
                  border: OutlineInputBorder(),
                ),
                items: RefundReasons.all.map((reason) {
                  return DropdownMenuItem(value: reason, child: Text(reason));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedReason = value!;
                  });
                },
              ),
              if (selectedReason == RefundReasons.other) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'تفاصيل السبب',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final reason = selectedReason == RefundReasons.other
                    ? reasonController.text
                    : selectedReason;
                _executeFullRefund(sale, reason);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('تأكيد الإرجاع'),
            ),
          ],
        ),
      ),
    );
  }

  /// تنفيذ الإرجاع الكامل
  void _executeFullRefund(Sale sale, String reason) async {
    try {
      final refundService = RefundService();
      final result = await refundService.refundFullInvoice(
        sale.invoiceNumber,
        reason,
      );

      if (result.isSuccess) {
        _showSuccessSnackBar(result.message);
        // طباعة فاتورة الإرجاع
        if (result.refundSale != null) {
          await PrintService.printSaleInvoice(result.refundSale!);
        }
        // تحديث البيانات
        if (mounted) {
          context.read<SaleProvider>().loadRecentSales();
        }
      } else {
        _showErrorSnackBar(result.message);
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في الإرجاع: ${e.toString()}');
    }
  }

  /// عرض نافذة الإرجاع الجزئي
  void _showPartialRefundDialog(Sale sale) {
    // يمكن تطوير هذه الوظيفة لاحقاً لإرجاع منتجات محددة
    _showErrorSnackBar('الإرجاع الجزئي قيد التطوير');
  }

  /// عرض التقارير
  void _showReports() {
    _showErrorSnackBar('التقارير قيد التطوير');
  }

  /// عرض خيارات النسخ الاحتياطي
  void _showBackupOptions() {
    _showErrorSnackBar('النسخ الاحتياطي قيد التطوير');
  }

  /// تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تطبيق خصم'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _discountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              labelText: _isPercentage ? 'نسبة الخصم (%)' : 'مبلغ الخصم (ر.س)',
              border: const OutlineInputBorder(),
            ),
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
