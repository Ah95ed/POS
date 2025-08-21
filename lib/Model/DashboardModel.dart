import 'package:flutter/material.dart';

class DashboardModel {
  final int totalItems;
  final double totalSalesValue;
  final double totalPurchaseValue;
  final double totalProfit;
  final int lowStockItems;
  final List<TopSellingItem> topSellingItems;
  final List<RecentTransaction> recentTransactions;

  DashboardModel({
    required this.totalItems,
    required this.totalSalesValue,
    required this.totalPurchaseValue,
    required this.totalProfit,
    required this.lowStockItems,
    required this.topSellingItems,
    required this.recentTransactions,
  });

  factory DashboardModel.empty() {
    return DashboardModel(
      totalItems: 0,
      totalSalesValue: 0.0,
      totalPurchaseValue: 0.0,
      totalProfit: 0.0,
      lowStockItems: 0,
      topSellingItems: [],
      recentTransactions: [],
    );
  }
}

class TopSellingItem {
  final String id;
  final String name;
  final String code;
  final int quantitySold;
  final double revenue;

  TopSellingItem({
    required this.id,
    required this.name,
    required this.code,
    required this.quantitySold,
    required this.revenue,
  });

  factory TopSellingItem.fromMap(Map<String, dynamic> map) {
    return TopSellingItem(
      id: map['ID'].toString(),
      name: map['Name'] ?? '',
      code: map['Code'] ?? '',
      quantitySold: int.tryParse(map['Quantity'].toString()) ?? 0,
      revenue:
          double.tryParse(
            map['Sale'].toString().replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0.0,
    );
  }
}

class RecentTransaction {
  final String id;
  final String itemName;
  final String itemCode;
  final String type; // 'sale' or 'purchase'
  final double amount;
  final String date;
  final String time;

  RecentTransaction({
    required this.id,
    required this.itemName,
    required this.itemCode,
    required this.type,
    required this.amount,
    required this.date,
    required this.time,
  });

  factory RecentTransaction.fromMap(
    Map<String, dynamic> map,
    String transactionType,
  ) {
    return RecentTransaction(
      id: map['ID'].toString(),
      itemName: map['Name'] ?? '',
      itemCode: map['Code'] ?? '',
      type: transactionType,
      amount:
          double.tryParse(
            map[transactionType == 'sale' ? 'Sale' : 'Buy']
                .toString()
                .replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0.0,
      date: map['Date'] ?? '',
      time: map['Time'] ?? '',
    );
  }
}

class DashboardStats {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  DashboardStats({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
