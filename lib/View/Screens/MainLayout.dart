import 'package:flutter/material.dart';
import 'package:pos/Helper/Locale/Language.dart';
import 'package:pos/Helper/Log/LogApp.dart';
import 'package:pos/Helper/Service/Service.dart';
import 'package:pos/Helper/Utils/DeviceUtils.dart';
import 'package:pos/View/Screens/DashboardScreen.dart';
import 'package:pos/View/Screens/ProductsScreen.dart';
import 'package:pos/View/Screens/SalesScreen.dart';
import 'package:pos/View/Screens/CustomersScreen.dart';
import 'package:pos/View/Screens/InvoicesScreen.dart';
import 'package:pos/View/Screens/DebtsScreen.dart';
import 'package:pos/View/Screens/SettingsScreen.dart';
import 'package:pos/View/style/app_colors.dart';
import 'package:smart_sizer/smart_sizer.dart' hide DeviceUtils;

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProductsScreen(),
    const SalesScreen(),
    const CustomersScreen(),
    const InvoicesScreen(),
    const DebtsScreen(),
    const SettingsScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      title: trans[Language.dashboard],
      icon: Icons.dashboard,
      selectedIcon: Icons.dashboard,
    ),
    NavigationItem(
      title: trans[Language.warehouse],
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
    ),
    NavigationItem(
      title: trans[Language.pointofsale],
      icon: Icons.point_of_sale_outlined,
      selectedIcon: Icons.point_of_sale,
    ),
    NavigationItem(
      title: 'العملاء',
      icon: Icons.people_outlined,
      selectedIcon: Icons.people,
    ),
    NavigationItem(
      title: 'الفواتير',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    NavigationItem(
      title: 'الديون والحسابات',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
    ),
    // NavigationItem(
    //   title: 'المشتريات',
    //   icon: Icons.shopping_cart_outlined,
    //   selectedIcon: Icons.shopping_cart,
    // ),
    // NavigationItem(
    //   title: 'التقارير',
    //   icon: Icons.analytics_outlined,
    //   selectedIcon: Icons.analytics,
    // ),
    NavigationItem(
      title: 'الإعدادات',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isWideScreen = context.screenWidth > 800;

    return Scaffold(
      appBar: DeviceUtils.isMobile(context) ? AppBar() : null,
      body: Row(
        
        children: [
          // Side Navigation
          if (isWideScreen) Expanded(flex:1,child:  _buildSideNavigation()),

          // Main Content
          Expanded(
            flex: 5,
            child: _screens[_selectedIndex]),
        ],
      ),
      drawer: !isWideScreen
          ? _buildDrawer()
          : Drawer(
              child: Column(
                children: [
                  // Header
                  _buildNavigationHeader(),

                  // Navigation Items
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _navigationItems.length,
                      itemBuilder: (context, index) {
                        return _buildNavigationTile(index, isDrawer: true);
                      },
                    ),
                  ),

                  // Footer
                  _buildNavigationFooter(),
                ],
              ),
            ),
    );
  }

  Widget _buildSideNavigation() {
    return Container(
      width: context.getWidth(100),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildNavigationHeader(),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                return _buildNavigationTile(index);
              },
            ),
          ),

          // Footer
          _buildNavigationFooter(),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Header
          _buildNavigationHeader(),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                return _buildNavigationTile(index, isDrawer: true);
              },
            ),
          ),

          // Footer
          _buildNavigationFooter(),
        ],
      ),
    );
  }

  Widget _buildNavigationHeader() {
    return Container(
      height: context.getHeight(170),
      width: context.getWidth(100),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.curveTop1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: context.getMinSize(60),
            height: context.getMinSize(60),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.store,
              size: context.getMinSize(20),
              color: AppColors.textMain,
            ),
          ),
          SizedBox(height: context.getHeight(4)),
          Text(
            trans[Language.pos],
            style: TextStyle(
              color: AppColors.background,
              fontSize: context.getFontSize(10),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'إدارة شاملة لمتجرك',
            style: TextStyle(
              color: AppColors.background,
              fontSize: context.getFontSize(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile(int index, {bool isDrawer = false}) {
    final item = _navigationItems[index];
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          isSelected ? item.selectedIcon : item.icon,
          color: isSelected ? AppColors.accent : AppColors.textMain,
          size: context.getMinSize(24),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: isSelected ? AppColors.accent : AppColors.textMain,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: context.getFontSize(16),
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppColors.accent.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          if (isDrawer) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildNavigationFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.textMain.withOpacity(0.2)),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.help_outline,
              color: AppColors.textMain.withOpacity(0.7),
            ),
            title: Text(
              'المساعدة',
              style: TextStyle(color: AppColors.textMain),
            ),
            onTap: () {
              _showHelpDialog();
            },
          ),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: AppColors.textMain.withOpacity(0.7),
            ),
            title: Text(
              'حول التطبيق',
              style: TextStyle(color: AppColors.textMain),
            ),
            onTap: () {
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('المساعدة'),
        content: const Text(
          'مرحباً بك في نظام نقطة البيع\n\n'
          'يمكنك التنقل بين الصفحات المختلفة من القائمة الجانبية:\n'
          '• لوحة التحكم: عرض الإحصائيات العامة\n'
          '• المنتجات: إدارة المنتجات والمخزون\n'
          '• المبيعات: تسجيل وإدارة المبيعات\n'
          '• المشتريات: تسجيل وإدارة المشتريات\n'
          '• التقارير: عرض التقارير والتحليلات\n'
          '• الإعدادات: إعدادات التطبيق',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'نظام نقطة البيع',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.store, size: 48),
      children: [
        const Text('نظام شامل لإدارة نقطة البيع'),
        const Text('تم تطويره باستخدام Flutter'),
      ],
    );
  }
}

class NavigationItem {
  final String title;
  final IconData icon;
  final IconData selectedIcon;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.selectedIcon,
  });
}
