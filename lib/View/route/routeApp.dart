import 'package:flutter/material.dart';
import 'package:pos/View/Screens/DashboardScreen.dart';

class RouteApp {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgotPassword';
  static const String resetPassword = '/resetPassword';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const dashboardScreen = '/DashboardScreen';
  static const productsScreen = '/ProductsScreen';
  static const customersScreen = '/CustomersScreen';
  static const ordersScreen = '/OrdersScreen';
  static const reportsScreen = '/ReportsScreen';

  static final Map<String, Widget Function(BuildContext)> routes =
      <String, WidgetBuilder>{
        dashboardScreen: (context) => const DashboardScreen(),
      };
}
