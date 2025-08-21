import 'package:flutter/material.dart';
import 'package:pos/View/Screens/DashboardScreen.dart';
import 'package:pos/View/Screens/ProductsScreen.dart';
import 'package:pos/View/Screens/ReportsScreen.dart';

class RouteApp {
  static const home = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgotPassword';
  static const resetPassword = '/resetPassword';
  static const dashboard = '/dashboard';
  static const profile = '/profile';
  static const settings = '/settings';
  static const dashboardScreen = '/DashboardScreen';
  static const productsScreen = '/ProductsScreen';
  static const customersScreen = '/CustomersScreen';
  static const ordersScreen = '/OrdersScreen';
  static const reportsScreen = '/ReportsScreen';

  static final Map<String, Widget Function(BuildContext)> routes =
      <String, WidgetBuilder>{
        dashboardScreen: (context) => const DashboardScreen(),
        productsScreen: (context) => const ProductsScreen(),

        reportsScreen: (context) => const ReportsScreen()
      };
}
