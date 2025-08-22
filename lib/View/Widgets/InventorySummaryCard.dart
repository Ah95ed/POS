import 'package:flutter/material.dart';
import 'package:pos/Model/ProductModel.dart';

/// بطاقة ملخص المخزون
class InventorySummaryCard extends StatelessWidget {
  final List<ProductModel> products;

  const InventorySummaryCard({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final summary = _calculateSummary();

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue[600]!, Colors.blue[800]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان
              Row(
                children: [
                  Icon(Icons.analytics, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'ملخص المخزون',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // الإحصائيات الرئيسية
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'عدد المنتجات',
                      '${summary.totalProducts}',
                      Icons.inventory_2,
                      Colors.white,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'إجمالي الكميات',
                      '${summary.totalQuantity}',
                      Icons.numbers,
                      Colors.white,
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
                      Colors.white,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'قيمة البيع',
                      '${summary.totalSaleValue.toStringAsFixed(0)} ر.س',
                      Icons.sell,
                      Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // هامش الربح الإجمالي
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'إجمالي الربح المتوقع',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${summary.totalProfit.toStringAsFixed(0)} ر.س',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // التنبيهات
              if (summary.lowStockCount > 0 ||
                  summary.expiredCount > 0 ||
                  summary.nearExpiryCount > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'تنبيهات المخزون',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          if (summary.lowStockCount > 0)
                            _buildAlertChip(
                              'مخزون منخفض: ${summary.lowStockCount}',
                              Icons.warning,
                              Colors.orange,
                            ),
                          if (summary.expiredCount > 0)
                            _buildAlertChip(
                              'منتهي الصلاحية: ${summary.expiredCount}',
                              Icons.dangerous,
                              Colors.red,
                            ),
                          if (summary.nearExpiryCount > 0)
                            _buildAlertChip(
                              'قريب الانتهاء: ${summary.nearExpiryCount}',
                              Icons.schedule,
                              Colors.amber,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء عنصر الملخص
  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color.withOpacity(0.9)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// بناء رقاقة التنبيه
  Widget _buildAlertChip(String text, IconData icon, Color color) {
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
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// حساب ملخص المخزون
  InventorySummary _calculateSummary() {
    int totalProducts = products.length;
    int totalQuantity = 0;
    double totalPurchaseValue = 0;
    double totalSaleValue = 0;
    double totalProfit = 0;
    int lowStockCount = 0;
    int expiredCount = 0;
    int nearExpiryCount = 0;

    for (final product in products) {
      totalQuantity += product.quantity;
      totalPurchaseValue += product.buyPrice * product.quantity;
      totalSaleValue += product.salePrice * product.quantity;
      totalProfit += product.profitPerUnit * product.quantity;

      if (product.isLowStock || product.isOutOfStock) {
        lowStockCount++;
      }
      if (product.isExpired) {
        expiredCount++;
      }
      if (product.isNearExpiry && !product.isExpired) {
        nearExpiryCount++;
      }
    }

    return InventorySummary(
      totalProducts: totalProducts,
      totalQuantity: totalQuantity,
      totalPurchaseValue: totalPurchaseValue,
      totalSaleValue: totalSaleValue,
      totalProfit: totalProfit,
      lowStockCount: lowStockCount,
      expiredCount: expiredCount,
      nearExpiryCount: nearExpiryCount,
    );
  }
}

/// فئة ملخص المخزون
class InventorySummary {
  final int totalProducts;
  final int totalQuantity;
  final double totalPurchaseValue;
  final double totalSaleValue;
  final double totalProfit;
  final int lowStockCount;
  final int expiredCount;
  final int nearExpiryCount;

  InventorySummary({
    required this.totalProducts,
    required this.totalQuantity,
    required this.totalPurchaseValue,
    required this.totalSaleValue,
    required this.totalProfit,
    required this.lowStockCount,
    required this.expiredCount,
    required this.nearExpiryCount,
  });
}
