import 'package:flutter/material.dart';
import 'package:pos/Model/CustomerModel.dart';
import 'package:pos/Helper/Constants/AppConstants.dart';
import 'package:smart_sizer/smart_sizer.dart';

/// بطاقة عرض العميل
class CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleVip;

  const CustomerCard({
    super.key,
    required this.customer,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleVip,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: customer.isVip
            ? BorderSide(color: Colors.amber[600]!, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف الأول: الاسم والحالة المميزة
              Row(
                children: [
                  // أيقونة العميل
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: customer.isVip
                        ? Colors.amber[100]
                        : Colors.blue[100],
                    child: Icon(
                      customer.isVip ? Icons.star : Icons.person,
                      color: customer.isVip
                          ? Colors.amber[700]
                          : Colors.blue[700],
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // اسم العميل
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                customer.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (customer.isVip)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'VIP',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[700],
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // تاريخ الإنشاء
                        Text(
                          'عضو منذ ${_formatDate(customer.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // قائمة الخيارات
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                        case 'toggle_vip':
                          onToggleVip?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('تعديل'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle_vip',
                        child: Row(
                          children: [
                            Icon(
                              customer.isVip ? Icons.star_border : Icons.star,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(customer.isVip ? 'إلغاء VIP' : 'جعل VIP'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('حذف', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // معلومات الاتصال
              if (customer.phone.isNotEmpty || customer.email != null)
                Column(
                  children: [
                    if (customer.phone.isNotEmpty)
                      _buildInfoRow(
                        Icons.phone,
                        'الهاتف',
                        customer.phone,
                        Colors.green,
                      ),

                    if (customer.email != null)
                      _buildInfoRow(
                        Icons.email,
                        'البريد الإلكتروني',
                        customer.email!,
                        Colors.blue,
                      ),

                    if (customer.address != null)
                      _buildInfoRow(
                        Icons.location_on,
                        'العنوان',
                        customer.address!,
                        Colors.orange,
                      ),
                  ],
                ),

              const SizedBox(height: 12),

              // الإحصائيات
              Row(
                children: [
                  // إجمالي المشتريات
                  Expanded(
                    child: _buildStatCard(
                      'إجمالي المشتريات',
                      AppConstants.formatCurrency(customer.totalPurchases),
                      Icons.shopping_cart,
                      Colors.green,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // النقاط (مؤقتاً معطل حتى إضافة points للـ CustomerModel)
                  Expanded(
                    child: _buildStatCard(
                      'المشتريات',
                      AppConstants.formatCurrency(customer.totalPurchases),
                      Icons.shopping_bag,
                      Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء صف المعلومات
  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة الإحصائية
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// تنسيق التاريخ
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} أيام';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'أسبوع' : 'أسابيع'}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'شهر' : 'أشهر'}';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'سنة' : 'سنوات'}';
    }
  }
}
