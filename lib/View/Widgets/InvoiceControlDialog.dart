import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/SaleProvider.dart';
import 'package:pos/Model/SaleModel.dart';
import 'package:pos/Helper/Constants/AppConstants.dart';
import 'package:smart_sizer/smart_sizer.dart';

/// نافذة التحكم بالفواتير
class InvoiceControlDialog extends StatefulWidget {
  const InvoiceControlDialog({super.key});

  @override
  State<InvoiceControlDialog> createState() => _InvoiceControlDialogState();
}

class _InvoiceControlDialogState extends State<InvoiceControlDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _invoiceNumberController =
      TextEditingController();
  List<SaleModel> _filteredSales = [];
  SaleModel? _selectedSale;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecentSales();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _invoiceNumberController.dispose();
    super.dispose();
  }

  /// تحميل المبيعات الحديثة
  Future<void> _loadRecentSales() async {
    final provider = context.read<SaleProvider>();
    await provider.loadRecentSales();
    setState(() {
      _filteredSales = provider.recentSales;
    });
  }

  /// فلترة المبيعات
  void _filterSales() {
    final provider = context.read<SaleProvider>();
    final query = _searchQuery.toLowerCase();

    setState(() {
      _filteredSales = provider.recentSales.where((sale) {
        return sale.invoiceNumber.toLowerCase().contains(query);
        // TODO: إضافة فلتر للعميل عند الحاجة
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: context.screenWidth * 0.9,
        height: context.screenHeight * 0.85,
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSalesListTab(),
                  _buildSaleDetailsTab(),
                  _buildSaleActionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء رأس النافذة
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'إدارة الفواتير',
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

  /// بناء شريط التبويبات
  Widget _buildTabBar() {
    return Container(
      color: Colors.grey[100],
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.blue[700],
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.blue[700],
        tabs: const [
          Tab(icon: Icon(Icons.list), text: 'قائمة الفواتير'),
          Tab(icon: Icon(Icons.visibility), text: 'تفاصيل الفاتورة'),
          Tab(icon: Icon(Icons.settings), text: 'إجراءات'),
        ],
      ),
    );
  }

  /// تبويب قائمة المبيعات
  Widget _buildSalesListTab() {
    return Column(
      children: [
        // شريط البحث
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'البحث برقم الفاتورة أو العميل...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterSales();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _invoiceNumberController,
                  decoration: InputDecoration(
                    hintText: 'رقم الفاتورة',
                    prefixIcon: const Icon(Icons.receipt),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _searchByInvoiceNumber,
                icon: const Icon(Icons.search),
                label: const Text('بحث'),
              ),
            ],
          ),
        ),

        // قائمة المبيعات
        Expanded(
          child: Consumer<SaleProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_filteredSales.isEmpty) {
                return const Center(
                  child: Text(
                    'لا توجد فواتير',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                itemCount: _filteredSales.length,
                itemBuilder: (context, index) {
                  final sale = _filteredSales[index];
                  return _buildSaleCard(sale);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// بناء بطاقة المبيعة
  Widget _buildSaleCard(SaleModel sale) {
    final isSelected = _selectedSale?.id == sale.id;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue[50] : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(sale.status),
          child: Icon(
            _getStatusIcon(sale.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          sale.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الإجمالي: ${AppConstants.formatCurrency(sale.total)}'),
            Text('التاريخ: ${AppConstants.formatDate(sale.createdAt)}'),
            // TODO: إضافة معلومات العميل عند الحاجة
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              sale.paymentMethod,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(sale.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(sale.status),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ),
        onTap: () {
          setState(() {
            _selectedSale = sale;
          });
          _tabController.animateTo(1); // الانتقال لتبويب التفاصيل
        },
      ),
    );
  }

  /// تبويب تفاصيل الفاتورة
  Widget _buildSaleDetailsTab() {
    if (_selectedSale == null) {
      return const Center(
        child: Text(
          'اختر فاتورة لعرض التفاصيل',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSaleHeader(),
          const SizedBox(height: 16),
          _buildSaleItems(),
          const SizedBox(height: 16),
          _buildSaleSummary(),
          const SizedBox(height: 16),
          _buildCustomerInfo(),
        ],
      ),
    );
  }

  /// بناء رأس تفاصيل الفاتورة
  Widget _buildSaleHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'فاتورة: ${_selectedSale!.invoiceNumber}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_selectedSale!.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusText(_selectedSale!.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'التاريخ: ${AppConstants.formatDateTime(_selectedSale!.createdAt)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'طريقة الدفع: ${_selectedSale!.paymentMethod}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء عناصر الفاتورة
  Widget _buildSaleItems() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'عناصر الفاتورة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedSale!.items.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = _selectedSale!.items[index];
                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(child: Text('${item.quantity}x')),
                    Expanded(
                      flex: 2,
                      child: Text(
                        AppConstants.formatCurrency(item.unitPrice),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        AppConstants.formatCurrency(item.total),
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// بناء ملخص الفاتورة
  Widget _buildSaleSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryRow('المجموع الفرعي:', _selectedSale!.subtotal),
            if (_selectedSale!.discount > 0)
              _buildSummaryRow(
                'الخصم:',
                _selectedSale!.discount,
                isDiscount: true,
              ),
            if (_selectedSale!.tax > 0)
              _buildSummaryRow('الضريبة:', _selectedSale!.tax),
            const Divider(thickness: 2),
            _buildSummaryRow('الإجمالي:', _selectedSale!.total, isTotal: true),
            _buildSummaryRow('المدفوع:', _selectedSale!.paidAmount),
            if (_selectedSale!.changeAmount > 0)
              _buildSummaryRow(
                'الباقي:',
                _selectedSale!.changeAmount,
                isChange: true,
              ),
          ],
        ),
      ),
    );
  }

  /// بناء صف ملخص
  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
    bool isChange = false,
  }) {
    Color? color;
    if (isTotal) color = Colors.green[700];
    if (isDiscount) color = Colors.red[700];
    if (isChange) color = Colors.blue[700];

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
            AppConstants.formatCurrency(amount),
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء معلومات العميل
  Widget _buildCustomerInfo() {
    if (_selectedSale!.customerId == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات العميل',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Text('معرف العميل: ${_selectedSale!.customerId}'),
              ],
            ),
            // TODO: جلب تفاصيل العميل باستخدام customerId
            if (_selectedSale!.notes != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(child: Text('ملاحظات: ${_selectedSale!.notes}')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// تبويب الإجراءات
  Widget _buildSaleActionsTab() {
    if (_selectedSale == null) {
      return const Center(
        child: Text(
          'اختر فاتورة لعرض الإجراءات',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildActionCard(
            'طباعة الفاتورة',
            'طباعة نسخة من الفاتورة',
            Icons.print,
            Colors.blue,
            _printInvoice,
          ),
          _buildActionCard(
            'إرسال بالإيميل',
            'إرسال الفاتورة عبر البريد الإلكتروني',
            Icons.email,
            Colors.green,
            _emailInvoice,
          ),
          _buildActionCard(
            'نسخة PDF',
            'تصدير الفاتورة كملف PDF',
            Icons.picture_as_pdf,
            Colors.red,
            _exportToPdf,
          ),
          if (_selectedSale!.status == 'completed')
            _buildActionCard(
              'إرجاع الفاتورة',
              'إجراء عملية إرجاع للفاتورة',
              Icons.undo,
              Colors.orange,
              _refundInvoice,
            ),
          _buildActionCard(
            'حذف الفاتورة',
            'حذف الفاتورة نهائياً (احذر!)',
            Icons.delete,
            Colors.red[800]!,
            _deleteInvoice,
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة إجراء
  Widget _buildActionCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  /// البحث برقم الفاتورة
  void _searchByInvoiceNumber() {
    final invoiceNumber = _invoiceNumberController.text.trim();
    if (invoiceNumber.isNotEmpty) {
      context.read<SaleProvider>().getSaleByInvoiceNumber(invoiceNumber).then((
        result,
      ) {
        if (result.isSuccess && result.data != null) {
          setState(() {
            _selectedSale = result.data;
            _filteredSales = [result.data!];
          });
          _tabController.animateTo(1);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لم يتم العثور على الفاتورة'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  /// الحصول على لون الحالة
  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// الحصول على أيقونة الحالة
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_empty;
      case 'cancelled':
        return Icons.cancel;
      case 'refunded':
        return Icons.undo;
      default:
        return Icons.help;
    }
  }

  /// الحصول على نص الحالة
  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'مكتملة';
      case 'pending':
        return 'معلقة';
      case 'cancelled':
        return 'ملغية';
      case 'refunded':
        return 'مُرجعة';
      default:
        return 'غير معروف';
    }
  }

  /// طباعة الفاتورة
  void _printInvoice() {
    // تنفيذ طباعة الفاتورة
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('جاري طباعة الفاتورة...')));
  }

  /// إرسال بالإيميل
  void _emailInvoice() {
    // تنفيذ إرسال الإيميل
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('جاري إرسال الإيميل...')));
  }

  /// تصدير PDF
  void _exportToPdf() {
    // تنفيذ تصدير PDF
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('جاري تصدير PDF...')));
  }

  /// إرجاع الفاتورة
  void _refundInvoice() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الإرجاع'),
        content: const Text('هل أنت متأكد من إرجاع هذه الفاتورة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // تنفيذ عملية الإرجاع
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إرجاع الفاتورة')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  /// حذف الفاتورة
  void _deleteInvoice() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text(
          'هل أنت متأكد من حذف هذه الفاتورة؟\nهذا الإجراء لا يمكن التراجع عنه!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // تنفيذ عملية الحذف
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('تم حذف الفاتورة')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
