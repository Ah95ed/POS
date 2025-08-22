import 'package:flutter/material.dart';
import 'package:pos/View/style/app_colors.dart';
import 'package:smart_sizer/smart_sizer.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'التقارير',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white),
            onPressed: () {
              // تصدير التقارير
            },
          ),
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.white),
            onPressed: () {
              // اختيار فترة زمنية
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: context.getMinSize(30),
              color: AppColors.isDark ? Colors.white70 : Colors.grey,
            ),
            SizedBox(height: context.getHeight(5)),
            Text(
              'صفحة التقارير',
              style: TextStyle(
                fontSize: context.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            SizedBox(height: context.getHeight(2)),
            Text(
              'هنا يمكنك عرض جميع التقارير والتحليلات',
              style: TextStyle(
                fontSize: context.getFontSize(14),
                color: AppColors.textMain.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.getHeight(5)),
            _buildReportCard(
              title: 'تقرير المبيعات',
              icon: Icons.shopping_cart,
              onTap: () {
                // عرض تقرير المبيعات
              },
            ),
            SizedBox(height: context.getHeight(3)),
            _buildReportCard(
              title: 'تقرير المخزون',
              icon: Icons.inventory,
              onTap: () {
                // عرض تقرير المخزون
              },
            ),
            SizedBox(height: context.getHeight(3)),
            _buildReportCard(
              title: 'تقرير الأرباح',
              icon: Icons.trending_up,
              onTap: () {
                // عرض تقرير الأرباح
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.card,
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: context.getWidth(5)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.getMinSize(3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.getMinSize(3)),
        child: Padding(
          padding: EdgeInsets.all(context.getMinSize(4)),
          child: Row(
            children: [
              Icon(
                icon,
                size: context.getMinSize(10),
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(width: context.getWidth(5)),
              Text(
                title,
                style: TextStyle(
                  fontSize: context.getFontSize(14),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: context.getMinSize(5),
                color: AppColors.textMain.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
