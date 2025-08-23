/// نماذج بيانات الفواتير
/// تحتوي على جميع النماذج المتعلقة بإدارة الفواتير
library;

/// نموذج الفاتورة
class InvoiceModel {
  final int? id;
  final int? customerId;
  final String invoiceNumber;
  final DateTime date;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<InvoiceItemModel> items;
  final String? customerName;
  final String? customerPhone;
  final String? notes;

  const InvoiceModel({
    this.id,
    this.customerId,
    required this.invoiceNumber,
    required this.date,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.customerName,
    this.customerPhone,
    this.notes,
  });

  /// إنشاء فاتورة من Map
  factory InvoiceModel.fromMap(
    Map<String, dynamic> map, {
    List<InvoiceItemModel>? items,
  }) {
    return InvoiceModel(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int?,
      invoiceNumber: map['invoice_number'] as String? ?? '',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      totalAmount: _parseDouble(map['total_amount']),
      status: map['status'] as String? ?? 'pending',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
      items: items ?? [],
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      notes: map['notes'] as String?,
    );
  }

  /// تحويل الفاتورة إلى Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      'invoice_number': invoiceNumber,
      'date': date.toIso8601String(),
      'total_amount': totalAmount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (notes != null) 'notes': notes,
    };
  }

  /// إنشاء نسخة محدثة
  InvoiceModel copyWith({
    int? id,
    int? customerId,
    String? invoiceNumber,
    DateTime? date,
    double? totalAmount,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<InvoiceItemModel>? items,
    String? customerName,
    String? customerPhone,
    String? notes,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      items: items ?? this.items,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      notes: notes ?? this.notes,
    );
  }

  /// حساب الإجمالي من العناصر
  double get calculatedTotal {
    return items.fold(0.0, (sum, item) => sum + item.total);
  }

  /// حساب إجمالي الكمية
  int get totalQuantity {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// عدد العناصر في الفاتورة
  int get itemsCount => items.length;

  /// التحقق من صحة البيانات
  bool get isValid {
    return invoiceNumber.isNotEmpty &&
        totalAmount >= 0 &&
        items.isNotEmpty &&
        items.every((item) => item.isValid);
  }

  /// التحقق من حالة الفاتورة
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isPaid => status == 'paid';

  /// تحويل الرقم إلى double
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
    return 'InvoiceModel(id: $id, invoiceNumber: $invoiceNumber, totalAmount: $totalAmount, itemsCount: ${items.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvoiceModel &&
        other.id == id &&
        other.invoiceNumber == invoiceNumber;
  }

  @override
  int get hashCode => Object.hash(id, invoiceNumber);
}

/// نموذج عنصر الفاتورة
class InvoiceItemModel {
  final int? id;
  final int? invoiceId;
  final int productId;
  final String productName;
  final String productCode;
  final int quantity;
  final double price;
  final double total;

  const InvoiceItemModel({
    this.id,
    this.invoiceId,
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.quantity,
    required this.price,
    required this.total,
  });

  /// إنشاء عنصر من Map
  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) {
    return InvoiceItemModel(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int?,
      productId: map['product_id'] as int? ?? 0,
      productName: map['product_name'] as String? ?? '',
      productCode: map['product_code'] as String? ?? '',
      quantity: map['quantity'] as int? ?? 1,
      price: _parseDouble(map['price']),
      total: _parseDouble(map['total']),
    );
  }

  /// تحويل العنصر إلى Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      'product_id': productId,
      'product_name': productName,
      'product_code': productCode,
      'quantity': quantity,
      'price': price,
      'total': total,
    };
  }

  /// إنشاء نسخة محدثة
  InvoiceItemModel copyWith({
    int? id,
    int? invoiceId,
    int? productId,
    String? productName,
    String? productCode,
    int? quantity,
    double? price,
    double? total,
  }) {
    return InvoiceItemModel(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      total: total ?? this.total,
    );
  }

  /// حساب الإجمالي المحسوب
  double get calculatedTotal {
    return price * quantity;
  }

  /// السعر للوحدة الواحدة
  double get unitPrice => price;

  /// التحقق من صحة البيانات
  bool get isValid {
    return productId > 0 &&
        productName.isNotEmpty &&
        quantity > 0 &&
        price >= 0 &&
        total >= 0;
  }

  /// تحويل الرقم إلى double
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
    return 'InvoiceItemModel(productName: $productName, quantity: $quantity, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvoiceItemModel &&
        other.productId == productId &&
        other.invoiceId == invoiceId;
  }

  @override
  int get hashCode => Object.hash(productId, invoiceId);
}

/// حالات الفاتورة
enum InvoiceStatus {
  pending,
  completed,
  cancelled,
  paid;

  @override
  String toString() {
    switch (this) {
      case InvoiceStatus.pending:
        return 'pending';
      case InvoiceStatus.completed:
        return 'completed';
      case InvoiceStatus.cancelled:
        return 'cancelled';
      case InvoiceStatus.paid:
        return 'paid';
    }
  }

  /// الحصول على النص العربي للحالة
  String get arabicName {
    switch (this) {
      case InvoiceStatus.pending:
        return 'معلقة';
      case InvoiceStatus.completed:
        return 'مكتملة';
      case InvoiceStatus.cancelled:
        return 'ملغية';
      case InvoiceStatus.paid:
        return 'مدفوعة';
    }
  }

  /// الحصول على اللون المناسب للحالة
  int get colorValue {
    switch (this) {
      case InvoiceStatus.pending:
        return 0xFFFF9800; // برتقالي
      case InvoiceStatus.completed:
        return 0xFF4CAF50; // أخضر
      case InvoiceStatus.cancelled:
        return 0xFFF44336; // أحمر
      case InvoiceStatus.paid:
        return 0xFF2196F3; // أزرق
    }
  }
}

/// أنواع التصفية للفواتير
enum InvoiceFilterType {
  all,
  pending,
  completed,
  cancelled,
  paid,
  today,
  thisWeek,
  thisMonth;

  /// الحصول على النص العربي للتصفية
  String get arabicName {
    switch (this) {
      case InvoiceFilterType.all:
        return 'الكل';
      case InvoiceFilterType.pending:
        return 'معلقة';
      case InvoiceFilterType.completed:
        return 'مكتملة';
      case InvoiceFilterType.cancelled:
        return 'ملغية';
      case InvoiceFilterType.paid:
        return 'مدفوعة';
      case InvoiceFilterType.today:
        return 'اليوم';
      case InvoiceFilterType.thisWeek:
        return 'هذا الأسبوع';
      case InvoiceFilterType.thisMonth:
        return 'هذا الشهر';
    }
  }
}
