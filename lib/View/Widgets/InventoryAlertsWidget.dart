import 'package:flutter/material.dart';
import 'package:pos/Model/ProductModel.dart';
import 'package:pos/View/Screens/EnhancedAlertsScreen.dart';

/// Widget تنبيهات المخزون
class InventoryAlertsWidget extends StatelessWidget {
  final List<ProductModel> products;

  const InventoryAlertsWidget({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final alerts = _calculateAlerts();

    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EnhancedAlertsScreen(),
            ),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.red[50]!, Colors.orange[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.warning,
                        color: Colors.red[700],
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'تنبيهات المخزون',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[600],
                      size: 14,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // التنبيهات
                Wrap(spacing: 8, runSpacing: 6, children: alerts),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// حساب التنبيهات
  List<Widget> _calculateAlerts() {
    final alerts = <Widget>[];

    // نافد المخزون
    final outOfStockCount = products
        .where((p) => p.isOutOfStock && !p.isArchived)
        .length;
    if (outOfStockCount > 0) {
      alerts.add(
        _buildAlertChip(
          '$outOfStockCount نافد المخزون',
          Icons.error,
          Colors.red,
        ),
      );
    }

    // مخزون منخفض
    final lowStockCount = products
        .where((p) => p.isLowStock && !p.isOutOfStock && !p.isArchived)
        .length;
    if (lowStockCount > 0) {
      alerts.add(
        _buildAlertChip(
          '$lowStockCount مخزون منخفض',
          Icons.warning,
          Colors.orange,
        ),
      );
    }

    // منتهي الصلاحية
    final expiredCount = products
        .where((p) => p.isExpired && !p.isArchived)
        .length;
    if (expiredCount > 0) {
      alerts.add(
        _buildAlertChip(
          '$expiredCount منتهي الصلاحية',
          Icons.dangerous,
          Colors.red[800]!,
        ),
      );
    }

    // قريب الانتهاء
    final nearExpiryCount = products
        .where((p) => p.isNearExpiry && !p.isExpired && !p.isArchived)
        .length;
    if (nearExpiryCount > 0) {
      alerts.add(
        _buildAlertChip(
          '$nearExpiryCount قريب الانتهاء',
          Icons.schedule,
          Colors.yellow[700]!,
        ),
      );
    }

    return alerts;
  }

  /// بناء رقاقة التنبيه
  Widget _buildAlertChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
