import 'package:flutter/material.dart';
import 'package:pos/Model/ProductModel.dart';

/// widget تقرير المخزون المفصل
class InventoryReportWidget extends StatelessWidget {
  final List<ProductModel> products;

  const InventoryReportWidget({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final report = _generateReport();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان التقرير
          _buildReportHeader(),

          const SizedBox(height: 20),

          // الملخص العام
          _buildGeneralSummary(report),

          const SizedBox(height: 20),

          // تحليل الحالة
          _buildStatusAnalysis(report),

          const SizedBox(height: 20),

          // تحليل الشركات
          _buildCompanyAnalysis(report),

          const SizedBox(height: 20),

          // تحليل الأسعار
          _buildPriceAnalysis(report),

          const SizedBox(height: 20),

          // المنتجات الأكثر ربحية
          _buildTopProfitableProducts(report),

          const SizedBox(height: 20),

          // التوصيات
          _buildRecommendations(report),
        ],
      ),
    );
  }

  /// بناء رأس التقرير
  Widget _buildReportHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تقرير المخزون المفصل',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'تم إنشاؤه في ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء الملخص العام
  Widget _buildGeneralSummary(InventoryReport report) {
    return _buildSection('الملخص العام', Icons.summarize, Colors.blue, [
      _buildSummaryGrid([
        _buildSummaryCard(
          'عدد المنتجات',
          '${report.totalProducts}',
          Icons.inventory_2,
          Colors.blue,
        ),
        _buildSummaryCard(
          'إجمالي الكميات',
          '${report.totalQuantity}',
          Icons.numbers,
          Colors.green,
        ),
        _buildSummaryCard(
          'قيمة الشراء',
          '${report.totalPurchaseValue.toStringAsFixed(0)} ر.س',
          Icons.shopping_cart,
          Colors.orange,
        ),
        _buildSummaryCard(
          'قيمة البيع',
          '${report.totalSaleValue.toStringAsFixed(0)} ر.س',
          Icons.sell,
          Colors.purple,
        ),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.trending_up, color: Colors.green[700], size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إجمالي الربح المتوقع',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                  Text(
                    '${report.totalProfit.toStringAsFixed(2)} ر.س',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${report.averageProfitMargin.toStringAsFixed(1)}%',
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
    ]);
  }

  /// بناء تحليل الحالة
  Widget _buildStatusAnalysis(InventoryReport report) {
    return _buildSection('تحليل حالة المخزون', Icons.pie_chart, Colors.orange, [
      Row(
        children: [
          Expanded(
            child: _buildStatusCard(
              'متوفر',
              report.availableProducts,
              report.totalProducts,
              Colors.green,
              Icons.check_circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatusCard(
              'منخفض',
              report.lowStockProducts,
              report.totalProducts,
              Colors.orange,
              Icons.warning,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _buildStatusCard(
              'نافد',
              report.outOfStockProducts,
              report.totalProducts,
              Colors.red,
              Icons.error,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatusCard(
              'منتهي الصلاحية',
              report.expiredProducts,
              report.totalProducts,
              Colors.red[800]!,
              Icons.dangerous,
            ),
          ),
        ],
      ),
    ]);
  }

  /// بناء تحليل الشركات
  Widget _buildCompanyAnalysis(InventoryReport report) {
    if (report.companiesAnalysis.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection('تحليل الشركات المصنعة', Icons.business, Colors.purple, [
      ...report.companiesAnalysis.take(5).map((company) {
        final percentage = (company.productCount / report.totalProducts * 100);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name.isEmpty ? 'غير محدد' : company.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${company.productCount} منتج • ${company.totalValue.toStringAsFixed(0)} ر.س',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Colors.purple[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    ]);
  }

  /// بناء تحليل الأسعار
  Widget _buildPriceAnalysis(InventoryReport report) {
    return _buildSection('تحليل الأسعار', Icons.attach_money, Colors.green, [
      _buildSummaryGrid([
        _buildSummaryCard(
          'أعلى سعر بيع',
          '${report.highestSalePrice.toStringAsFixed(2)} ر.س',
          Icons.arrow_upward,
          Colors.green,
        ),
        _buildSummaryCard(
          'أقل سعر بيع',
          '${report.lowestSalePrice.toStringAsFixed(2)} ر.س',
          Icons.arrow_downward,
          Colors.red,
        ),
        _buildSummaryCard(
          'متوسط سعر البيع',
          '${report.averageSalePrice.toStringAsFixed(2)} ر.س',
          Icons.trending_flat,
          Colors.blue,
        ),
        _buildSummaryCard(
          'متوسط هامش الربح',
          '${report.averageProfitMargin.toStringAsFixed(1)}%',
          Icons.percent,
          Colors.purple,
        ),
      ]),
    ]);
  }

  /// بناء المنتجات الأكثر ربحية
  Widget _buildTopProfitableProducts(InventoryReport report) {
    if (report.topProfitableProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection('المنتجات الأكثر ربحية', Icons.star, Colors.amber, [
      ...report.topProfitableProducts.take(5).map((product) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.star, color: Colors.amber[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'الكمية: ${product.quantity} • السعر: ${product.salePrice.toStringAsFixed(2)} ر.س',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${product.profitPerUnit.toStringAsFixed(2)} ر.س',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${product.profitMargin.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    ]);
  }

  /// بناء التوصيات
  Widget _buildRecommendations(InventoryReport report) {
    final recommendations = _generateRecommendations(report);

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection('التوصيات', Icons.lightbulb, Colors.orange, [
      ...recommendations.map((recommendation) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: recommendation.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: recommendation.color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(recommendation.icon, color: recommendation.color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: recommendation.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    ]);
  }

  /// بناء قسم
  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  /// بناء شبكة الملخص
  Widget _buildSummaryGrid(List<Widget> cards) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: cards,
    );
  }

  /// بناء بطاقة الملخص
  Widget _buildSummaryCard(
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة الحالة
  Widget _buildStatusCard(
    String title,
    int count,
    int total,
    Color color,
    IconData icon,
  ) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// إنشاء التقرير
  InventoryReport _generateReport() {
    if (products.isEmpty) {
      return InventoryReport.empty();
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
    final totalProfit = products.fold<double>(
      0,
      (sum, p) => sum + (p.profitPerUnit * p.quantity),
    );

    final availableProducts = products
        .where((p) => !p.isLowStock && !p.isOutOfStock)
        .length;
    final lowStockProducts = products
        .where((p) => p.isLowStock && !p.isOutOfStock)
        .length;
    final outOfStockProducts = products.where((p) => p.isOutOfStock).length;
    final expiredProducts = products.where((p) => p.isExpired).length;

    final companiesMap = <String, CompanyAnalysis>{};
    for (final product in products) {
      final company = product.company.isEmpty ? 'غير محدد' : product.company;
      if (companiesMap.containsKey(company)) {
        companiesMap[company] = companiesMap[company]!.copyWith(
          productCount: companiesMap[company]!.productCount + 1,
          totalValue:
              companiesMap[company]!.totalValue +
              (product.salePrice * product.quantity),
        );
      } else {
        companiesMap[company] = CompanyAnalysis(
          name: company,
          productCount: 1,
          totalValue: product.salePrice * product.quantity,
        );
      }
    }

    final companiesAnalysis = companiesMap.values.toList()
      ..sort((a, b) => b.productCount.compareTo(a.productCount));

    final topProfitableProducts = List<ProductModel>.from(products)
      ..sort((a, b) => b.profitPerUnit.compareTo(a.profitPerUnit));

    final salePrices = products.map((p) => p.salePrice).toList();
    final highestSalePrice = salePrices.isNotEmpty
        ? salePrices.reduce((a, b) => a > b ? a : b)
        : 0.0;
    final lowestSalePrice = salePrices.isNotEmpty
        ? salePrices.reduce((a, b) => a < b ? a : b)
        : 0.0;
    final averageSalePrice = salePrices.isNotEmpty
        ? salePrices.reduce((a, b) => a + b) / salePrices.length
        : 0.0;
    final averageProfitMargin = totalSaleValue > 0
        ? (totalProfit / totalSaleValue * 100)
        : 0.0;

    return InventoryReport(
      totalProducts: totalProducts,
      totalQuantity: totalQuantity,
      totalPurchaseValue: totalPurchaseValue,
      totalSaleValue: totalSaleValue,
      totalProfit: totalProfit,
      availableProducts: availableProducts,
      lowStockProducts: lowStockProducts,
      outOfStockProducts: outOfStockProducts,
      expiredProducts: expiredProducts,
      companiesAnalysis: companiesAnalysis,
      topProfitableProducts: topProfitableProducts,
      highestSalePrice: highestSalePrice,
      lowestSalePrice: lowestSalePrice,
      averageSalePrice: averageSalePrice,
      averageProfitMargin: averageProfitMargin,
    );
  }

  /// إنشاء التوصيات
  List<Recommendation> _generateRecommendations(InventoryReport report) {
    final recommendations = <Recommendation>[];

    if (report.outOfStockProducts > 0) {
      recommendations.add(
        Recommendation(
          message:
              'يوجد ${report.outOfStockProducts} منتج نافد المخزون - يحتاج إلى تجديد فوري',
          icon: Icons.error,
          color: Colors.red,
        ),
      );
    }

    if (report.lowStockProducts > 0) {
      recommendations.add(
        Recommendation(
          message:
              'يوجد ${report.lowStockProducts} منتج منخفض المخزون - يُنصح بالتجديد قريباً',
          icon: Icons.warning,
          color: Colors.orange,
        ),
      );
    }

    if (report.expiredProducts > 0) {
      recommendations.add(
        Recommendation(
          message:
              'يوجد ${report.expiredProducts} منتج منتهي الصلاحية - يحتاج إلى مراجعة',
          icon: Icons.dangerous,
          color: Colors.red[800]!,
        ),
      );
    }

    if (report.averageProfitMargin < 10) {
      recommendations.add(
        Recommendation(
          message:
              'هامش الربح منخفض (${report.averageProfitMargin.toStringAsFixed(1)}%) - راجع استراتيجية التسعير',
          icon: Icons.trending_down,
          color: Colors.orange,
        ),
      );
    }

    if (report.totalProducts < 10) {
      recommendations.add(
        Recommendation(
          message:
              'عدد المنتجات قليل - فكر في إضافة منتجات جديدة لتنويع المخزون',
          icon: Icons.add_circle,
          color: Colors.blue,
        ),
      );
    }

    return recommendations;
  }
}

/// نموذج تقرير المخزون
class InventoryReport {
  final int totalProducts;
  final int totalQuantity;
  final double totalPurchaseValue;
  final double totalSaleValue;
  final double totalProfit;
  final int availableProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final int expiredProducts;
  final List<CompanyAnalysis> companiesAnalysis;
  final List<ProductModel> topProfitableProducts;
  final double highestSalePrice;
  final double lowestSalePrice;
  final double averageSalePrice;
  final double averageProfitMargin;

  InventoryReport({
    required this.totalProducts,
    required this.totalQuantity,
    required this.totalPurchaseValue,
    required this.totalSaleValue,
    required this.totalProfit,
    required this.availableProducts,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.expiredProducts,
    required this.companiesAnalysis,
    required this.topProfitableProducts,
    required this.highestSalePrice,
    required this.lowestSalePrice,
    required this.averageSalePrice,
    required this.averageProfitMargin,
  });

  factory InventoryReport.empty() {
    return InventoryReport(
      totalProducts: 0,
      totalQuantity: 0,
      totalPurchaseValue: 0,
      totalSaleValue: 0,
      totalProfit: 0,
      availableProducts: 0,
      lowStockProducts: 0,
      outOfStockProducts: 0,
      expiredProducts: 0,
      companiesAnalysis: [],
      topProfitableProducts: [],
      highestSalePrice: 0,
      lowestSalePrice: 0,
      averageSalePrice: 0,
      averageProfitMargin: 0,
    );
  }
}

/// تحليل الشركة
class CompanyAnalysis {
  final String name;
  final int productCount;
  final double totalValue;

  CompanyAnalysis({
    required this.name,
    required this.productCount,
    required this.totalValue,
  });

  CompanyAnalysis copyWith({
    String? name,
    int? productCount,
    double? totalValue,
  }) {
    return CompanyAnalysis(
      name: name ?? this.name,
      productCount: productCount ?? this.productCount,
      totalValue: totalValue ?? this.totalValue,
    );
  }
}

/// التوصية
class Recommendation {
  final String message;
  final IconData icon;
  final Color color;

  Recommendation({
    required this.message,
    required this.icon,
    required this.color,
  });
}
