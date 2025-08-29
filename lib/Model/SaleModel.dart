/// نماذج بيانات نقطة البيع
/// تحتوي على جميع النماذج المتعلقة بعمليات البيع
library;

import 'package:pos/Helper/Result.dart';

/// نموذج الفاتورة
class Sale {
  final int? id;
  final String invoiceNumber;
  final DateTime date;
  final List<SaleItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;
  final double paidAmount;
  final double changeAmount;
  final String? customerName;
  final String? customerPhone;
  final String? notes;
  final String status;

  const Sale({
    this.id,
    required this.invoiceNumber,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.paidAmount,
    required this.changeAmount,
    this.customerName,
    this.customerPhone,
    this.notes,
    this.status = 'completed',
  });

  /// إنشاء فاتورة من Map
  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as String? ?? '',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      items: [], // سيتم تحميلها منفصلة
      subtotal: _parseDouble(map['subtotal']),
      discount: _parseDouble(map['discount']),
      tax: _parseDouble(map['tax']),
      total: _parseDouble(map['total']),
      paymentMethod: map['payment_method'] as String? ?? 'نقدي',
      paidAmount: _parseDouble(map['paid_amount']),
      changeAmount: _parseDouble(map['change_amount']),
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'completed',
    );
  }

  /// تحويل الفاتورة إلى Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'invoice_number': invoiceNumber,
      'date': date.toIso8601String(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'payment_method': paymentMethod,
      'paid_amount': paidAmount,
      'change_amount': changeAmount,
      if (customerName != null) 'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
      if (notes != null) 'notes': notes,
      'status': status,
    };
  }

  /// إنشاء نسخة محدثة
  Sale copyWith({
    int? id,
    String? invoiceNumber,
    DateTime? date,
    List<SaleItem>? items,
    double? subtotal,
    double? discount,
    double? tax,
    double? total,
    String? paymentMethod,
    double? paidAmount,
    double? changeAmount,
    String? customerName,
    String? customerPhone,
    String? notes,
    String? status,
  }) {
    return Sale(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAmount: paidAmount ?? this.paidAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  /// التحقق من صحة البيانات
  bool get isValid {
    return invoiceNumber.isNotEmpty &&
        items.isNotEmpty &&
        subtotal >= 0 &&
        tax >= 0 &&
        discount >= 0 &&
        total >= 0 &&
        paidAmount >= 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}

/// نموذج عنصر الفاتورة
class SaleItem {
  final int? id;
  final int? saleId;
  final int productId;
  final String productCode;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double discount;
  final double total;

  const SaleItem({
    this.id,
    this.saleId,
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.discount = 0.0,
    required this.total,
  });

  /// إنشاء عنصر من Map
  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int?,
      productId: map['product_id'] as int? ?? 0,
      productCode: map['product_code'] as String? ?? '',
      productName: map['product_name'] as String? ?? '',
      unitPrice: _parseDouble(map['unit_price']),
      quantity: map['quantity'] as int? ?? 1,
      discount: _parseDouble(map['discount']),
      total: _parseDouble(map['total']),
    );
  }

  /// تحويل العنصر إلى Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      'product_code': productCode,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'discount': discount,
      'total': total,
    };
  }

  /// إنشاء نسخة محدثة
  SaleItem copyWith({
    int? id,
    int? saleId,
    String? productCode,
    String? productName,
    double? unitPrice,
    int? quantity,
    double? discount,
    double? total,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
      total: total ?? this.total,
    );
  }

  /// حساب الإجمالي
  double calculateTotal() {
    return (unitPrice * quantity) - discount;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}

/// حالات الفاتورة
enum SaleStatus {
  pending,
  completed,
  cancelled,
  refunded;

  @override
  String toString() {
    switch (this) {
      case SaleStatus.pending:
        return 'pending';
      case SaleStatus.completed:
        return 'completed';
      case SaleStatus.cancelled:
        return 'cancelled';
      case SaleStatus.refunded:
        return 'refunded';
    }
  }
}

/// نموذج المبيعة الرئيسية
class SaleModel {
  final int? id;
  final String invoiceNumber;
  final int? customerId;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final double paidAmount;
  final double changeAmount;
  final String paymentMethod;
  final String status;
  final String? notes;
  final int? cashierId;
  final DateTime createdAt;
  final List<SaleItemModel> items;

  const SaleModel({
    this.id,
    required this.invoiceNumber,
    this.customerId,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    required this.paidAmount,
    required this.changeAmount,
    required this.paymentMethod,
    required this.status,
    this.notes,
    this.cashierId,
    required this.createdAt,
    required this.items,
  });

  /// إنشاء مبيعة من Map
  factory SaleModel.fromMap(
    Map<String, dynamic> map, {
    List<SaleItemModel>? items,
  }) {
    return SaleModel(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as String? ?? '',
      customerId: map['customer_id'] as int?,
      subtotal: _parseDouble(map['subtotal']),
      tax: _parseDouble(map['tax']),
      discount: _parseDouble(map['discount']),
      total: _parseDouble(map['total']),
      paidAmount: _parseDouble(map['paid_amount']),
      changeAmount: _parseDouble(map['change_amount']),
      paymentMethod: map['payment_method'] as String? ?? 'cash',
      status: map['status'] as String? ?? 'completed',
      notes: map['notes'] as String?,
      cashierId: map['cashier_id'] as int?,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      items: items ?? [],
    );
  }

  /// تحويل المبيعة إلى Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'invoice_number': invoiceNumber,
      if (customerId != null) 'customer_id': customerId,
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'paid_amount': paidAmount,
      'change_amount': changeAmount,
      'payment_method': paymentMethod,
      'status': status,
      if (notes != null) 'notes': notes,
      if (cashierId != null) 'cashier_id': cashierId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// إنشاء نسخة محدثة
  SaleModel copyWith({
    int? id,
    String? invoiceNumber,
    int? customerId,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    double? paidAmount,
    double? changeAmount,
    String? paymentMethod,
    String? status,
    String? notes,
    int? cashierId,
    DateTime? createdAt,
    List<SaleItemModel>? items,
  }) {
    return SaleModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paidAmount: paidAmount ?? this.paidAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      cashierId: cashierId ?? this.cashierId,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  /// حساب الإجمالي الفرعي من العناصر
  double get calculatedSubtotal {
    return items.fold(0.0, (sum, item) => sum + item.total);
  }

  /// حساب إجمالي الكمية
  int get totalQuantity {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// التحقق من اكتمال الدفع
  bool get isFullyPaid => paidAmount >= total;

  /// المبلغ المتبقي للدفع
  double get remainingAmount => total - paidAmount;

  /// التحقق من صحة البيانات
  bool get isValid {
    return invoiceNumber.isNotEmpty &&
        subtotal >= 0 &&
        tax >= 0 &&
        discount >= 0 &&
        total >= 0 &&
        paidAmount >= 0 &&
        items.isNotEmpty;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  @override
  String toString() {
    return 'SaleModel(id: $id, invoiceNumber: $invoiceNumber, total: $total, items: ${items.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SaleModel &&
        other.id == id &&
        other.invoiceNumber == invoiceNumber;
  }

  @override
  int get hashCode => Object.hash(id, invoiceNumber);
}

/// نموذج عنصر المبيعة
class SaleItemModel {
  final int? id;
  final int? saleId;
  final int productId;
  final String productName;
  final String productCode;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double total;

  const SaleItemModel({
    this.id,
    this.saleId,
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.total,
  });

  /// إنشاء عنصر من Map
  factory SaleItemModel.fromMap(Map<String, dynamic> map) {
    return SaleItemModel(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int?,
      productId: map['product_id'] as int? ?? 0,
      productName: map['product_name'] as String? ?? '',
      productCode: map['product_code'] as String? ?? '',
      quantity: map['quantity'] as int? ?? 1,
      unitPrice: _parseDouble(map['unit_price']),
      discount: _parseDouble(map['discount']),
      total: _parseDouble(map['total']),
    );
  }

  /// تحويل العنصر إلى Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'product_code': productCode,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'total': total,
    };
  }

  /// إنشاء نسخة محدثة
  SaleItemModel copyWith({
    int? id,
    int? saleId,
    int? productId,
    String? productName,
    String? productCode,
    int? quantity,
    double? unitPrice,
    double? discount,
    double? total,
  }) {
    return SaleItemModel(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      total: total ?? this.total,
    );
  }

  /// حساب الإجمالي المحسوب
  double get calculatedTotal {
    final subtotal = unitPrice * quantity;
    return subtotal - discount;
  }

  /// حساب نسبة الخصم
  double get discountPercentage {
    if (unitPrice == 0) return 0;
    return (discount / (unitPrice * quantity)) * 100;
  }

  /// السعر بعد الخصم للوحدة
  double get discountedUnitPrice {
    if (quantity == 0) return unitPrice;
    return (calculatedTotal / quantity);
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  @override
  String toString() {
    return 'SaleItemModel(productName: $productName, quantity: $quantity, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SaleItemModel &&
        other.productId == productId &&
        other.saleId == saleId;
  }

  @override
  int get hashCode => Object.hash(productId, saleId);
}

/// نموذج طريقة الدفع
class PaymentMethodModel {
  final int? id;
  final String name;
  final String nameAr;
  final bool isActive;
  final String? icon;

  const PaymentMethodModel({
    this.id,
    required this.name,
    required this.nameAr,
    required this.isActive,
    this.icon,
  });

  /// إنشاء طريقة دفع من Map
  factory PaymentMethodModel.fromMap(Map<String, dynamic> map) {
    return PaymentMethodModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      nameAr: map['name_ar'] as String? ?? '',
      isActive: (map['is_active'] as int? ?? 1) == 1,
      icon: map['icon'] as String?,
    );
  }

  /// تحويل طريقة الدفع إلى Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'name_ar': nameAr,
      'is_active': isActive ? 1 : 0,
      if (icon != null) 'icon': icon,
    };
  }

  @override
  String toString() {
    return 'PaymentMethodModel(id: $id, nameAr: $nameAr, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentMethodModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// نموذج إحصائيات المبيعات
class SalesStats {
  final int totalSales;
  final double totalRevenue;
  final double totalProfit;
  final int totalItems;
  final double averageSaleAmount;
  final DateTime periodStart;
  final DateTime periodEnd;

  const SalesStats({
    required this.totalSales,
    required this.totalRevenue,
    required this.totalProfit,
    required this.totalItems,
    required this.averageSaleAmount,
    required this.periodStart,
    required this.periodEnd,
  });

  /// إنشاء إحصائيات من قائمة المبيعات
  factory SalesStats.fromSales(
    List<SaleModel> sales, {
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    final now = DateTime.now();
    final start = periodStart ?? DateTime(now.year, now.month, now.day);
    final end = periodEnd ?? now;

    double totalRevenue = 0.0;
    int totalItems = 0;

    for (final sale in sales) {
      totalRevenue += sale.total;
      totalItems += sale.totalQuantity;
    }

    return SalesStats(
      totalSales: sales.length,
      totalRevenue: totalRevenue,
      totalProfit: 0.0, // يحتاج حساب من تكلفة المنتجات
      totalItems: totalItems,
      averageSaleAmount: sales.isEmpty ? 0.0 : totalRevenue / sales.length,
      periodStart: start,
      periodEnd: end,
    );
  }
}

/// أنواع العملاء للتصفية
enum CustomerType { all, vip, regular, withPurchases, withoutPurchases }

/// امتداد لـ CustomerType لإضافة وظائف مساعدة
extension CustomerTypeExtension on CustomerType {
  String get label {
    switch (this) {
      case CustomerType.all:
        return 'الكل';
      case CustomerType.vip:
        return 'مميز';
      case CustomerType.regular:
        return 'عادي';
      case CustomerType.withPurchases:
        return 'لديه مشتريات';
      case CustomerType.withoutPurchases:
        return 'بدون مشتريات';
    }
  }
}
