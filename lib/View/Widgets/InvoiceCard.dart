import 'package:flutter/material.dart';
import 'package:smart_sizer/smart_sizer.dart';
import 'package:pos/Model/InvoiceModel.dart';

/// بطاقة عرض الفاتورة
class InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(String)? onStatusChange;

  const InvoiceCard({
    super.key,
    required this.invoice,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: context.getWidth(3)),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(context.getWidth(4)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف الأول: رقم الفاتورة والحالة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // رقم الفاتورة
                  Expanded(
                    child: Text(
                      invoice.invoiceNumber,
                      style: TextStyle(
                        fontSize: context.getFontSize(16),
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),

                  // حالة الفاتورة
                  _buildStatusChip(context),
                ],
              ),

              SizedBox(height: context.getWidth(3)),

              // الصف الثاني: معلومات العميل
              if (invoice.customerName != null &&
                  invoice.customerName!.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: context.getMinSize(16),
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: context.getWidth(2)),
                    Expanded(
                      child: Text(
                        invoice.customerName!,
                        style: TextStyle(
                          fontSize: context.getFontSize(14),
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),

              if (invoice.customerPhone != null &&
                  invoice.customerPhone!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: context.getWidth(1)),
                  child: Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: context.getMinSize(16),
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: context.getWidth(2)),
                      Text(
                        invoice.customerPhone!,
                        style: TextStyle(
                          fontSize: context.getFontSize(14),
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: context.getWidth(3)),

              // الصف الثالث: التاريخ والمبلغ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // التاريخ
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: context.getMinSize(16),
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: context.getWidth(2)),
                      Text(
                        _formatDate(invoice.date),
                        style: TextStyle(
                          fontSize: context.getFontSize(13),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  // المبلغ الإجمالي
                  Text(
                    '${invoice.totalAmount.toStringAsFixed(2)} د.ع',
                    style: TextStyle(
                      fontSize: context.getFontSize(16),
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),

              // عدد العناصر
              if (invoice.items.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: context.getWidth(2)),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory,
                        size: context.getMinSize(16),
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: context.getWidth(2)),
                      Text(
                        '${invoice.items.length} عنصر',
                        style: TextStyle(
                          fontSize: context.getFontSize(13),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

              // الملاحظات
              if (invoice.notes != null && invoice.notes!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: context.getWidth(2)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        size: context.getMinSize(16),
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: context.getWidth(2)),
                      Expanded(
                        child: Text(
                          invoice.notes!,
                          style: TextStyle(
                            fontSize: context.getFontSize(12),
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: context.getWidth(3)),

              // أزرار الإجراءات
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // تغيير الحالة
                  if (onStatusChange != null)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz, color: Colors.grey[600]),
                      onSelected: onStatusChange,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'pending',
                          child: Row(
                            children: [
                              Icon(Icons.pending, color: Colors.orange),
                              SizedBox(width: context.getWidth(8)),
                              Text('معلقة'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'paid',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: context.getWidth(8)),
                              Text('مدفوعة'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'overdue',
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red),
                              SizedBox(width: context.getWidth(8)),
                              Text('متأخرة'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'cancelled',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.grey),
                              SizedBox(width: context.getWidth(8)),
                              Text('ملغية'),
                            ],
                          ),
                        ),
                      ],
                    ),

                  SizedBox(width: context.getWidth(2)),

                  // تعديل
                  if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit,
                        color: Colors.blue[600],
                        size: context.getMinSize(20),
                      ),
                      tooltip: 'تعديل',
                    ),

                  // حذف
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red[600],
                        size: context.getMinSize(20),
                      ),
                      tooltip: 'حذف',
                    ),
                ],
              ),
            ],
          ),
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
        vertical: context.getWidth(1),
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: context.getMinSize(14), color: textColor),
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
}
