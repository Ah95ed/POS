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

  // تنسيق التاريخ والوقت
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // تنسيق الأرقام
  static String formatNumber(double number) {
    return number.toStringAsFixed(0);
  }

  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  // إعدادات أخرى
  static const int decimalPlaces = 0; // الدينار العراقي لا يستخدم خانات عشرية
  static const String appName = 'نظام نقاط البيع';
  static const String appVersion = '1.0.0';

  // إعدادات قاعدة البيانات
  static const String databaseName = 'pos_database.db';
  static const int databaseVersion = 7;

  // إعدادات الطباعة
  static const String receiptHeader = 'فاتورة مبيعات';
  static const String receiptFooter = 'شكراً لتسوقكم معنا';

  // إعدادات التنبيهات
  static const int lowStockThreshold = 10;
  static const int criticalStockThreshold = 5;

  // إعدادات الصفحات
  static const int itemsPerPage = 20;
  static const int maxSearchResults = 100;

  // طرق الدفع
  static const List<String> paymentMethods = [
    'نقدي',
    'بطاقة ائتمان',
    'بطاقة مدى',
    'تحويل بنكي',
    'محفظة إلكترونية',
    'شيك',
    'آجل',
  ];

  // حالات الفواتير
  static const List<String> invoiceStatuses = [
    'completed',
    'pending',
    'cancelled',
    'refunded',
  ];

  // الحد الأقصى للخصم
  static const double maxDiscountPercentage = 50.0;
  static const double maxDiscountAmount = 1000.0;

  // رسائل التحقق
  static const String requiredFieldMessage = 'هذا الحقل مطلوب';
  static const String saveSuccessMessage = 'تم الحفظ بنجاح';
  static const String saveErrorMessage = 'خطأ في الحفظ';
}
