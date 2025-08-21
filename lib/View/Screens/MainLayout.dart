import 'package:flutter/material.dart';
import 'package:pos/View/Screens/DashboardScreen.dart';
import 'package:pos/View/Screens/ProductsScreen.dart';
import 'package:pos/View/Screens/SalesScreen.dart';
import 'package:pos/View/Screens/PurchasesScreen.dart';
import 'package:pos/View/Screens/ReportsScreen.dart';
import 'package:pos/View/Screens/SettingsScreen.dart';

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
    const PurchasesScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      title: 'لوحة التحكم',
      icon: Icons.dashboard,
      selectedIcon: Icons.dashboard,
    ),
    NavigationItem(
      title: 'المنتجات',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
    ),
    NavigationItem(
      title: 'المبيعات',
      icon: Icons.point_of_sale_outlined,
      selectedIcon: Icons.point_of_sale,
    ),
    NavigationItem(
      title: 'المشتريات',
      icon: Icons.shopping_cart_outlined,
      selectedIcon: Icons.shopping_cart,
    ),
    NavigationItem(
      title: 'التقارير',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
    ),
    NavigationItem(
      title: 'الإعدادات',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    return Scaffold(
      body: Row(
        children: [
          // Side Navigation
          if (isWideScreen) _buildSideNavigation(),

          // Main Content
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
      drawer: !isWideScreen ? _buildDrawer() : null,
    );
  }

  Widget _buildSideNavigation() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.store, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'نظام نقطة البيع',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'إدارة شاملة لمتجرك',
            style: TextStyle(color: Colors.white70, fontSize: 14),
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
          color: isSelected ? Colors.blue[700] : Colors.grey[600],
          size: 24,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: isSelected ? Colors.blue[700] : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        selected: isSelected,
        selectedTileColor: Colors.blue[50],
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
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.help_outline, color: Colors.grey[600]),
            title: Text('المساعدة', style: TextStyle(color: Colors.grey[800])),
            onTap: () {
              _showHelpDialog();
            },
          ),
          ListTile(
            leading: Icon(Icons.info_outline, color: Colors.grey[600]),
            title: Text(
              'حول التطبيق',
              style: TextStyle(color: Colors.grey[800]),
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
