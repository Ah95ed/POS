import 'package:pos/Model/SaleModel.dart';

/// خدمة الإرجاع - Refund Service
/// تتعامل مع عمليات إرجاع المنتجات والفواتير
class RefundService {
  /// البحث عن فاتورة للإرجاع
  Future<RefundSearchResult> searchInvoiceForRefund(
    String invoiceNumber,
  ) async {
    try {
      // محاكاة البحث في قاعدة البيانات
      await Future.delayed(const Duration(milliseconds: 500));

      // في التطبيق الحقيقي، ستبحث في قاعدة البيانات
      // هنا نعيد نتيجة وهمية للاختبار

      if (invoiceNumber.isEmpty) {
        return RefundSearchResult(
          found: false,
          message: 'يرجى إدخال رقم الفاتورة',
        );
      }

      // محاكاة فاتورة موجودة
      final sale = Sale(
        id: 1,
        invoiceNumber: invoiceNumber,
        date: DateTime.now().subtract(const Duration(days: 1)),
        items: [],
        subtotal: 100.0,
        discount: 0.0,
        tax: 15.0,
        total: 115.0,
        paymentMethod: 'نقدي',
        paidAmount: 115.0,
        changeAmount: 0.0,
        status: 'completed',
      );

      return RefundSearchResult(
        found: true,
        canRefund: true,
        sale: sale,
        message: 'تم العثور على الفاتورة',
      );
    } catch (e) {
      return RefundSearchResult(
        found: false,
        message: 'خطأ في البحث: ${e.toString()}',
      );
    }
  }

  /// إرجاع فاتورة كاملة
  Future<RefundResult> refundFullInvoice(
    String invoiceNumber,
    String reason,
  ) async {
    try {
      // محاكاة عملية الإرجاع
      await Future.delayed(const Duration(seconds: 1));

      // إنشاء فاتورة إرجاع جديدة
      final refundSale = Sale(
        id: 2,
        invoiceNumber: 'REF-$invoiceNumber',
        date: DateTime.now(),
        items: [],
        subtotal: -100.0,
        discount: 0.0,
        tax: -15.0,
        total: -115.0,
        paymentMethod: 'إرجاع نقدي',
        paidAmount: -115.0,
        changeAmount: 0.0,
        notes: 'إرجاع كامل - السبب: $reason',
        status: 'refunded',
      );

      return RefundResult(
        isSuccess: true,
        message: 'تم إرجاع الفاتورة بنجاح',
        refundSale: refundSale,
      );
    } catch (e) {
      return RefundResult(
        isSuccess: false,
        message: 'خطأ في الإرجاع: ${e.toString()}',
      );
    }
  }
}

/// نتيجة البحث عن فاتورة للإرجاع
class RefundSearchResult {
  final bool found;
  final bool canRefund;
  final Sale? sale;
  final String message;

  RefundSearchResult({
    required this.found,
    this.canRefund = false,
    this.sale,
    required this.message,
  });
}

/// نتيجة عملية الإرجاع
class RefundResult {
  final bool isSuccess;
  final String message;
  final Sale? refundSale;

  RefundResult({
    required this.isSuccess,
    required this.message,
    this.refundSale,
  });
}

/// أسباب الإرجاع الشائعة
class RefundReasons {
  static const String defective = 'منتج معيب';
  static const String wrongItem = 'منتج خاطئ';
  static const String customerRequest = 'طلب العميل';
  static const String qualityIssue = 'مشكلة في الجودة';
  static const String other = 'أخرى';

  static List<String> get all => [
    defective,
    wrongItem,
    customerRequest,
    qualityIssue,
    other,
  ];
}
