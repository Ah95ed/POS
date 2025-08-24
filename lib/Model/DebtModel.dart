/// نموذج الديون
class DebtModel {
  final int? id;
  final int partyId; // معرف العميل أو المورد
  final String partyType; // customer أو supplier
  final String partyName; // اسم العميل أو المورد
  final String? partyPhone; // رقم هاتف العميل أو المورد
  final double amount; // المبلغ الكلي بالدينار العراقي
  final double paidAmount; // المبلغ المدفوع
  final double remainingAmount; // المبلغ المتبقي
  final DateTime dueDate; // تاريخ الاستحقاق
  final String status; // unpaid, partiallyPaid, paid
  final bool archived; // مؤرشف أو لا
  final String? notes; // ملاحظات
  final DateTime createdAt;
  final DateTime updatedAt;

  const DebtModel({
    this.id,
    required this.partyId,
    required this.partyType,
    required this.partyName,
    this.partyPhone,
    required this.amount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.dueDate,
    required this.status,
    required this.archived,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// إنشاء دين من Map
  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id'] as int?,
      partyId: map['party_id'] as int,
      partyType: map['party_type'] as String,
      partyName: map['party_name'] as String,
      partyPhone: map['party_phone'] as String?,
      amount: _parseDouble(map['amount']),
      paidAmount: _parseDouble(map['paid_amount']),
      remainingAmount: _parseDouble(map['remaining_amount']),
      dueDate:
          DateTime.tryParse(map['due_date'] as String? ?? '') ?? DateTime.now(),
      status: map['status'] as String? ?? 'unpaid',
      archived: (map['archived'] as int? ?? 0) == 1,
      notes: map['notes'] as String?,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// تحويل الدين إلى Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'party_id': partyId,
      'party_type': partyType,
      'party_name': partyName,
      if (partyPhone != null) 'party_phone': partyPhone,
      'amount': amount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'archived': archived ? 1 : 0,
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// إنشاء نسخة محدثة
  DebtModel copyWith({
    int? id,
    int? partyId,
    String? partyType,
    String? partyName,
    String? partyPhone,
    double? amount,
    double? paidAmount,
    double? remainingAmount,
    DateTime? dueDate,
    String? status,
    bool? archived,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DebtModel(
      id: id ?? this.id,
      partyId: partyId ?? this.partyId,
      partyType: partyType ?? this.partyType,
      partyName: partyName ?? this.partyName,
      partyPhone: partyPhone ?? this.partyPhone,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      archived: archived ?? this.archived,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// التحقق من صحة البيانات
  bool get isValid =>
      partyName.isNotEmpty &&
      amount > 0 &&
      partyType.isNotEmpty &&
      ['customer', 'supplier'].contains(partyType) &&
      ['unpaid', 'partiallyPaid', 'paid'].contains(status);

  /// تحديث حالة الدين بناءً على المبلغ المدفوع
  String get calculatedStatus {
    if (paidAmount <= 0) return 'unpaid';
    if (paidAmount >= amount) return 'paid';
    return 'partiallyPaid';
  }

  /// التحقق من انتهاء تاريخ الاستحقاق
  bool get isOverdue => DateTime.now().isAfter(dueDate) && status != 'paid';

  /// تنسيق المبلغ بالدينار العراقي
  String get formattedAmount => '${amount.toStringAsFixed(0)} د.ع';
  String get formattedPaidAmount => '${paidAmount.toStringAsFixed(0)} د.ع';
  String get formattedRemainingAmount =>
      '${remainingAmount.toStringAsFixed(0)} د.ع';

  /// تنسيق تاريخ الاستحقاق
  String get formattedDueDate =>
      '${dueDate.day}/${dueDate.month}/${dueDate.year}';

  /// نص حالة الدين بالعربية
  String get statusText {
    switch (status) {
      case 'paid':
        return 'مدفوع';
      case 'partiallyPaid':
        return 'مدفوع جزئياً';
      case 'unpaid':
      default:
        return 'غير مدفوع';
    }
  }

  /// نص نوع الطرف بالعربية
  String get partyTypeText {
    switch (partyType) {
      case 'supplier':
        return 'مورد';
      case 'customer':
      default:
        return 'عميل';
    }
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
    return 'DebtModel(id: $id, partyName: $partyName, amount: $amount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DebtModel &&
        other.id == id &&
        other.partyId == partyId &&
        other.partyType == partyType &&
        other.amount == amount &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(id, partyId, partyType, amount, status);
  }
}

/// نموذج معاملة الدين (الدفعات)
class DebtTransactionModel {
  final int? id;
  final int debtId;
  final double amountPaid;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  const DebtTransactionModel({
    this.id,
    required this.debtId,
    required this.amountPaid,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  /// إنشاء معاملة من Map
  factory DebtTransactionModel.fromMap(Map<String, dynamic> map) {
    return DebtTransactionModel(
      id: map['id'] as int?,
      debtId: map['debt_id'] as int,
      amountPaid: _parseDouble(map['amount_paid']),
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      notes: map['notes'] as String?,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// تحويل المعاملة إلى Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'debt_id': debtId,
      'amount_paid': amountPaid,
      'date': date.toIso8601String(),
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// إنشاء نسخة محدثة
  DebtTransactionModel copyWith({
    int? id,
    int? debtId,
    double? amountPaid,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
  }) {
    return DebtTransactionModel(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      amountPaid: amountPaid ?? this.amountPaid,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// التحقق من صحة البيانات
  bool get isValid => amountPaid > 0;

  /// تنسيق المبلغ بالدينار العراقي
  String get formattedAmount => '${amountPaid.toStringAsFixed(0)} د.ع';

  /// تنسيق التاريخ
  String get formattedDate => '${date.day}/${date.month}/${date.year}';

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
    return 'DebtTransactionModel(id: $id, debtId: $debtId, amountPaid: $amountPaid)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DebtTransactionModel &&
        other.id == id &&
        other.debtId == debtId &&
        other.amountPaid == amountPaid &&
        other.date == date;
  }

  @override
  int get hashCode {
    return Object.hash(id, debtId, amountPaid, date);
  }
}
