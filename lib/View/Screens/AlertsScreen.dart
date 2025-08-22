import 'package:flutter/material.dart';
import 'package:pos/View/style/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/ProductProvider.dart';
import 'package:pos/Model/ProductModel.dart';

/// شاشة التنبيهات
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ProductAlert> _allAlerts = [];
  List<ProductModel> _nearExpiryProducts = [];
  List<ProductModel> _expiredProducts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// تحميل التنبيهات
  Future<void> _loadAlerts() async {
    final provider = context.read<ProductProvider>();

    final alerts = provider.getAlerts();
    final nearExpiry = await provider.getNearExpiryProducts();
    final expired = await provider.getExpiredProducts();

    setState(() {
      _allAlerts = alerts;
      _nearExpiryProducts = nearExpiry;
      _expiredProducts = expired;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllAlertsTab(),
                _buildLowStockTab(),
                _buildNearExpiryTab(),
                _buildExpiredTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء شريط التطبيق
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.notifications, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'التنبيهات (${_allAlerts.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.accent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadAlerts,
        ),
      ],
    );
  }

  /// بناء شريط التبويبات
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.accent,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: AppColors.accent,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.notifications, size: 16),
                const SizedBox(width: 4),
                Text('الكل (${_allAlerts.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning, size: 16),
                const SizedBox(width: 4),
                Text(
                  'مخزون منخفض (${_allAlerts.where((a) => a.type == AlertType.lowStock || a.type == AlertType.outOfStock).length})',
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule, size: 16),
                const SizedBox(width: 4),
                Text('قريب الانتهاء (${_nearExpiryProducts.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.dangerous, size: 16),
                const SizedBox(width: 4),
                Text('منتهي (${_expiredProducts.length})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// تبويب جميع التنبيهات
  Widget _buildAllAlertsTab() {
    if (_allAlerts.isEmpty) {
      return _buildEmptyState(
        Icons.check_circle,
        'لا توجد تنبيهات',
        'جميع المنتجات في حالة جيدة',
        Colors.green,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allAlerts.length,
        itemBuilder: (context, index) {
          final alert = _allAlerts[index];
          return _buildAlertCard(alert);
        },
      ),
    );
  }

  /// تبويب المخزون المنخفض
  Widget _buildLowStockTab() {
    final lowStockAlerts = _allAlerts
        .where(
          (a) => a.type == AlertType.lowStock || a.type == AlertType.outOfStock,
        )
        .toList();

    if (lowStockAlerts.isEmpty) {
      return _buildEmptyState(
        Icons.inventory_2,
        'لا توجد تنبيهات مخزون',
        'جميع المنتجات لديها مخزون كافي',
        Colors.blue,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lowStockAlerts.length,
        itemBuilder: (context, index) {
          final alert = lowStockAlerts[index];
          return _buildAlertCard(alert);
        },
      ),
    );
  }

  /// تبويب قريب الانتهاء
  Widget _buildNearExpiryTab() {
    if (_nearExpiryProducts.isEmpty) {
      return _buildEmptyState(
        Icons.schedule,
        'لا توجد منتجات قريبة الانتهاء',
        'جميع المنتجات لديها تواريخ انتهاء بعيدة',
        Colors.amber,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _nearExpiryProducts.length,
        itemBuilder: (context, index) {
          final product = _nearExpiryProducts[index];
          return _buildProductCard(
            product,
            AlertType.nearExpiry,
            'قريب الانتهاء (${product.daysUntilExpiry} يوم متبقي)',
          );
        },
      ),
    );
  }

  /// تبويب منتهي الصلاحية
  Widget _buildExpiredTab() {
    if (_expiredProducts.isEmpty) {
      return _buildEmptyState(
        Icons.check_circle,
        'لا توجد منتجات منتهية الصلاحية',
        'جميع المنتجات صالحة للاستخدام',
        Colors.green,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _expiredProducts.length,
        itemBuilder: (context, index) {
          final product = _expiredProducts[index];
          return _buildProductCard(
            product,
            AlertType.expired,
            'منتهي الصلاحية',
          );
        },
      ),
    );
  }

  /// بناء حالة فارغة
  Widget _buildEmptyState(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: color),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة التنبيه
  Widget _buildAlertCard(ProductAlert alert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showProductDetails(alert.product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: alert.type.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(alert.type.icon, color: alert.type.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.type.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: alert.type.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(alert.message, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء بطاقة المنتج
  Widget _buildProductCard(
    ProductModel product,
    AlertType alertType,
    String alertMessage,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showProductDetails(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: alertType.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      alertType.icon,
                      color: alertType.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alertMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: alertType.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      'الكمية: ${product.quantity}',
                      Icons.numbers,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      'الكود: ${product.code}',
                      Icons.qr_code,
                    ),
                  ),
                ],
              ),
              if (product.expiryDate != null) ...[
                const SizedBox(height: 8),
                _buildInfoChip(
                  'تاريخ الانتهاء: ${product.expiryDate!.day}/${product.expiryDate!.month}/${product.expiryDate!.year}',
                  Icons.calendar_today,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// بناء رقاقة المعلومات
  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// عرض تفاصيل المنتج
  void _showProductDetails(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            if (product.isLowStock)
              Icon(Icons.warning, color: Colors.orange, size: 20),
            if (product.isOutOfStock)
              Icon(Icons.error, color: Colors.red, size: 20),
            if (product.isNearExpiry)
              Icon(Icons.schedule, color: Colors.amber, size: 20),
            if (product.isExpired)
              Icon(Icons.dangerous, color: Colors.red[800], size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(product.name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('الكود/الباركود', product.code),
              _buildDetailRow(
                'الوصف',
                product.description.isEmpty ? 'غير محدد' : product.description,
              ),
              _buildDetailRow('الكمية', '${product.quantity}'),
              _buildDetailRow('حد التنبيه', '${product.lowStockThreshold}'),
              _buildDetailRow(
                'سعر الشراء',
                '${product.buyPrice.toStringAsFixed(2)} ريال',
              ),
              _buildDetailRow(
                'سعر البيع',
                '${product.salePrice.toStringAsFixed(2)} ريال',
              ),
              _buildDetailRow('الشركة', product.company),
              _buildDetailRow('تاريخ الإضافة', product.date),
              if (product.expiryDate != null)
                _buildDetailRow(
                  'تاريخ الانتهاء',
                  '${product.expiryDate!.day}/${product.expiryDate!.month}/${product.expiryDate!.year}',
                ),
              if (product.daysUntilExpiry != null)
                _buildDetailRow(
                  'الأيام المتبقية',
                  '${product.daysUntilExpiry} يوم',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // يمكن إضافة وظيفة تعديل المنتج هنا
            },
            child: const Text('تعديل'),
          ),
        ],
      ),
    );
  }

  /// بناء صف التفاصيل
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }
}
