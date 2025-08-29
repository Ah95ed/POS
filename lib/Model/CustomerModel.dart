/// نموذج العميل - Customer Model
/// يحتوي على جميع خصائص العميل وطرق التحويل
class CustomerModel {
  final int? id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final double totalDebt;
  final double totalPurchases;
  final DateTime? lastPurchaseDate;
  final bool isVip;
  final String notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CustomerModel({
    this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.totalDebt = 0.0,
    this.totalPurchases = 0.0,
    this.lastPurchaseDate,
    this.isVip = false,
    this.notes = '',
    required this.createdAt,
    this.updatedAt,
  });

  /// تحويل من Map إلى CustomerModel
  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      address: map['address'],
      totalDebt: (map['total_debt'] ?? 0).toDouble(),
      totalPurchases: (map['total_purchases'] ?? 0).toDouble(),
      lastPurchaseDate: map['last_purchase_date'] != null
          ? DateTime.parse(map['last_purchase_date'])
          : null,
      isVip: (map['is_vip'] ?? 0) == 1,
      notes: map['notes'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  /// تحويل من CustomerModel إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'total_debt': totalDebt,
      'total_purchases': totalPurchases,
      'last_purchase_date': lastPurchaseDate?.toIso8601String(),
      'is_vip': isVip ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// إنشاء نسخة جديدة مع تحديث بعض الخصائص
  CustomerModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? totalDebt,
    double? totalPurchases,
    DateTime? lastPurchaseDate,
    bool? isVip,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      totalDebt: totalDebt ?? this.totalDebt,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      isVip: isVip ?? this.isVip,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// تحويل إلى String للعرض
  @override
  String toString() {
    return 'CustomerModel(id: $id, name: $name, phone: $phone, totalDebt: $totalDebt)';
  }

  /// مقارنة العملاء
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// الحصول على الاسم المختصر للعرض
  String get displayName {
    if (name.length > 20) {
      return '${name.substring(0, 17)}...';
    }
    return name;
  }

  /// الحصول على رقم الهاتف المنسق
  String get formattedPhone {
    if (phone.startsWith('+966')) {
      return phone;
    } else if (phone.startsWith('966')) {
      return '+$phone';
    } else if (phone.startsWith('05')) {
      return '+966${phone.substring(1)}';
    }
    return phone;
  }

  /// التحقق من وجود ديون
  bool get hasDebt => totalDebt > 0;

  /// التحقق من كون العميل نشط
  bool get isActive {
    if (lastPurchaseDate == null) return false;
    final difference = DateTime.now().difference(lastPurchaseDate!);
    return difference.inDays <= 90; // نشط إذا اشترى خلال 90 يوم
  }

  /// الحصول على مستوى العميل
  CustomerLevel get level {
    if (isVip) return CustomerLevel.vip;
    if (totalPurchases >= 10000) return CustomerLevel.gold;
    if (totalPurchases >= 5000) return CustomerLevel.silver;
    return CustomerLevel.bronze;
  }

  /// الحصول على لون مستوى العميل
  String get levelColor {
    switch (level) {
      case CustomerLevel.vip:
        return '#9C27B0'; // Purple
      case CustomerLevel.gold:
        return '#FFD700'; // Gold
      case CustomerLevel.silver:
        return '#C0C0C0'; // Silver
      case CustomerLevel.bronze:
        return '#CD7F32'; // Bronze
    }
  }
}

/// مستويات العملاء
enum CustomerLevel { bronze, silver, gold, vip }

/// إحصائيات العملاء
class CustomerStats {
  final int totalCustomers;
  final int activeCustomers;
  final int vipCustomers;
  final double totalDebt;
  final double totalSales;
  final CustomerModel? topCustomer;

  const CustomerStats({
    required this.totalCustomers,
    required this.activeCustomers,
    required this.vipCustomers,
    required this.totalDebt,
    required this.totalSales,
    this.topCustomer,
  });

  factory CustomerStats.fromMap(Map<String, dynamic> map) {
    return CustomerStats(
      totalCustomers: map['total_customers']?.toInt() ?? 0,
      activeCustomers: map['active_customers']?.toInt() ?? 0,
      vipCustomers: map['vip_customers']?.toInt() ?? 0,
      totalDebt: (map['total_debt'] ?? 0).toDouble(),
      totalSales: (map['total_sales'] ?? 0).toDouble(),
      topCustomer: map['top_customer'] != null
          ? CustomerModel.fromMap(map['top_customer'])
          : null,
    );
  }
}
