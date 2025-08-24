/// ثوابت التطبيق
class AppConstants {
  // إعدادات العملة
  static const String currencyName = 'د.ع';
  static const String currencySymbol = 'د.ع';
  static const String currencyCode = 'IQD';

  // تنسيق العملة
  static String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)} $currencyName';
  }

  static String formatCurrencyWithSymbol(double amount) {
    return '${amount.toStringAsFixed(0)} $currencySymbol';
  }

  // إعدادات أخرى
  static const int decimalPlaces = 0; // الدينار العراقي لا يستخدم خانات عشرية
  static const String appName = 'نظام نقاط البيع';
  static const String appVersion = '1.0.0';

  // إعدادات قاعدة البيانات
  static const String databaseName = 'pos_database.db';
  static const int databaseVersion = 1;

  // إعدادات الطباعة
  static const String receiptHeader = 'فاتورة مبيعات';
  static const String receiptFooter = 'شكراً لتسوقكم معنا';

  // إعدادات التنبيهات
  static const int lowStockThreshold = 10;
  static const int criticalStockThreshold = 5;

  // إعدادات الصفحات
  static const int itemsPerPage = 20;
  static const int maxSearchResults = 100;
}
