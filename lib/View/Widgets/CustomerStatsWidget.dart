import 'package:flutter/material.dart';
import 'package:smart_sizer/smart_sizer.dart';
import 'package:pos/Helper/Constants/AppConstants.dart';

/// ويدجت إحصائيات العملاء
class CustomerStatsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const CustomerStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد إحصائيات متاحة',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ بإضافة عملاء لرؤية الإحصائيات',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان الإحصائيات
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text(
                'إحصائيات العملاء',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // شبكة الإحصائيات
          _buildStatsGrid(),
        ],
      ),
    );
  }

  /// بناء شبكة الإحصائيات
  Widget _buildStatsGrid() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // الصف الأول
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'إجمالي العملاء',
                '${stats['total_customers'] ?? 0}',
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'العملاء المميزون',
                '${stats['vip_customers'] ?? 0}',
                Icons.star,
                Colors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // الصف الثاني
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'إجمالي الإيرادات',
                _formatCurrency(stats['total_revenue']),
                Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'متوسط المشتريات',
                _formatCurrency(stats['avg_purchases']),
                Icons.shopping_cart,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // الصف الثالث
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'إجمالي النقاط',
                '${stats['total_points'] ?? 0}',
                Icons.stars,
                Colors.purple,
              ),
            ),
            const Expanded(child: SizedBox()), // مساحة فارغة
          ],
        ),
      ],
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الأيقونة والعنوان
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // القيمة
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // نسبة العملاء المميزين
          if (title == 'العملاء المميزون') _buildVipPercentage(),
        ],
      ),
    );
  }

  /// بناء نسبة العملاء المميزين
  Widget _buildVipPercentage() {
    final totalCustomers = stats['total_customers'] ?? 0;
    final vipCustomers = stats['vip_customers'] ?? 0;

    if (totalCustomers == 0) {
      return const SizedBox.shrink();
    }

    final percentage = (vipCustomers / totalCustomers * 100).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.amber[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'من إجمالي العملاء',
            style: TextStyle(
              fontSize: 12,
              color: Colors.amber.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// تنسيق العملة
  String _formatCurrency(dynamic value) {
    if (value == null) return AppConstants.formatCurrency(0.0);

    double amount = 0.0;
    if (value is double) {
      amount = value;
    } else if (value is int) {
      amount = value.toDouble();
    } else if (value is String) {
      amount = double.tryParse(value) ?? 0.0;
    }

    return AppConstants.formatCurrency(amount);
  }
}
