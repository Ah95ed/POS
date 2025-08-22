import 'package:flutter/material.dart';
import 'package:pos/Model/ProductModel.dart';
import 'package:smart_sizer/smart_sizer.dart';

/// بطاقة ملخص المخزون المحسنة
class EnhancedInventorySummaryCard extends StatelessWidget {
  final List<ProductModel> products;
  final VoidCallback? onTap;

  const EnhancedInventorySummaryCard({
    super.key,
    required this.products,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final summary = _calculateSummary();

    return Card(
      elevation: 4,
      margin:  EdgeInsets.all(context.getMinSize(8)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.blue[700]!, Colors.blue[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding:  EdgeInsets.all(context.getMinSize(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان والأيقونة
                Row(
                  children: [
                    Container(
                      padding:  EdgeInsets.all(context.getMinSize(4)),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.inventory_2,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'ملخص المخزون',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.7),
                        size: 16,
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // الإحصائيات الرئيسية
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'المنتجات',
                        '${summary.totalProducts}',
                        Icons.inventory,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'الكميات',
                        '${summary.totalQuantity}',
                        Icons.numbers,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'قيمة الشراء',
                        '${summary.totalPurchaseValue.toStringAsFixed(0)} ر.س',
                        Icons.shopping_cart,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'قيمة البيع',
                        '${summary.totalSaleValue.toStringAsFixed(0)} ر.س',
                        Icons.sell,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // الربح المتوقع
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: Colors.green[300],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الربح المتوقع',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              '${summary.expectedProfit.toStringAsFixed(2)} ر.س',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${summary.profitMargin.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // مؤشرات التنبيه
                _buildAlertIndicators(summary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// بناء عنصر الملخص
  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.7), size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// بناء مؤشرات التنبيه
  Widget _buildAlertIndicators(InventorySummary summary) {
    final alerts = <Widget>[];

    if (summary.outOfStockCount > 0) {
      alerts.add(
        _buildAlertChip(
          '${summary.outOfStockCount} نافد',
          Icons.error,
          Colors.red[300]!,
        ),
      );
    }

    if (summary.lowStockCount > 0) {
      alerts.add(
        _buildAlertChip(
          '${summary.lowStockCount} منخفض',
          Icons.warning,
          Colors.orange[300]!,
        ),
      );
    }

    if (summary.nearExpiryCount > 0) {
      alerts.add(
        _buildAlertChip(
          '${summary.nearExpiryCount} قريب الانتهاء',
          Icons.schedule,
          Colors.yellow[300]!,
        ),
      );
    }

    if (summary.expiredCount > 0) {
      alerts.add(
        _buildAlertChip(
          '${summary.expiredCount} منتهي',
          Icons.dangerous,
          Colors.red[400]!,
        ),
      );
    }

    if (alerts.isEmpty) {
      alerts.add(
        _buildAlertChip('المخزون صحي', Icons.check_circle, Colors.green[300]!),
      );
    }

    return Wrap(spacing: 8, runSpacing: 4, children: alerts);
  }

  /// بناء رقاقة التنبيه
  Widget _buildAlertChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// حساب ملخص المخزون
  InventorySummary _calculateSummary() {
    if (products.isEmpty) {
      return InventorySummary.empty();
    }

    final totalProducts = products.length;
    final totalQuantity = products.fold<int>(0, (sum, p) => sum + p.quantity);
    final totalPurchaseValue = products.fold<double>(
      0,
      (sum, p) => sum + (p.buyPrice * p.quantity),
    );
    final totalSaleValue = products.fold<double>(
      0,
      (sum, p) => sum + (p.salePrice * p.quantity),
    );
    final expectedProfit = totalSaleValue - totalPurchaseValue;
    final profitMargin = totalSaleValue > 0
        ? (expectedProfit / totalSaleValue * 100)
        : 0.0;

    final outOfStockCount = products.where((p) => p.isOutOfStock).length;
    final lowStockCount = products
        .where((p) => p.isLowStock && !p.isOutOfStock)
        .length;
    final nearExpiryCount = products
        .where((p) => p.isNearExpiry && !p.isExpired)
        .length;
    final expiredCount = products.where((p) => p.isExpired).length;

    return InventorySummary(
      totalProducts: totalProducts,
      totalQuantity: totalQuantity,
      totalPurchaseValue: totalPurchaseValue,
      totalSaleValue: totalSaleValue,
      expectedProfit: expectedProfit,
      profitMargin: profitMargin,
      outOfStockCount: outOfStockCount,
      lowStockCount: lowStockCount,
      nearExpiryCount: nearExpiryCount,
      expiredCount: expiredCount,
    );
  }
}

/// نموذج ملخص المخزون
class InventorySummary {
  final int totalProducts;
  final int totalQuantity;
  final double totalPurchaseValue;
  final double totalSaleValue;
  final double expectedProfit;
  final double profitMargin;
  final int outOfStockCount;
  final int lowStockCount;
  final int nearExpiryCount;
  final int expiredCount;

  InventorySummary({
    required this.totalProducts,
    required this.totalQuantity,
    required this.totalPurchaseValue,
    required this.totalSaleValue,
    required this.expectedProfit,
    required this.profitMargin,
    required this.outOfStockCount,
    required this.lowStockCount,
    required this.nearExpiryCount,
    required this.expiredCount,
  });

  factory InventorySummary.empty() {
    return InventorySummary(
      totalProducts: 0,
      totalQuantity: 0,
      totalPurchaseValue: 0,
      totalSaleValue: 0,
      expectedProfit: 0,
      profitMargin: 0,
      outOfStockCount: 0,
      lowStockCount: 0,
      nearExpiryCount: 0,
      expiredCount: 0,
    );
  }
}
