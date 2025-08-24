import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/DebtProvider.dart';
import 'package:smart_sizer/smart_sizer.dart';

/// ويدجت إحصائيات الديون
class DebtStatsWidget extends StatelessWidget {
  const DebtStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DebtProvider>(
      builder: (context, provider, child) {
        final stats = provider.statistics;

        if (stats.isEmpty) {
          return const SizedBox.shrink();
        }

        final total = stats['total'] as Map<String, dynamic>? ?? {};
        final overdue = stats['overdue'] as Map<String, dynamic>? ?? {};

        return SingleChildScrollView(
          child: Container(
            
            margin: EdgeInsets.all(context.getMinSize(4)),
            padding: EdgeInsets.all(context.getMinSize(4)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Colors.white,
                      size: context.getWidth(6),
                    ),
                    SizedBox(width: context.getWidth(2)),
                    Text(
                      'إحصائيات الديون',
                      style: TextStyle(
                        fontSize: context.getFontSize(18),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
          
                SizedBox(height: context.getWidth(4)),
          
                // الإحصائيات الرئيسية
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'إجمالي الديون',
                        '${_parseDouble(total['total_count']).toInt()}',
                        Icons.account_balance_wallet,
                        Colors.white,
                      ),
                    ),
                    SizedBox(width: context.getWidth(3)),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'المبلغ المتبقي',
                        '${_parseDouble(total['total_remaining']).toStringAsFixed(0)} د.ع',
                        Icons.money_off,
                        Colors.white,
                      ),
                    ),
                  ],
                ),
          
                SizedBox(height: context.getWidth(3)),
          
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'المبلغ المدفوع',
                        '${_parseDouble(total['total_paid']).toStringAsFixed(0)} د.ع',
                        Icons.payment,
                        Colors.green[100]!,
                        textColor: Colors.green[800]!,
                      ),
                    ),
                    SizedBox(width: context.getWidth(3)),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'الديون المتأخرة',
                        '${_parseDouble(overdue['count']).toInt()}',
                        Icons.warning,
                        Colors.red[100]!,
                        textColor: Colors.red[800]!,
                      ),
                    ),
                  ],
                ),
          
                SizedBox(height: context.getWidth(4)),
          
                // إحصائيات حسب الحالة
                _buildStatusStats(context, stats),
          
                SizedBox(height: context.getWidth(3)),
          
                // إحصائيات حسب النوع
                _buildTypeStats(context, stats),
              ],
            ),
          ),
        );
      },
    );
  }

  /// بناء بطاقة إحصائية
  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color backgroundColor, {
    Color? textColor,
  }) {
    return Container(
      padding: EdgeInsets.all(context.getWidth(3)),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: textColor ?? Colors.blue[700],
                size: context.getWidth(5),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: context.getFontSize(16),
                  fontWeight: FontWeight.bold,
                  color: textColor ?? Colors.blue[700],
                ),
              ),
            ],
          ),
          SizedBox(height: context.getWidth(1)),
          Text(
            title,
            style: TextStyle(
              fontSize: context.getFontSize(12),
              color: (textColor ?? Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء إحصائيات الحالة
  Widget _buildStatusStats(BuildContext context, Map<String, dynamic> stats) {
    final statusStats = stats['by_status'] as List<Map<String, dynamic>>? ?? [];

    if (statusStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'حسب الحالة:',
          style: TextStyle(
            fontSize: context.getFontSize(14),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: context.getWidth(2)),
        Row(
          children: statusStats.map((stat) {
            final status = stat['status'] as String;
            final count = _parseDouble(stat['count']).toInt();
            final amount = _parseDouble(stat['amount']);

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: context.getWidth(2)),
                padding: EdgeInsets.all(context.getWidth(2)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _getStatusText(status),
                      style: TextStyle(
                        fontSize: context.getFontSize(10),
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: context.getFontSize(14),
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${amount.toStringAsFixed(0)} د.ع',
                      style: TextStyle(
                        fontSize: context.getFontSize(8),
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// بناء إحصائيات النوع
  Widget _buildTypeStats(BuildContext context, Map<String, dynamic> stats) {
    final typeStats = stats['by_type'] as List<Map<String, dynamic>>? ?? [];

    if (typeStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'حسب النوع:',
          style: TextStyle(
            fontSize: context.getFontSize(14),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: context.getWidth(2)),
        Row(
          children: typeStats.map((stat) {
            final type = stat['party_type'] as String;
            final count = _parseDouble(stat['count']).toInt();
            final amount = _parseDouble(stat['amount']);

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: context.getWidth(2)),
                padding: EdgeInsets.all(context.getWidth(2)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      type == 'customer' ? Icons.person : Icons.business,
                      color: Colors.white,
                      size: context.getWidth(4),
                    ),
                    Text(
                      type == 'customer' ? 'العملاء' : 'الموردين',
                      style: TextStyle(
                        fontSize: context.getFontSize(10),
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: context.getFontSize(14),
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${amount.toStringAsFixed(0)} د.ع',
                      style: TextStyle(
                        fontSize: context.getFontSize(8),
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// تحويل نص الحالة
  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'مدفوع';
      case 'partiallyPaid':
        return 'جزئي';
      case 'unpaid':
      default:
        return 'غير مدفوع';
    }
  }

  /// تحويل القيمة إلى double
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
