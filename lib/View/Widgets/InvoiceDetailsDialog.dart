import 'package:flutter/material.dart';
import 'package:pos/Model/InvoiceModel.dart';
import 'package:smart_sizer/smart_sizer.dart';

/// حوار عرض تفاصيل الفاتورة
class InvoiceDetailsDialog extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoiceDetailsDialog({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: context.getWidth(90),
        constraints: BoxConstraints(maxHeight: context.getHeight(80)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // رأس الحوار
            _buildHeader(context),

            // محتوى الحوار
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.getWidth(4)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // معلومات الفاتورة الأساسية
                    _buildInvoiceInfo(context),

                    SizedBox(height: context.getWidth(4)),

                    // معلومات العميل
                    if (invoice.customerName != null) ...[
                      _buildCustomerInfo(context),
                      SizedBox(height: context.getWidth(4)),
                    ],

                    // قائمة المنتجات
                    _buildItemsList(context),

                    SizedBox(height: context.getWidth(4)),

                    // الملاحظات
                    if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                      _buildNotes(context),
                      SizedBox(height: context.getWidth(4)),
                    ],

                    // الإجمالي
                    _buildTotal(context),
                  ],
                ),
              ),
            ),

            // أزرار الحوار
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  /// بناء رأس الحوار
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.getWidth(4)),
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
            Icons.receipt_long,
            color: Colors.white,
            size: context.getWidth(6),
          ),
          SizedBox(width: context.getWidth(3)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تفاصيل الفاتورة',
                  style: TextStyle(
                    fontSize: context.getFontSize(16),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'رقم: ${invoice.invoiceNumber}',
                  style: TextStyle(
                    fontSize: context.getFontSize(12),
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
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

  /// بناء معلومات الفاتورة الأساسية
  Widget _buildInvoiceInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(context.getWidth(3)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'معلومات الفاتورة',
              style: TextStyle(
                fontSize: context.getFontSize(14),
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: context.getWidth(2)),
            _buildInfoRow(context, 'رقم الفاتورة', invoice.invoiceNumber),
            _buildInfoRow(context, 'التاريخ', _formatDate(invoice.date)),
            _buildInfoRow(
              context,
              'تاريخ الإنشاء',
              _formatDateTime(invoice.createdAt),
            ),
            if (invoice.updatedAt != invoice.createdAt)
              _buildInfoRow(
                context,
                'آخر تحديث',
                _formatDateTime(invoice.updatedAt),
              ),
            _buildInfoRow(context, 'الحالة', _getStatusText(invoice.status)),
          ],
        ),
      ),
    );
  }

  /// بناء معلومات العميل
  Widget _buildCustomerInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(context.getWidth(3)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'معلومات العميل',
              style: TextStyle(
                fontSize: context.getFontSize(14),
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: context.getWidth(2)),
            _buildInfoRow(context, 'الاسم', invoice.customerName ?? 'غير محدد'),
            if (invoice.customerPhone != null)
              _buildInfoRow(context, 'الهاتف', invoice.customerPhone!),
          ],
        ),
      ),
    );
  }

  /// بناء قائمة المنتجات
  Widget _buildItemsList(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(context.getWidth(3)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المنتجات (${invoice.items.length})',
              style: TextStyle(
                fontSize: context.getFontSize(14),
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: context.getWidth(2)),

            // رأس الجدول
            Container(
              padding: EdgeInsets.symmetric(
                vertical: context.getWidth(2),
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

            SizedBox(height: context.getWidth(1)),

            // صفوف المنتجات
            ...invoice.items.map((item) => _buildItemRow(context, item)),
          ],
        ),
      ),
    );
  }

  /// بناء صف المنتج
  Widget _buildItemRow(BuildContext context, InvoiceItemModel item) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: context.getWidth(2),
        horizontal: context.getWidth(1),
      ),
      margin: EdgeInsets.only(bottom: context.getWidth(1)),
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
                    fontSize: context.getFontSize(12),
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                if (item.productCode.isNotEmpty)
                  Text(
                    'كود: ${item.productCode}',
                    style: TextStyle(
                      fontSize: context.getFontSize(10),
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
              style: TextStyle(
                fontSize: context.getFontSize(12),
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              item.price.toStringAsFixed(2),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.getFontSize(12),
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              item.total.toStringAsFixed(2),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.getFontSize(12),
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء الملاحظات
  Widget _buildNotes(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(context.getWidth(3)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الملاحظات',
              style: TextStyle(
                fontSize: context.getFontSize(14),
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: context.getWidth(2)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.getWidth(2)),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                invoice.notes!,
                style: TextStyle(
                  fontSize: context.getFontSize(12),
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء الإجمالي
  Widget _buildTotal(BuildContext context) {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: EdgeInsets.all(context.getWidth(3)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'إجمالي الكمية:',
                  style: TextStyle(
                    fontSize: context.getFontSize(13),
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '${invoice.totalQuantity}',
                  style: TextStyle(
                    fontSize: context.getFontSize(13),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.getWidth(1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المبلغ الإجمالي:',
                  style: TextStyle(
                    fontSize: context.getFontSize(16),
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                Text(
                  '${invoice.totalAmount.toStringAsFixed(2)} ر.س',
                  style: TextStyle(
                    fontSize: context.getFontSize(18),
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// بناء أزرار الحوار
  Widget _buildActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.getWidth(4)),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: تنفيذ الطباعة
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('سيتم تنفيذ الطباعة قريباً'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              icon: const Icon(Icons.print),
              label: const Text('طباعة'),
            ),
          ),
          SizedBox(width: context.getWidth(2)),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: تنفيذ المشاركة
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('سيتم تنفيذ المشاركة قريباً'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('مشاركة'),
            ),
          ),
          SizedBox(width: context.getWidth(2)),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء صف المعلومات
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.getWidth(1)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: context.getWidth(25),
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: context.getFontSize(12),
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: context.getFontSize(12),
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
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
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// الحصول على نص الحالة
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'معلقة';
      case 'completed':
        return 'مكتملة';
      case 'paid':
        return 'مدفوعة';
      case 'cancelled':
        return 'ملغية';
      default:
        return 'غير محدد';
    }
  }
}
