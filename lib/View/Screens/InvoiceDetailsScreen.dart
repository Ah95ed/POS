import 'package:flutter/material.dart';
import 'package:pos/Model/InvoiceModel.dart';
import 'package:smart_sizer/smart_sizer.dart';

/// شاشة تفاصيل الفاتورة
class InvoiceDetailsScreen extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoiceDetailsScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.getMinSize(4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات الفاتورة الأساسية
            _buildInvoiceHeader(context),

            SizedBox(height: context.getHeight(6)),

            // معلومات العميل
            _buildCustomerInfo(context),

            SizedBox(height: context.getHeight(6)),

            // عناصر الفاتورة
            _buildInvoiceItems(context),

            SizedBox(height: context.getHeight(6)),

            // ملخص الفاتورة
            _buildInvoiceSummary(context),

            SizedBox(height: context.getHeight(6)),

            // الملاحظات
            if (invoice.notes != null && invoice.notes!.isNotEmpty)
              _buildNotes(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _printInvoice(context),
        icon: const Icon(Icons.print),
        label: const Text('طباعة'),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  /// بناء شريط التطبيق
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'فاتورة ${invoice.invoiceNumber}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.blue[700],
      elevation: 0,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editInvoice(context);
                break;
              case 'duplicate':
                _duplicateInvoice(context);
                break;
              case 'share':
                _shareInvoice(context);
                break;
              case 'export_pdf':
                _exportToPdf(context);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [Icon(Icons.edit), SizedBox(width: 8), Text('تعديل')],
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [Icon(Icons.copy), SizedBox(width: 8), Text('نسخ')],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('مشاركة'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export_pdf',
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf),
                  SizedBox(width: 8),
                  Text('تصدير PDF'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// بناء رأس الفاتورة
  Widget _buildInvoiceHeader(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(context.getWidth(4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رقم الفاتورة',
                      style: TextStyle(
                        fontSize: context.getFontSize(12),
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      invoice.invoiceNumber,
                      style: TextStyle(
                        fontSize: context.getFontSize(18),
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                _buildStatusChip(context),
              ],
            ),

            SizedBox(height: context.getHeight(4)),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تاريخ الإنشاء',
                        style: TextStyle(
                          fontSize: context.getFontSize(12),
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _formatDate(invoice.date),
                        style: TextStyle(
                          fontSize: context.getFontSize(14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'آخر تحديث',
                        style: TextStyle(
                          fontSize: context.getFontSize(12),
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _formatDateTime(invoice.updatedAt),
                        style: TextStyle(
                          fontSize: context.getFontSize(14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// بناء معلومات العميل
  Widget _buildCustomerInfo(BuildContext context) {
    if (invoice.customerName == null && invoice.customerPhone == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(context.getWidth(4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue[700]),
                SizedBox(width: context.getWidth(2)),
                Text(
                  'معلومات العميل',
                  style: TextStyle(
                    fontSize: context.getFontSize(16),
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),

            SizedBox(height: context.getHeight(3)),

            if (invoice.customerName != null &&
                invoice.customerName!.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.person_outline, size: 18, color: Colors.grey[600]),
                  SizedBox(width: context.getWidth(2)),
                  Text(
                    'الاسم: ${invoice.customerName}',
                    style: TextStyle(fontSize: context.getFontSize(14)),
                  ),
                ],
              ),

            if (invoice.customerPhone != null &&
                invoice.customerPhone!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: context.getHeight(2)),
                child: Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: context.getWidth(2)),
                    Text(
                      'الهاتف: ${invoice.customerPhone}',
                      style: TextStyle(fontSize: context.getFontSize(14)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// بناء عناصر الفاتورة
  Widget _buildInvoiceItems(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(context.getWidth(4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory, color: Colors.blue[700]),
                SizedBox(width: context.getWidth(2)),
                Text(
                  'عناصر الفاتورة',
                  style: TextStyle(
                    fontSize: context.getFontSize(16),
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),

            SizedBox(height: context.getHeight(3)),

            // رأس الجدول
            Container(
              padding: EdgeInsets.symmetric(
                vertical: context.getHeight(2),
                horizontal: context.getWidth(1),
              ),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'المنتج',
                      style: TextStyle(
                        fontSize: context.getFontSize(12),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'الكمية',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.getFontSize(12),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'السعر',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.getFontSize(12),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'الإجمالي',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.getFontSize(12),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // العناصر
            ...invoice.items.map((item) => _buildItemRow(item, context)),
          ],
        ),
      ),
    );
  }

  /// بناء صف العنصر
  Widget _buildItemRow(InvoiceItemModel item, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: context.getHeight(3),
        horizontal: context.getWidth(1),
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.productCode.isNotEmpty)
                  Text(
                    'كود: ${item.productCode}',
                    style: TextStyle(
                      fontSize: context.getFontSize(11),
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
        ],
      ),
    );
  }

  /// بناء ملخص الفاتورة
  Widget _buildInvoiceSummary(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(context.getWidth(4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: Colors.blue[700]),
                SizedBox(width: context.getWidth(2)),
                Text(
                  'ملخص الفاتورة',
                  style: TextStyle(
                    fontSize: context.getFontSize(16),
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),

            SizedBox(height: context.getHeight(3)),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'عدد العناصر:',
                  style: TextStyle(fontSize: context.getFontSize(14)),
                ),
                Text(
                  '${invoice.items.length}',
                  style: TextStyle(
                    fontSize: context.getFontSize(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            SizedBox(height: context.getHeight(2)),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'إجمالي الكمية:',
                  style: TextStyle(fontSize: context.getFontSize(14)),
                ),
                Text(
                  '${invoice.items.fold(0, (sum, item) => sum + item.quantity)}',
                  style: TextStyle(
                    fontSize: context.getFontSize(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المبلغ الإجمالي:',
                  style: TextStyle(
                    fontSize: context.getFontSize(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${invoice.totalAmount.toStringAsFixed(2)} د.ع',
                  style: TextStyle(
                    fontSize: context.getFontSize(18),
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// بناء الملاحظات
  Widget _buildNotes(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(context.getWidth(4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: Colors.blue[700]),
                SizedBox(width: context.getWidth(2)),
                Text(
                  'ملاحظات',
                  style: TextStyle(
                    fontSize: context.getFontSize(16),
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),

            SizedBox(height: context.getHeight(3)),

            Text(
              invoice.notes!,
              style: TextStyle(
                fontSize: context.getFontSize(14),
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء chip حالة الفاتورة
  Widget _buildStatusChip(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String statusText;
    IconData statusIcon;

    switch (invoice.status.toLowerCase()) {
      case 'paid':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        statusText = 'مدفوعة';
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[700]!;
        statusText = 'معلقة';
        statusIcon = Icons.pending;
        break;
      case 'overdue':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        statusText = 'متأخرة';
        statusIcon = Icons.warning;
        break;
      case 'cancelled':
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        statusText = 'ملغية';
        statusIcon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[700]!;
        statusText = invoice.status;
        statusIcon = Icons.info;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.getWidth(3),
        vertical: context.getHeight(1),
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: textColor),
          SizedBox(width: context.getWidth(1)),
          Text(
            statusText,
            style: TextStyle(
              fontSize: context.getFontSize(12),
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// تنسيق التاريخ والوقت
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// طباعة الفاتورة
  void _printInvoice(BuildContext context) {
    // TODO: تنفيذ طباعة الفاتورة
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم تنفيذ الطباعة قريباً'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// تعديل الفاتورة
  void _editInvoice(BuildContext context) {
    // TODO: فتح حوار التعديل
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم تنفيذ التعديل قريباً'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// نسخ الفاتورة
  void _duplicateInvoice(BuildContext context) {
    // TODO: تنفيذ نسخ الفاتورة
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم تنفيذ النسخ قريباً'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// مشاركة الفاتورة
  void _shareInvoice(BuildContext context) {
    // TODO: تنفيذ مشاركة الفاتورة
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم تنفيذ المشاركة قريباً'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// تصدير إلى PDF
  void _exportToPdf(BuildContext context) {
    // TODO: تنفيذ تصدير PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم تنفيذ تصدير PDF قريباً'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
