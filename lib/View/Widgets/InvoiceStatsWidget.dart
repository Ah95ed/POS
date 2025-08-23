import 'package:flutter/material.dart';
import 'package:smart_sizer/smart_sizer.dart';

/// Widget لعرض إحصائيات الفواتير
class InvoiceStatsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const InvoiceStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final todayStats = stats['today'] as Map<String, dynamic>? ?? {};
    final monthStats = stats['month'] as Map<String, dynamic>? ?? {};
    final statusStats = stats['status'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: EdgeInsets.all(context.getWidth(4)),
      padding: EdgeInsets.all(context.getWidth(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان الإحصائيات
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue[700]),
              SizedBox(width: context.getWidth(2)),
              Text(
                'إحصائيات الفواتير',
                style: TextStyle(
                  fontSize: context.getFontSize(16),
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),

          SizedBox(height: context.getWidth(4)),

          // إحصائيات اليوم والشهر
          Row(
            children: [
              // إحصائيات اليوم
              Expanded(
                child: _buildStatCard(
                  context: context,
                  title: 'اليوم',
                  count: todayStats['count'] ?? 0,
                  amount: (todayStats['total_amount'] ?? 0.0).toDouble(),
                  color: Colors.green,
                  icon: Icons.today,
                ),
              ),

              SizedBox(width: context.getWidth(3)),

              // إحصائيات الشهر
              Expanded(
                child: _buildStatCard(
                  context: context,
                  title: 'هذا الشهر',
                  count: monthStats['count'] ?? 0,
                  amount: (monthStats['total_amount'] ?? 0.0).toDouble(),
                  color: Colors.blue,
                  icon: Icons.calendar_month,
                ),
              ),
            ],
          ),

          SizedBox(height: context.getWidth(4)),

          // إحصائيات الحالات
          if (statusStats.isNotEmpty) ...[
            Text(
              'حسب الحالة',
              style: TextStyle(
                fontSize: context.getFontSize(14),
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: context.getWidth(2)),
            _buildStatusStats(context, statusStats),
          ],
        ],
      ),
    );
  }

  /// بناء بطاقة إحصائية
  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required int count,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(context.getWidth(3)),
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
              Icon(icon, color: color, size: 18),
              SizedBox(width: context.getWidth(2)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: context.getFontSize(12),
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.getWidth(2)),
          Text(
            '$count فاتورة',
            style: TextStyle(
              fontSize: context.getFontSize(14),
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} ر.س',
            style: TextStyle(
              fontSize: context.getFontSize(13),
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء إحصائيات الحالات
  Widget _buildStatusStats(
    BuildContext context,
    Map<String, dynamic> statusStats,
  ) {
    return Wrap(
      spacing: context.getWidth(2),
      runSpacing: context.getWidth(2),
      children: statusStats.entries.map((entry) {
        final status = entry.key;
        final data = entry.value as Map<String, dynamic>;
        final count = data['count'] ?? 0;
        final amount = (data['total_amount'] ?? 0.0).toDouble();

        return _buildStatusChip(context, status, count, amount);
      }).toList(),
    );
  }

  /// بناء chip حالة
  Widget _buildStatusChip(
    BuildContext context,
    String status,
    int count,
    double amount,
  ) {
    Color color;
    String statusText;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'paid':
        color = Colors.green;
        statusText = 'مدفوعة';
        icon = Icons.check_circle;
        break;
      case 'pending':
        color = Colors.orange;
        statusText = 'معلقة';
        icon = Icons.pending;
        break;
      case 'overdue':
        color = Colors.red;
        statusText = 'متأخرة';
        icon = Icons.warning;
        break;
      case 'cancelled':
        color = Colors.grey;
        statusText = 'ملغية';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.blue;
        statusText = status;
        icon = Icons.info;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.getWidth(3),
        vertical: context.getWidth(2),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              SizedBox(width: context.getWidth(1)),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: context.getFontSize(11),
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: context.getWidth(1)),
          Text(
            '$count',
            style: TextStyle(
              fontSize: context.getFontSize(12),
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          if (amount > 0)
            Text(
              '${amount.toStringAsFixed(0)} ر.س',
              style: TextStyle(
                fontSize: context.getFontSize(10),
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }
}
