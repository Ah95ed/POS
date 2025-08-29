import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/DashboardProvider.dart';
import 'package:pos/Model/DashboardModel.dart';
import 'package:pos/View/style/app_colors.dart';
import 'package:smart_sizer/smart_sizer.dart';
import 'package:pos/Helper/Constants/AppConstants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().initializeDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboardProvider, child) {
          if (dashboardProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dashboardProvider.errorMessage.isNotEmpty) {
            return _buildErrorWidget(context, dashboardProvider);
          }

          return _buildDashboardContent(context, dashboardProvider);
        },
      ),
    );
  }

  /// بناء شريط التطبيق
  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    return MediaQuery.of(context).size.width < 600
        ? null
        : AppBar(
            backgroundColor: AppColors.accent,
            elevation: 4,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: AppColors.background),
                onPressed: () {
                  context.read<DashboardProvider>().refreshDashboard();
                },
              ),
            ],
          );
  }

  /// بناء widget الخطأ
  Widget _buildErrorWidget(BuildContext context, DashboardProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.textMain.withOpacity(0.6),
              ),
              SizedBox(height: constraints.maxHeight * 0.02),
              Text(
                provider.errorMessage,
                style: TextStyle(fontSize: 16, color: AppColors.textMain),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: constraints.maxHeight * 0.02),
              ElevatedButton(
                onPressed: () {
                  provider.refreshDashboard();
                },
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// بناء محتوى الشاشة الرئيسي
  Widget _buildDashboardContent(
    BuildContext context,
    DashboardProvider dashboardProvider,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final screenWidth = constraints.maxWidth;

        return RefreshIndicator(
          onRefresh: dashboardProvider.refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(screenWidth * 0.01),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                _buildWelcomeSection(screenWidth, screenHeight),
                SizedBox(height: screenHeight * 0.02),

                // Statistics Cards
                _buildStatisticsSection(
                  dashboardProvider,
                  screenWidth,
                  screenHeight,
                ),
                SizedBox(height: screenHeight * 0.03),

                // Sales Stats + Date Range
                _buildSalesStatsSection(
                  dashboardProvider,
                  screenWidth,
                  screenHeight,
                ),
                SizedBox(height: screenHeight * 0.03),

                // Invoice Status distribution
                _buildInvoiceStatusSection(
                  dashboardProvider,
                  screenWidth,
                  screenHeight,
                ),
                SizedBox(height: screenHeight * 0.03),

                // Top Customers
                _buildTopCustomersSection(
                  dashboardProvider,
                  screenWidth,
                  screenHeight,
                ),
                SizedBox(height: screenHeight * 0.03),

                // Top Selling Items
                _buildTopSellingSection(
                  dashboardProvider,
                  screenWidth,
                  screenHeight,
                ),
                SizedBox(height: screenHeight * 0.03),

                // Recent Transactions
                _buildRecentTransactionsSection(
                  dashboardProvider,
                  screenWidth,
                  screenHeight,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(double screenWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.02),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.curveTop1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مرحباً بك في نظام نقطة البيع',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.background,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            'إدارة شاملة لمتجرك',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.background.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(
    DashboardProvider provider,
    double screenWidth,
    double screenHeight,
  ) {
    final stats = provider.getDashboardStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الإحصائيات',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: DeviceUtils.valueDecider(
              context,
              onMobile: 1,
              onTablet: 2,
              onDesktop: 3,
            ),
            crossAxisSpacing: screenWidth * 0.04,
            mainAxisSpacing: screenHeight * 0.04,
            childAspectRatio: 1.3,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return _buildStatCard(stat, screenWidth, screenHeight);
          },
        ),
      ],
    );
  }

  Widget _buildSalesStatsSection(
    DashboardProvider provider,
    double screenWidth,
    double screenHeight,
  ) {
    final s = provider.dashboardData.salesStats;

    // In case we need a simple line chart for revenue trend later, keep layout ready
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.02),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'إحصائيات المبيعات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              _buildDateRangePicker(provider),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          if (s == null)
            Text(
              'لا توجد بيانات للفترة المحددة',
              style: TextStyle(color: AppColors.textMain.withOpacity(0.7)),
            )
          else ...[
            Wrap(
              spacing: screenWidth * 0.04,
              runSpacing: screenHeight * 0.02,
              children: [
                _miniStat(
                  'عدد الفواتير',
                  s.totalSales.toString(),
                  Icons.receipt_long,
                  Colors.blue,
                ),
                _miniStat(
                  'الإيرادات',
                  AppConstants.formatCurrency(s.totalRevenue),
                  Icons.attach_money,
                  Colors.green,
                ),
                _miniStat(
                  'متوسط الفاتورة',
                  AppConstants.formatCurrency(s.averageSaleAmount),
                  Icons.analytics,
                  Colors.orange,
                ),
                _miniStat(
                  'العناصر المباعة',
                  s.totalItems.toString(),
                  Icons.shopping_bag,
                  Colors.purple,
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
          ],
        ],
      ),
    );
  }

  Widget _miniStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textMain.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMain.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Widget _buildDateRangePicker(DashboardProvider provider) {
    final hasRange = provider.startDate != null && provider.endDate != null;
    return Row(
      children: [
        IconButton(
          tooltip: 'تحديد نطاق التاريخ',
          icon: Icon(
            Icons.date_range,
            color: hasRange
                ? AppColors.accent
                : AppColors.textMain.withOpacity(0.7),
          ),
          onPressed: () async {
            final initialRange = hasRange
                ? DateTimeRange(
                    start: provider.startDate!,
                    end: provider.endDate!,
                  )
                : null;
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              initialDateRange: initialRange,
              locale: const Locale('ar'),
            );
            if (picked != null) {
              await provider.setDateRange(
                DateTime(
                  picked.start.year,
                  picked.start.month,
                  picked.start.day,
                ),
                DateTime(
                  picked.end.year,
                  picked.end.month,
                  picked.end.day,
                  23,
                  59,
                  59,
                ),
              );
            }
          },
        ),
        if (hasRange)
          Container(
            margin: const EdgeInsetsDirectional.only(start: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accent.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month, size: 14),
                const SizedBox(width: 6),
                Text(
                  'من ${_formatDate(provider.startDate!)} إلى ${_formatDate(provider.endDate!)}',
                  style: TextStyle(fontSize: 12, color: AppColors.textMain),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => provider.setDateRange(null, null),
                  child: const Icon(Icons.close, size: 14),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInvoiceStatusSection(
    DashboardProvider provider,
    double screenWidth,
    double screenHeight,
  ) {
    final data = provider.dashboardData.invoiceStatusCounts ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'حالات الفواتير',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        Container(
          padding: EdgeInsets.all(screenWidth * 0.02),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          height: 200,
          child: data.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد بيانات',
                    style: TextStyle(
                      color: AppColors.textMain.withOpacity(0.7),
                    ),
                  ),
                )
              : PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: _buildInvoiceStatusSections(data),
                  ),
                ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildInvoiceStatusSections(Map<String, int> data) {
    final colors = [Colors.green, Colors.orange, Colors.red, Colors.blueGrey];
    final keys = data.keys.toList();
    final total = data.values.fold<int>(0, (a, b) => a + b);
    return [
      for (int i = 0; i < keys.length; i++)
        PieChartSectionData(
          color: colors[i % colors.length],
          value: data[keys[i]]!.toDouble(),
          title: total == 0
              ? '0%'
              : '${((data[keys[i]]! / total) * 100).toStringAsFixed(0)}%\n${keys[i]}',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
        ),
    ];
  }

  Widget _buildTopCustomersSection(
    DashboardProvider provider,
    double screenWidth,
    double screenHeight,
  ) {
    final customers = provider.dashboardData.topCustomers ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'أفضل العملاء',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            TextButton(onPressed: () {}, child: const Text('عرض الكل')),
          ],
        ),
        SizedBox(height: screenHeight * 0.02),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: customers.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Center(
                    child: Text(
                      'لا يوجد عملاء',
                      style: TextStyle(
                        color: AppColors.textMain.withOpacity(0.7),
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: customers.length,
                  separatorBuilder: (_, __) => Divider(
                    color: AppColors.textMain.withOpacity(0.2),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final c = customers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.accent.withOpacity(0.15),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        c.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'المشتريات: ${AppConstants.formatCurrency(c.totalPurchases)}',
                      ),
                      trailing: c.isVip
                          ? const Icon(Icons.star, color: Colors.amber)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    DashboardStats stat,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(stat.icon, size: 32, color: stat.color),
          SizedBox(height: screenHeight * 0.01),
          Text(
            stat.value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: stat.color,
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          Text(
            stat.title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMain.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            stat.subtitle,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textMain.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSellingSection(
    DashboardProvider provider,
    double screenWidth,
    double screenHeight,
  ) {
    final topItems = provider.dashboardData.topSellingItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'أفضل المنتجات مبيعاً',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            TextButton(onPressed: () {}, child: const Text('عرض الكل')),
          ],
        ),
        SizedBox(height: screenHeight * 0.02),
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: EdgeInsets.all(screenWidth * 0.02),
          child: topItems.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد منتجات',
                    style: TextStyle(fontSize: 14, color: AppColors.textMain),
                  ),
                )
              : SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY:
                          topItems
                              .map((e) => e.quantitySold.toDouble())
                              .fold<double>(0, (p, c) => c > p ? c : p) +
                          2,
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= topItems.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  topItems[index].code,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      barGroups: [
                        for (int i = 0; i < topItems.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: topItems[i].quantitySold.toDouble(),
                                color: AppColors.accent,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsSection(
    DashboardProvider provider,
    double screenWidth,
    double screenHeight,
  ) {
    final transactions = provider.dashboardData.recentTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'المعاملات الأخيرة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            TextButton(onPressed: () {}, child: const Text('عرض الكل')),
          ],
        ),
        SizedBox(height: screenHeight * 0.02),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: transactions.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Center(
                    child: Text(
                      'لا توجد معاملات',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMain.withOpacity(0.7),
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.take(5).length,
                  separatorBuilder: (context, index) => Divider(
                    color: AppColors.textMain.withOpacity(0.2),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: transaction.type == 'sale'
                            ? Colors.green[100]
                            : Colors.orange[100],
                        child: Icon(
                          transaction.type == 'sale'
                              ? Icons.trending_up
                              : Icons.shopping_cart,
                          color: transaction.type == 'sale'
                              ? Colors.green[700]
                              : Colors.orange[700],
                        ),
                      ),
                      title: Text(
                        transaction.itemName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${transaction.type == 'sale' ? 'مبيعات' : 'مشتريات'} - ${transaction.itemCode}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppConstants.formatCurrency(transaction.amount),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: transaction.type == 'sale'
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                          Text(
                            transaction.date,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
