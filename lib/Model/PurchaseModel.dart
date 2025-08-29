import 'package:pos/Helper/DataBase/POSDatabase.dart';
import 'package:pos/Model/SupplierModel.dart';

/// نموذج المشتريات - Purchase Model
/// يمثل فاتورة شراء كاملة مع العناصر
class PurchaseModel {
  final int? id;
  final int? supplierId;
  final String invoiceNumber;
  final DateTime date;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final PurchaseStatus status;
  final String? notes;
  final DateTime createdAt;
  final List<PurchaseItemModel> items;
  final SupplierModel? supplier;

  const PurchaseModel({
    this.id,
    this.supplierId,
    required this.invoiceNumber,
    required this.date,
    required this.subtotal,
    this.tax = 0.0,
    this.discount = 0.0,
    required this.total,
    this.status = PurchaseStatus.pending,
    this.notes,
    required this.createdAt,
    this.items = const [],
    this.supplier,
  });

  /// التحقق من صحة البيانات
  bool get isValid {
    return invoiceNumber.trim().isNotEmpty &&
           total >= 0 &&
           subtotal >= 0 &&
           items.isNotEmpty &&
           items.every((item) => item.isValid);
  }

  /// عدد الأصناف في الفاتورة
  int get itemsCount => items.length;

  /// إجمالي الكمية المشتراة
  int get totalQuantity {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// حساب الإجمالي النهائي
  double get calculatedTotal {
    return subtotal + tax - discount;
  }

  /// التحقق من تطابق الحسابات
  bool get isCalculationValid {
    return (calculatedTotal - total).abs() < 0.01;
  }

  /// حالة الفاتورة بالعربية
  String get statusInArabic {
    switch (status) {
      case PurchaseStatus.pending:
        return 'معلقة';
      case PurchaseStatus.completed:
        return 'مكتملة';
      case PurchaseStatus.cancelled:
        return 'ملغية';
      case PurchaseStatus.returned:
        return 'مرتجعة';
    }
  }

  /// لون حالة الفاتورة
  String get statusColor {
    switch (status) {
      case PurchaseStatus.pending:
        return '#FF9800';
      case PurchaseStatus.completed:
        return '#4CAF50';
      case PurchaseStatus.cancelled:
        return '#F44336';
      case PurchaseStatus.returned:
        return '#9C27B0';
    }
  }

  /// نسخ المشتريات مع تعديل بعض الخصائص
  PurchaseModel copyWith({
    int? id,
    int? supplierId,
    String? invoiceNumber,
    DateTime? date,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    PurchaseStatus? status,
    String? notes,
    DateTime? createdAt,
    List<PurchaseItemModel>? items,
    SupplierModel? supplier,
  }) {
    return PurchaseModel(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      supplier: supplier ?? this.supplier,
    );
  }

  /// تحويل إلى Map لقاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      POSDatabase.purchaseId: id,
      POSDatabase.purchaseSupplierId: supplierId,
      POSDatabase.purchaseInvoiceNumber: invoiceNumber,
      POSDatabase.purchaseDate: date.toIso8601String(),
      POSDatabase.purchaseSubtotal: subtotal,
      POSDatabase.purchaseTax: tax,
      POSDatabase.purchaseDiscount: discount,
      POSDatabase.purchaseTotal: total,
      POSDatabase.purchaseStatus: status.toString().split('.').last,
      POSDatabase.purchaseNotes: notes,
      POSDatabase.purchaseCreatedAt: createdAt.toIso8601String(),
    };
  }

  /// إنشاء من Map من قاعدة البيانات
  factory PurchaseModel.fromMap(Map<String, dynamic> map) {
    return PurchaseModel(
      id: map[POSDatabase.purchaseId],
      supplierId: map[POSDatabase.purchaseSupplierId],
      invoiceNumber: map[POSDatabase.purchaseInvoiceNumber] ?? '',
      date: DateTime.parse(
        map[POSDatabase.purchaseDate] ?? DateTime.now().toIso8601String(),
      ),
      subtotal: map[POSDatabase.purchaseSubtotal]?.toDouble() ?? 0.0,
      tax: map[POSDatabase.purchaseTax]?.toDouble() ?? 0.0,
      discount: map[POSDatabase.purchaseDiscount]?.toDouble() ?? 0.0,
      total: map[POSDatabase.purchaseTotal]?.toDouble() ?? 0.0,
      status: PurchaseStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map[POSDatabase.purchaseStatus],
        orElse: () => PurchaseStatus.pending,
      ),
      notes: map[POSDatabase.purchaseNotes],
      createdAt: DateTime.parse(
        map[POSDatabase.purchaseCreatedAt] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  String toString() {
    return 'PurchaseModel{id: $id, invoiceNumber: $invoiceNumber, total: $total}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PurchaseModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// نموذج عنصر المشتريات - Purchase Item Model
class PurchaseItemModel {
  final int? id;
  final int purchaseId;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double total;

  const PurchaseItemModel({
    this.id,
    required this.purchaseId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  /// التحقق من صحة البيانات
  bool get isValid {
    return productName.trim().isNotEmpty &&
           quantity > 0 &&
           unitPrice >= 0 &&
           total >= 0;
  }

  /// حساب الإجمالي المتوقع
  double get calculatedTotal => quantity * unitPrice;

  /// التحقق من تطابق الحسابات
  bool get isCalculationValid {
    return (calculatedTotal - total).abs() < 0.01;
  }

  /// نسخ العنصر مع تعديل بعض الخصائص
  PurchaseItemModel copyWith({
    int? id,
    int? purchaseId,
    int? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? total,
  }) {
    return PurchaseItemModel(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
    );
  }

  /// تحويل إلى Map لقاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      POSDatabase.purchaseItemId: id,
      POSDatabase.purchaseItemPurchaseId: purchaseId,
      POSDatabase.purchaseItemProductId: productId,
      POSDatabase.purchaseItemProductName: productName,
      POSDatabase.purchaseItemQuantity: quantity,
      POSDatabase.purchaseItemUnitPrice: unitPrice,
      POSDatabase.purchaseItemTotal: total,
    };
  }

  /// إنشاء من Map من قاعدة البيانات
  factory PurchaseItemModel.fromMap(Map<String, dynamic> map) {
    return PurchaseItemModel(
      id: map[POSDatabase.purchaseItemId],
      purchaseId: map[POSDatabase.purchaseItemPurchaseId] ?? 0,
      productId: map[POSDatabase.purchaseItemProductId] ?? 0,
      productName: map[POSDatabase.purchaseItemProductName] ?? '',
      quantity: map[POSDatabase.purchaseItemQuantity] ?? 0,
      unitPrice: map[POSDatabase.purchaseItemUnitPrice]?.toDouble() ?? 0.0,
      total: map[POSDatabase.purchaseItemTotal]?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return 'PurchaseItemModel{productName: $productName, quantity: $quantity, total: $total}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PurchaseItemModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// حالات المشتريات
enum PurchaseStatus {
  pending,   // معلقة
  completed, // مكتملة
  cancelled, // ملغية
  returned,  // مرتجعة
}

/// إحصائيات المشتريات
class PurchaseStats {
  final int totalPurchases;
  final double totalAmount;
  final double averageAmount;
  final int pendingPurchases;
  final int completedPurchases;

  const PurchaseStats({
    required this.totalPurchases,
    required this.totalAmount,
    required this.averageAmount,
    required this.pendingPurchases,
    required this.completedPurchases,
  });

  /// نسبة المشتريات المكتملة
  double get completionRate {
    if (totalPurchases == 0) return 0.0;
    return (completedPurchases / totalPurchases) * 100;
  }

  /// نسبة المشتريات المعلقة
  double get pendingRate {
    if (totalPurchases == 0) return 0.0;
    return (pendingPurchases / totalPurchases) * 100;
  }
}
