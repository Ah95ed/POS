import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/ProductProvider.dart';
import 'package:pos/Model/ProductModel.dart';
import 'package:pos/View/Widgets/InventoryReportWidget.dart';

/// شاشة تقارير المخزون
class InventoryReportsScreen extends StatefulWidget {
  const InventoryReportsScreen({super.key});

  @override
  State<InventoryReportsScreen> createState() => _InventoryReportsScreenState();
}

class _InventoryReportsScreenState extends State<InventoryReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await context.read<ProductProvider>().loadProducts();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تقارير المخزون',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.indigo[700],
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'التقرير المفصل'),
            Tab(icon: Icon(Icons.pie_chart), text: 'الإحصائيات'),
            Tab(icon: Icon(Icons.trending_up), text: 'تحليل الأداء'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _showExportDialog();
                  break;
                case 'print':
                  _showPrintDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('تصدير التقرير'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print, color: Colors.green),
                    SizedBox(width: 8),
                    Text('طباعة التقرير'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage.isNotEmpty) {
            return _buildErrorWidget(provider.errorMessage);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDetailedReportTab(provider),
              _buildStatisticsTab(provider),
              _buildPerformanceTab(provider),
            ],
          );
        },
      ),
    );
  }

  /// تبويب التقرير المفصل
  Widget _buildDetailedReportTab(ProductProvider provider) {
    return InventoryReportWidget(products: provider.products);
  }

  /// تبويب الإحصائيات
  Widget _buildStatisticsTab(ProductProvider provider) {
    final products = provider.products;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // إحصائيات الكميات
          _buildQuantityStatistics(products),

          const SizedBox(height: 20),

          // إحصائيات الأسعار
          _buildPriceStatistics(products),

          const SizedBox(height: 20),

          // إحصائيات الشركات
          _buildCompanyStatistics(products),

          const SizedBox(height: 20),

          // إحصائيات الحالة
          _buildStatusStatistics(products),
        ],
      ),
    );
  }

  /// تبويب تحليل الأداء
  Widget _buildPerformanceTab(ProductProvider provider) {
    final products = provider.products;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // أداء المبيعات
          _buildSalesPerformance(products),

          const SizedBox(height: 20),

          // أداء المخزون
          _buildInventoryPerformance(products),

          const SizedBox(height: 20),

          // توقعات الربح
          _buildProfitProjections(products),

          const SizedBox(height: 20),

          // مؤشرات الأداء الرئيسية
          _buildKPIs(products),
        ],
      ),
    );
  }

  /// بناء إحصائيات الكميات
  Widget _buildQuantityStatistics(List<ProductModel> products) {
    final totalQuantity = products.fold<int>(0, (sum, p) => sum + p.quantity);
    final averageQuantity = products.isNotEmpty
        ? totalQuantity / products.length
        : 0.0;
    final maxQuantity = products.isNotEmpty
        ? products.map((p) => p.quantity).reduce((a, b) => a > b ? a : b)
        : 0;
    final minQuantity = products.isNotEmpty
        ? products.map((p) => p.quantity).reduce((a, b) => a < b ? a : b)
        : 0;

    return _buildStatisticsCard(
      'إحصائيات الكميات',
      Icons.inventory,
      Colors.blue,
      [
        _buildStatRow('إجمالي الكميات', '$totalQuantity قطعة'),
        _buildStatRow(
          'متوسط الكمية',
          '${averageQuantity.toStringAsFixed(1)} قطعة',
        ),
        _buildStatRow('أعلى كمية', '$maxQuantity قطعة'),
        _buildStatRow('أقل كمية', '$minQuantity قطعة'),
      ],
    );
  }

  /// بناء إحصائيات الأسعار
  Widget _buildPriceStatistics(List<ProductModel> products) {
    if (products.isEmpty) return const SizedBox.shrink();

    final salePrices = products.map((p) => p.salePrice).toList();
    final buyPrices = products.map((p) => p.buyPrice).toList();

    final avgSalePrice =
        salePrices.fold<double>(0.0, (a, b) => a + b) / salePrices.length;
    final avgBuyPrice =
        buyPrices.fold<double>(0.0, (a, b) => a + b) / buyPrices.length;
    final maxSalePrice = salePrices.reduce((a, b) => a > b ? a : b);
    final minSalePrice = salePrices.reduce((a, b) => a < b ? a : b);

    return _buildStatisticsCard(
      'إحصائيات الأسعار',
      Icons.attach_money,
      Colors.green,
      [
        _buildStatRow(
          'متوسط سعر البيع',
          '${avgSalePrice.toStringAsFixed(2)} ر.س',
        ),
        _buildStatRow(
          'متوسط سعر الشراء',
          '${avgBuyPrice.toStringAsFixed(2)} ر.س',
        ),
        _buildStatRow('أعلى سعر بيع', '${maxSalePrice.toStringAsFixed(2)} ر.س'),
        _buildStatRow('أقل سعر بيع', '${minSalePrice.toStringAsFixed(2)} ر.س'),
      ],
    );
  }

  /// بناء إحصائيات الشركات
  Widget _buildCompanyStatistics(List<ProductModel> products) {
    final companiesMap = <String, int>{};
    for (final product in products) {
      final company = product.company.isEmpty ? 'غير محدد' : product.company;
      companiesMap[company] = (companiesMap[company] ?? 0) + 1;
    }

    final sortedCompanies = companiesMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildStatisticsCard(
      'إحصائيات الشركات',
      Icons.business,
      Colors.purple,
      [
        _buildStatRow('عدد الشركات', '${companiesMap.length} شركة'),
        ...sortedCompanies.take(3).map((entry) {
          return _buildStatRow(entry.key, '${entry.value} منتج');
        }),
      ],
    );
  }

  /// بناء إحصائيات الحالة
  Widget _buildStatusStatistics(List<ProductModel> products) {
    final available = products
        .where((p) => !p.isLowStock && !p.isOutOfStock)
        .length;
    final lowStock = products
        .where((p) => p.isLowStock && !p.isOutOfStock)
        .length;
    final outOfStock = products.where((p) => p.isOutOfStock).length;
    final expired = products.where((p) => p.isExpired).length;

    return _buildStatisticsCard(
      'إحصائيات الحالة',
      Icons.pie_chart,
      Colors.orange,
      [
        _buildStatRow('متوفر', '$available منتج', color: Colors.green),
        _buildStatRow('مخزون منخفض', '$lowStock منتج', color: Colors.orange),
        _buildStatRow('نافد المخزون', '$outOfStock منتج', color: Colors.red),
        _buildStatRow(
          'منتهي الصلاحية',
          '$expired منتج',
          color: Colors.red[800],
        ),
      ],
    );
  }

  /// بناء أداء المبيعات
  Widget _buildSalesPerformance(List<ProductModel> products) {
    final totalSaleValue = products.fold<double>(
      0.0,
      (sum, p) => sum + (p.salePrice * p.quantity),
    );
    final totalPurchaseValue = products.fold<double>(
      0.0,
      (sum, p) => sum + (p.buyPrice * p.quantity),
    );
    final totalProfit = totalSaleValue - totalPurchaseValue;
    final profitMargin = totalSaleValue > 0
        ? (totalProfit / totalSaleValue * 100)
        : 0;

    return _buildStatisticsCard(
      'أداء المبيعات المتوقع',
      Icons.trending_up,
      Colors.indigo,
      [
        _buildStatRow(
          'قيمة المبيعات المتوقعة',
          '${totalSaleValue.toStringAsFixed(2)} ر.س',
        ),
        _buildStatRow(
          'تكلفة الشراء',
          '${totalPurchaseValue.toStringAsFixed(2)} ر.س',
        ),
        _buildStatRow(
          'الربح المتوقع',
          '${totalProfit.toStringAsFixed(2)} ر.س',
          color: Colors.green,
        ),
        _buildStatRow(
          'هامش الربح',
          '${profitMargin.toStringAsFixed(1)}%',
          color: Colors.green,
        ),
      ],
    );
  }

  /// بناء أداء المخزون
  Widget _buildInventoryPerformance(List<ProductModel> products) {
    final totalProducts = products.length;
    final activeProducts = products.where((p) => !p.isArchived).length;
    final healthyStock = products
        .where((p) => !p.isLowStock && !p.isOutOfStock && !p.isExpired)
        .length;
    final healthPercentage = totalProducts > 0
        ? (healthyStock / totalProducts * 100)
        : 0;

    return _buildStatisticsCard(
      'أداء المخزون',
      Icons.inventory_2,
      Colors.teal,
      [
        _buildStatRow('إجمالي المنتجات', '$totalProducts منتج'),
        _buildStatRow('المنتجات النشطة', '$activeProducts منتج'),
        _buildStatRow(
          'المخزون الصحي',
          '$healthyStock منتج',
          color: Colors.green,
        ),
        _buildStatRow(
          'نسبة الصحة',
          '${healthPercentage.toStringAsFixed(1)}%',
          color: healthPercentage >= 80
              ? Colors.green
              : healthPercentage >= 60
              ? Colors.orange
              : Colors.red,
        ),
      ],
    );
  }

  /// بناء توقعات الربح
  Widget _buildProfitProjections(List<ProductModel> products) {
    final monthlyProfit = products.fold<double>(
      0.0,
      (sum, p) => sum + (p.profitMargin * p.quantity * 0.1),
    ); // افتراض بيع 10% شهرياً
    final yearlyProfit = monthlyProfit * 12;
    final bestProduct = products.isNotEmpty
        ? products.reduce((a, b) => a.profitMargin > b.profitMargin ? a : b)
        : null;

    return _buildStatisticsCard(
      'توقعات الربح',
      Icons.monetization_on,
      Colors.amber,
      [
        _buildStatRow(
          'الربح الشهري المتوقع',
          '${monthlyProfit.toStringAsFixed(2)} ر.س',
        ),
        _buildStatRow(
          'الربح السنوي المتوقع',
          '${yearlyProfit.toStringAsFixed(2)} ر.س',
        ),
        if (bestProduct != null)
          _buildStatRow('أفضل منتج ربحية', bestProduct.name),
        if (bestProduct != null)
          _buildStatRow(
            'ربح الوحدة',
            '${bestProduct.profitMargin.toStringAsFixed(2)} ر.س',
          ),
      ],
    );
  }

  /// بناء مؤشرات الأداء الرئيسية
  Widget _buildKPIs(List<ProductModel> products) {
    final totalValue = products.fold<double>(
      0.0,
      (sum, p) => sum + (p.salePrice * p.quantity),
    );
    final averageValue = products.isNotEmpty ? totalValue / products.length : 0;
    final stockTurnover = 12.0; // افتراض دوران المخزون 12 مرة سنوياً
    final inventoryDays = 365 / stockTurnover;

    return _buildStatisticsCard(
      'مؤشرات الأداء الرئيسية (KPIs)',
      Icons.dashboard,
      Colors.deepPurple,
      [
        _buildStatRow(
          'قيمة المخزون الإجمالية',
          '${totalValue.toStringAsFixed(2)} ر.س',
        ),
        _buildStatRow(
          'متوسط قيمة المنتج',
          '${averageValue.toStringAsFixed(2)} ر.س',
        ),
        _buildStatRow(
          'دوران المخزون (سنوي)',
          '${stockTurnover.toStringAsFixed(1)} مرة',
        ),
        _buildStatRow(
          'أيام المخزون',
          '${inventoryDays.toStringAsFixed(0)} يوم',
        ),
      ],
    );
  }

  /// بناء بطاقة الإحصائيات
  Widget _buildStatisticsCard(
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
                    fontSize: 16,
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

  /// بناء صف الإحصائية
  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء widget الخطأ
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  /// عرض نافذة التصدير
  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصدير التقرير'),
        content: const Text('سيتم إضافة ميزة التصدير قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  /// عرض نافذة الطباعة
  void _showPrintDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('طباعة التقرير'),
        content: const Text('سيتم إضافة ميزة الطباعة قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}
