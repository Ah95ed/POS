/// كلاس للتعامل مع نتائج العمليات
/// يستخدم في جميع أنحاء التطبيق لإرجاع النتائج مع معالجة الأخطاء
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const Result._({this.data, this.error, required this.isSuccess});

  /// إنشاء نتيجة ناجحة
  factory Result.success(T data) {
    return Result._(data: data, isSuccess: true);
  }

  /// إنشاء نتيجة فاشلة مع رسالة خطأ
  factory Result.error(String error) {
    return Result._(error: error, isSuccess: false);
  }

  /// التحقق من وجود خطأ
  bool get isError => !isSuccess;

  /// الحصول على البيانات أو قيمة افتراضية
  T? get dataOrNull => isSuccess ? data : null;

  /// الحصول على رسالة الخطأ أو قيمة افتراضية
  String get errorMessage => error ?? 'خطأ غير معروف';
}

/// Extension لتسهيل العمل مع القوائم
extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
}

/// Extension لتسهيل العمل مع النصوص
extension StringExtension on String {
  bool get isNotNullOrEmpty => isNotEmpty;
  bool get isNullOrEmpty => isEmpty;
}
