import 'package:flutter/material.dart';
import 'package:pos/Helper/Locale/Language.dart';
import 'package:pos/Helper/Service/Service.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/DashboardProvider.dart';
import 'package:pos/Model/DashboardModel.dart';
import 'package:pos/View/style/app_colors.dart';
import 'package:smart_sizer/smart_sizer.dart';

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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DeviceUtils.isMobile(context)
          ? null
          : AppBar(
              // centerTitle: true,
              // title:  Text(
              // trans[Language.dashboard] ,
              //   style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.background),
              // ),
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
            ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashboardProvider, child) {
          if (dashboardProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dashboardProvider.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.textMain.withOpacity(0.6),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    dashboardProvider.errorMessage,
                    style: TextStyle(fontSize: 16, color: AppColors.textMain),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  ElevatedButton(
                    onPressed: () {
                      dashboardProvider.refreshDashboard();
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: dashboardProvider.refreshDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  _buildWelcomeSection(screenWidth, screenHeight),
                  SizedBox(height: screenHeight * 0.03),

                  // Statistics Cards
                  _buildStatisticsSection(
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
      ),
    );
  }

  Widget _buildWelcomeSection(double screenWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
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
            crossAxisCount: 2,
            crossAxisSpacing: screenWidth * 0.03,
            mainAxisSpacing: screenHeight * 0.02,
            childAspectRatio: 1.2,
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
            TextButton(
              onPressed: () {
                // Navigate to full list
              },
              child: const Text('عرض الكل'),
            ),
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
          child: topItems.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Center(
                    child: Text(
                      'لا توجد منتجات',
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
                  itemCount: topItems.length,
                  separatorBuilder: (context, index) => Divider(
                    color: AppColors.textMain.withOpacity(0.2),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final item = topItems[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.accent.withOpacity(0.2),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'الكود: ${item.code}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.revenue.toStringAsFixed(2)} ريال',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          Text(
                            'الكمية: ${item.quantitySold}',
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
                color: Colors.grey[800],
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to full transactions list
              },
              child: const Text('عرض الكل'),
            ),
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
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                            '${transaction.amount.toStringAsFixed(2)} ريال',
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
