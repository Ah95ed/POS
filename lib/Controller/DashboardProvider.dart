import 'package:flutter/material.dart';
import 'package:pos/Helper/DataBase/DataBaseSqflite.dart';
import 'package:pos/Helper/Log/LogApp.dart';
import 'package:pos/Model/DashboardModel.dart';

class DashboardProvider extends ChangeNotifier {
  final DataBaseSqflite _database = DataBaseSqflite();

  DashboardModel _dashboardData = DashboardModel.empty();
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  DashboardModel get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Initialize dashboard data
  Future<void> initializeDashboard() async {
    await loadDashboardData();
  }

  // Load all dashboard data
  Future<void> loadDashboardData() async {
    try {
      _setLoading(true);
      _errorMessage = '';

      // Load all data concurrently
      final results = await Future.wait([
        _getTotalItems(),
        _getTotalSalesValue(),
        _getTotalPurchaseValue(),
        _getLowStockItems(),
        _getTopSellingItems(),
        _getRecentTransactions(),
      ]);

      final totalItems = results[0] as int;
      final totalSalesValue = results[1] as double;
      final totalPurchaseValue = results[2] as double;
      final lowStockItems = results[3] as int;
      final topSellingItems = results[4] as List<TopSellingItem>;
      final recentTransactions = results[5] as List<RecentTransaction>;

      _dashboardData = DashboardModel(
        totalItems: totalItems,
        totalSalesValue: totalSalesValue,
        totalPurchaseValue: totalPurchaseValue,
        totalProfit: totalSalesValue - totalPurchaseValue,
        lowStockItems: lowStockItems,
        topSellingItems: topSellingItems,
        recentTransactions: recentTransactions,
      );

      logInfo("Dashboard data loaded successfully");
    } catch (e) {
      _errorMessage = 'خطأ في تحميل بيانات الداشبورد: $e';
      logInfo("Error loading dashboard data: $e");
    } finally {
      _setLoading(false);
    }
  }

  // Refresh dashboard data
  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<int> _getTotalItems() async {
    try {
      final items = await _database.getAllData();
      return items.length;
    } catch (e) {
      logInfo("Error getting total items: $e");
      return 0;
    }
  }

  Future<double> _getTotalSalesValue() async {
    try {
      final items = await _database.getAllData();
      double total = 0.0;

      for (var item in items) {
        if (item != null && item['Sale'] != null) {
          String saleStr = item['Sale'].toString().replaceAll(
            RegExp(r'[^0-9.]'),
            '',
          );
          double salePrice = double.tryParse(saleStr) ?? 0.0;
          int quantity = int.tryParse(item['Quantity'].toString()) ?? 0;
          total += salePrice * quantity;
        }
      }

      return total;
    } catch (e) {
      logInfo("Error calculating total sales value: $e");
      return 0.0;
    }
  }

  Future<double> _getTotalPurchaseValue() async {
    try {
      final items = await _database.getAllData();
      double total = 0.0;

      for (var item in items) {
        if (item != null && item['Buy'] != null) {
          String buyStr = item['Buy'].toString().replaceAll(
            RegExp(r'[^0-9.]'),
            '',
          );
          double buyPrice = double.tryParse(buyStr) ?? 0.0;
          int quantity = int.tryParse(item['Quantity'].toString()) ?? 0;
          total += buyPrice * quantity;
        }
      }

      return total;
    } catch (e) {
      logInfo("Error calculating total purchase value: $e");
      return 0.0;
    }
  }

  Future<int> _getLowStockItems() async {
    try {
      final items = await _database.getAllData();
      int lowStockCount = 0;

      for (var item in items) {
        if (item != null && item['Quantity'] != null) {
          int quantity = int.tryParse(item['Quantity'].toString()) ?? 0;
          if (quantity < 10) {
            // Consider items with less than 10 as low stock
            lowStockCount++;
          }
        }
      }

      return lowStockCount;
    } catch (e) {
      logInfo("Error getting low stock items: $e");
      return 0;
    }
  }

  Future<List<TopSellingItem>> _getTopSellingItems() async {
    try {
      final items = await _database.getAllData();
      List<TopSellingItem> topItems = [];

      for (var item in items) {
        if (item != null) {
          topItems.add(TopSellingItem.fromMap(item));
        }
      }

      // Sort by revenue (sale price * quantity) and take top 5
      topItems.sort(
        (a, b) =>
            (b.revenue * b.quantitySold).compareTo(a.revenue * a.quantitySold),
      );
      return topItems.take(5).toList();
    } catch (e) {
      logInfo("Error getting top selling items: $e");
      return [];
    }
  }

  Future<List<RecentTransaction>> _getRecentTransactions() async {
    try {
      final items = await _database.getAllData();
      List<RecentTransaction> transactions = [];

      // Create mock recent transactions based on items
      // In a real app, you would have a separate transactions table
      for (var item in items) {
        if (item != null && transactions.length < 10) {
          // Add as sale transaction
          transactions.add(RecentTransaction.fromMap(item, 'sale'));
        }
      }

      return transactions;
    } catch (e) {
      logInfo("Error getting recent transactions: $e");
      return [];
    }
  }

  // Get dashboard statistics for display
  List<DashboardStats> getDashboardStats() {
    return [
      DashboardStats(
        title: 'إجمالي المنتجات',
        value: _dashboardData.totalItems.toString(),
        subtitle: 'منتج',
        icon: Icons.inventory,
        color: Colors.blue,
      ),
      DashboardStats(
        title: 'قيمة المبيعات',
        value: _dashboardData.totalSalesValue.toStringAsFixed(2),
        subtitle: 'ريال',
        icon: Icons.trending_up,
        color: Colors.green,
      ),
      DashboardStats(
        title: 'قيمة المشتريات',
        value: _dashboardData.totalPurchaseValue.toStringAsFixed(2),
        subtitle: 'ريال',
        icon: Icons.shopping_cart,
        color: Colors.orange,
      ),
      DashboardStats(
        title: 'صافي الربح',
        value: _dashboardData.totalProfit.toStringAsFixed(2),
        subtitle: 'ريال',
        icon: Icons.account_balance_wallet,
        color: _dashboardData.totalProfit >= 0 ? Colors.green : Colors.red,
      ),
      DashboardStats(
        title: 'مخزون منخفض',
        value: _dashboardData.lowStockItems.toString(),
        subtitle: 'منتج',
        icon: Icons.warning,
        color: Colors.red,
      ),
    ];
  }
}
