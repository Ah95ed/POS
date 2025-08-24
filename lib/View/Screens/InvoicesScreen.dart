import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sizer/smart_sizer.dart';
import 'package:pos/Controller/InvoiceProvider.dart';
import 'package:pos/Model/InvoiceModel.dart';
import 'package:pos/View/Widgets/InvoiceCard.dart';
import 'package:pos/View/Widgets/InvoiceFormDialog.dart';
import 'package:pos/View/Widgets/InvoiceStatsWidget.dart';
import 'package:pos/View/Screens/InvoiceDetailsScreen.dart';

/// شاشة إدارة الفواتير
class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'all';
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().loadInvoices();
      context.read<InvoiceProvider>().loadInvoiceStats();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Consumer<InvoiceProvider>(
        builder: (context, invoiceProvider, child) {
          if (invoiceProvider.isLoading && invoiceProvider.invoices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // إحصائيات الفواتير
              if (invoiceProvider.invoiceStats != null)
                InvoiceStatsWidget(stats: invoiceProvider.invoiceStats!),

              // شريط البحث والتصفية
              _buildSearchAndFilterBar(invoiceProvider),

              // قائمة الفواتير
              Expanded(child: _buildInvoicesList(invoiceProvider)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddInvoiceDialog(),
        icon: const Icon(Icons.receipt_long),
        label: const Text('إضافة فاتورة'),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  /// بناء شريط التطبيق
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'إدارة الفواتير',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: Colors.blue[700],
      elevation: 0,
      actions: [
        Consumer<InvoiceProvider>(
          builder: (context, provider, child) {
            return IconButton(
              icon: Badge(
                label: Text('${provider.invoicesCount}'),
                child: const Icon(Icons.receipt, color: Colors.white),
              ),
              onPressed: () => _showInvoiceStats(provider),
              tooltip: 'إحصائيات الفواتير',
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'export':
                _exportInvoices();
                break;
              case 'import':
                _importInvoices();
                break;
              case 'backup':
                _backupInvoices();
                break;
              case 'reset_filters':
                _resetFilters();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.file_download),
                  SizedBox(width: 8),
                  Text('تصدير الفواتير'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'import',
              child: Row(
                children: [
                  Icon(Icons.file_upload),
                  SizedBox(width: 8),
                  Text('استيراد الفواتير'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'backup',
              child: Row(
                children: [
                  Icon(Icons.backup),
                  SizedBox(width: 8),
                  Text('نسخ احتياطي'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'reset_filters',
              child: Row(
                children: [
                  Icon(Icons.clear_all),
                  SizedBox(width: 8),
                  Text('إعادة تعيين التصفيات'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// بناء شريط البحث والتصفية
  Widget _buildSearchAndFilterBar(InvoiceProvider provider) {
    return Container(
      padding: EdgeInsets.all(context.getWidth(4)),
      color: Colors.white,
      child: Column(
        children: [
          // شريط البحث
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'البحث برقم الفاتورة أو اسم العميل أو رقم الهاتف...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        provider.clearSearch();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[700]!),
              ),
            ),
            onChanged: provider.searchInvoices,
          ),

          SizedBox(height: context.getWidth(3)),

          // أزرار التصفية
          Row(
            children: [
              // تصفية الحالة
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilterChip('all', 'الكل', provider),
                      SizedBox(width: context.getWidth(2)),
                      _buildStatusFilterChip('pending', 'معلقة', provider),
                      SizedBox(width: context.getWidth(2)),
                      _buildStatusFilterChip('paid', 'مدفوعة', provider),
                      SizedBox(width: context.getWidth(2)),
                      _buildStatusFilterChip('overdue', 'متأخرة', provider),
                    ],
                  ),
                ),
              ),

              SizedBox(width: context.getWidth(2)),

              // تصفية التاريخ
              IconButton(
                onPressed: () => _showDateRangePicker(provider),
                icon: Icon(
                  Icons.date_range,
                  color: _selectedDateRange != null
                      ? Colors.blue[700]
                      : Colors.grey[600],
                ),
                tooltip: 'تصفية حسب التاريخ',
              ),
            ],
          ),

          // عرض نطاق التاريخ المحدد
          if (_selectedDateRange != null)
            Container(
              margin: EdgeInsets.only(top: context.getWidth(2)),
              padding: EdgeInsets.symmetric(
                horizontal: context.getWidth(3),
                vertical: context.getWidth(1),
              ),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.date_range, size: 16, color: Colors.blue[700]),
                  SizedBox(width: context.getWidth(2)),
                  Text(
                    'من ${_formatDate(_selectedDateRange!.start)} إلى ${_formatDate(_selectedDateRange!.end)}',
                    style: TextStyle(
                      fontSize: context.getFontSize(12),
                      color: Colors.blue[700],
                    ),
                  ),
                  SizedBox(width: context.getWidth(2)),
                  GestureDetector(
                    onTap: () => _clearDateFilter(provider),
                    child: Icon(Icons.close, size: 16, color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// بناء chip تصفية الحالة
  Widget _buildStatusFilterChip(
    String status,
    String label,
    InvoiceProvider provider,
  ) {
    final isSelected = _selectedStatusFilter == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatusFilter = status;
        });
        provider.filterByStatus(status);
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
    );
  }

  /// بناء قائمة الفواتير
  Widget _buildInvoicesList(InvoiceProvider provider) {
    if (provider.errorMessage != null) {
      return _buildErrorState(provider);
    }

    final invoices = provider.filteredInvoices;

    if (invoices.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshInvoices(),
      child: ListView.builder(
        padding: EdgeInsets.all(context.getWidth(4)),
        itemCount: invoices.length,
        itemBuilder: (context, index) {
          final invoice = invoices[index];
          return InvoiceCard(
            invoice: invoice,
            onTap: () => _showInvoiceDetails(invoice),
            onEdit: () => _showEditInvoiceDialog(invoice),
            onDelete: () => _showDeleteConfirmation(invoice),
            onStatusChange: (status) => _updateInvoiceStatus(invoice, status),
          );
        },
      ),
    );
  }

  /// بناء حالة الخطأ
  Widget _buildErrorState(InvoiceProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          SizedBox(height: context.getWidth(4)),
          Text(
            'حدث خطأ',
            style: TextStyle(
              fontSize: context.getFontSize(18),
              color: Colors.red[600],
            ),
          ),
          SizedBox(height: context.getWidth(2)),
          Text(
            provider.errorMessage ?? 'خطأ غير معروف',
            style: TextStyle(
              fontSize: context.getFontSize(14),
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.getWidth(4)),
          ElevatedButton(
            onPressed: () => provider.loadInvoices(),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  /// بناء حالة القائمة الفارغة
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          SizedBox(height: context.getWidth(4)),
          Text(
            'لا توجد فواتير',
            style: TextStyle(
              fontSize: context.getFontSize(18),
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: context.getWidth(2)),
          Text(
            'ابدأ بإضافة فاتورة جديدة',
            style: TextStyle(
              fontSize: context.getFontSize(14),
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: context.getWidth(4)),
          ElevatedButton.icon(
            onPressed: () => _showAddInvoiceDialog(),
            icon: const Icon(Icons.receipt_long),
            label: const Text('إضافة فاتورة'),
          ),
        ],
      ),
    );
  }

  /// عرض حوار إضافة فاتورة
  void _showAddInvoiceDialog() {
    showDialog(
      context: context,
      builder: (context) => InvoiceFormDialog(
        title: 'إضافة فاتورة جديدة',
        onSave: (invoice) async {
          final provider = context.read<InvoiceProvider>();
          final success = await provider.addInvoice(invoice);

          if (success) {
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم إضافة الفاتورة بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    provider.errorMessage ?? 'خطأ في إضافة الفاتورة',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  /// عرض حوار تعديل فاتورة
  void _showEditInvoiceDialog(InvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (context) => InvoiceFormDialog(
        title: 'تعديل الفاتورة',
        
        invoice: invoice,
        onSave: (updatedInvoice) async {
          final provider = context.read<InvoiceProvider>();
          final success = await provider.updateInvoice(updatedInvoice);

          if (success) {
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تحديث الفاتورة بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    provider.errorMessage ?? 'خطأ في تحديث الفاتورة',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  /// عرض تفاصيل الفاتورة
  void _showInvoiceDetails(InvoiceModel invoice) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InvoiceDetailsScreen(invoice: invoice),
      ),
    );
  }

  /// عرض تأكيد الحذف
  void _showDeleteConfirmation(InvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من حذف الفاتورة "${invoice.invoiceNumber}"؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = context.read<InvoiceProvider>();
              final success = await provider.deleteInvoice(invoice.id!);

              if (success) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف الفاتورة بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ?? 'خطأ في حذف الفاتورة',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  /// تحديث حالة الفاتورة
  void _updateInvoiceStatus(InvoiceModel invoice, String status) async {
    final provider = context.read<InvoiceProvider>();
    final success = await provider.updateInvoiceStatus(invoice.id!, status);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث حالة الفاتورة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'خطأ في تحديث حالة الفاتورة',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// عرض إحصائيات الفواتير
  void _showInvoiceStats(InvoiceProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إحصائيات الفواتير'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إجمالي الفواتير: ${provider.invoicesCount}'),
            Text('الفواتير المدفوعة: ${provider.paidInvoicesCount}'),
            Text('الفواتير المعلقة: ${provider.pendingInvoicesCount}'),
            Text('الفواتير المتأخرة: ${provider.overdueInvoicesCount}'),
            const Divider(),
            Text(
              'إجمالي القيمة: ${provider.totalInvoicesAmount.toStringAsFixed(2)} ر.س',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  /// عرض منتقي نطاق التاريخ
  void _showDateRangePicker(InvoiceProvider provider) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      locale: const Locale('ar'),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      provider.filterByDateRange(picked.start, picked.end);
    }
  }

  /// مسح تصفية التاريخ
  void _clearDateFilter(InvoiceProvider provider) {
    setState(() {
      _selectedDateRange = null;
    });
    provider.loadInvoices();
  }

  /// إعادة تعيين جميع التصفيات
  void _resetFilters() {
    setState(() {
      _selectedStatusFilter = 'all';
      _selectedDateRange = null;
    });
    _searchController.clear();
    context.read<InvoiceProvider>().resetFilters();
  }

  /// تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// تصدير الفواتير
  void _exportInvoices() {
    // TODO: تنفيذ تصدير الفواتير
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم تنفيذ تصدير الفواتير قريباً'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// استيراد الفواتير
  void _importInvoices() {
    // TODO: تنفيذ استيراد الفواتير
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم تنفيذ استيراد الفواتير قريباً'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// نسخ احتياطي للفواتير
  void _backupInvoices() {
    // TODO: تنفيذ النسخ الاحتياطي
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم تنفيذ النسخ الاحتياطي قريباً'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
