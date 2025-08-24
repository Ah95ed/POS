import 'package:flutter/material.dart';
import 'package:pos/Model/DebtModel.dart';
import 'package:pos/View/style/app_colors.dart';
import 'package:smart_sizer/smart_sizer.dart';

/// بطاقة عرض الدين
class DebtCard extends StatelessWidget {
  final DebtModel debt;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final VoidCallback? onAddPayment;
  final VoidCallback? onViewTransactions;
  final bool isArchived;

  const DebtCard({
    super.key,
    required this.debt,
    this.onEdit,
    this.onDelete,
    this.onArchive,
    this.onAddPayment,
    this.onViewTransactions,
    this.isArchived = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: context.getWidth(3)),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _getStatusColor(), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onViewTransactions,
        child: Padding(
          padding: EdgeInsets.all(context.getWidth(4)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف الأول: اسم العميل/المورد والحالة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.partyName,
                          style: TextStyle(
                            fontSize: context.getFontSize(16),
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        if (debt.partyPhone != null)
                          Text(
                            debt.partyPhone!,
                            style: TextStyle(
                              fontSize: context.getFontSize(12),
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusChip(context),
                ],
              ),

              SizedBox(height: context.getWidth(3)),

              // نوع الطرف
              Row(
                children: [
                  Icon(
                    debt.partyType == 'customer'
                        ? Icons.person
                        : Icons.business,
                    size: context.getWidth(4),
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: context.getWidth(1)),
                  Text(
                    debt.partyTypeText,
                    style: TextStyle(
                      fontSize: context.getFontSize(12),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              SizedBox(height: context.getWidth(3)),

              // معلومات المبالغ
              Container(
                padding: EdgeInsets.all(context.getWidth(3)),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildAmountRow(
                      'المبلغ الكلي:',
                      debt.formattedAmount,
                      Colors.blue[700]!,
                      context,
                    ),
                    SizedBox(height: context.getWidth(1)),
                    _buildAmountRow(
                      'المبلغ المدفوع:',
                      debt.formattedPaidAmount,
                      Colors.green[700]!,
                      context,
                    ),
                    SizedBox(height: context.getWidth(1)),
                    _buildAmountRow(
                      'المبلغ المتبقي:',
                      debt.formattedRemainingAmount,
                      Colors.red[700]!,
                      context,
                    ),
                  ],
                ),
              ),

              SizedBox(height: context.getWidth(3)),

              // تاريخ الاستحقاق
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: context.getWidth(4),
                    color: debt.isOverdue ? Colors.red : Colors.grey[600],
                  ),
                  SizedBox(width: context.getWidth(1)),
                  Text(
                    'تاريخ الاستحقاق: ${debt.formattedDueDate}',
                    style: TextStyle(
                      fontSize: context.getFontSize(12),
                      color: debt.isOverdue ? Colors.red : Colors.grey[600],
                      fontWeight: debt.isOverdue
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  if (debt.isOverdue) ...[
                    SizedBox(width: context.getWidth(2)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.getWidth(2),
                        vertical: context.getWidth(0.5),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'متأخر',
                        style: TextStyle(
                          fontSize: context.getFontSize(10),
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // الملاحظات
              if (debt.notes != null && debt.notes!.isNotEmpty) ...[
                SizedBox(height: context.getWidth(2)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note,
                      size: context.getWidth(4),
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: context.getWidth(1)),
                    Expanded(
                      child: Text(
                        debt.notes!,
                        style: TextStyle(
                          fontSize: context.getFontSize(12),
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: context.getWidth(3)),

              // أزرار الإجراءات
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onViewTransactions != null)
                    _buildActionButton(
                      icon: Icons.history,
                      label: 'المعاملات',
                      onPressed: onViewTransactions!,
                      color: Colors.blue,
                      context: context,
                    ),

                  if (onAddPayment != null && debt.status != 'paid')
                    _buildActionButton(
                      icon: Icons.payment,
                      label: 'دفعة',
                      onPressed: onAddPayment!,
                      color: Colors.green,
                      context: context,
                    ),

                  if (onEdit != null)
                    _buildActionButton(
                      icon: Icons.edit,
                      label: 'تعديل',
                      onPressed: onEdit!,
                      color: Colors.orange,
                      context: context,
                    ),

                  if (onArchive != null)
                    _buildActionButton(
                      icon: isArchived ? Icons.unarchive : Icons.archive,
                      label: isArchived ? 'إلغاء الأرشفة' : 'أرشفة',
                      onPressed: onArchive!,
                      color: Colors.purple,
                      context: context,
                    ),

                  if (onDelete != null)
                    _buildActionButton(
                      icon: Icons.delete,
                      label: 'حذف',
                      onPressed: onDelete!,
                      color: Colors.red,
                      context: context,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء رقاقة الحالة
  Widget _buildStatusChip(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.getWidth(3),
        vertical: context.getWidth(1),
      ),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        debt.statusText,
        style: TextStyle(
          fontSize: context.getFontSize(12),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// بناء صف المبلغ
  Widget _buildAmountRow(
    String label,
    String amount,
    Color color,
    BuildContext context,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.getFontSize(12),
            color: Colors.grey[700],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: context.getFontSize(12),
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// بناء زر الإجراء
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    required BuildContext context,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: context.getWidth(2)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.getWidth(2),
            vertical: context.getWidth(1),
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: context.getWidth(4), color: color),
              SizedBox(width: context.getWidth(1)),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.getFontSize(10),
                  color: AppColors.textMain,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// الحصول على لون الحالة
  Color _getStatusColor() {
    switch (debt.status) {
      case 'paid':
        return Colors.green;
      case 'partiallyPaid':
        return Colors.orange;
      case 'unpaid':
      default:
        return Colors.red;
    }
  }
}
