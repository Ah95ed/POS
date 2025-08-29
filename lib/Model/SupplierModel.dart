import 'package:pos/Helper/DataBase/POSDatabase.dart';

/// نموذج المورد - Supplier Model
/// يمثل بيانات الموردين في النظام
class SupplierModel {
  final int? id;
  final String name;
  final String? company;
  final String? phone;
  final String? email;
  final String? address;
  final double totalPurchases;
  final bool isActive;
  final DateTime createdAt;

  const SupplierModel({
    this.id,
    required this.name,
    this.company,
    this.phone,
    this.email,
    this.address,
    this.totalPurchases = 0.0,
    this.isActive = true,
    required this.createdAt,
  });

  /// التحقق من صحة البيانات
  bool get isValid {
    return name.trim().isNotEmpty &&
           (email == null || email!.trim().isEmpty || _isValidEmail(email!));
  }

  /// التحقق من صحة البريد الإلكتروني
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// معلومات الاتصال مكتملة
  bool get hasContactInfo {
    return phone != null && phone!.isNotEmpty ||
           email != null && email!.isNotEmpty;
  }

  /// نص عرض المورد
  String get displayText {
    if (company != null && company!.isNotEmpty) {
      return '$name - $company';
    }
    return name;
  }

  /// معلومات الاتصال للعرض
  String get contactInfo {
    List<String> info = [];
    if (phone != null && phone!.isNotEmpty) info.add(phone!);
    if (email != null && email!.isNotEmpty) info.add(email!);
    return info.join(' • ');
  }

  /// نسخ المورد مع تعديل بعض الخصائص
  SupplierModel copyWith({
    int? id,
    String? name,
    String? company,
    String? phone,
    String? email,
    String? address,
    double? totalPurchases,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// تحويل إلى Map لقاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      POSDatabase.supplierId: id,
      POSDatabase.supplierName: name,
      POSDatabase.supplierCompany: company,
      POSDatabase.supplierPhone: phone,
      POSDatabase.supplierEmail: email,
      POSDatabase.supplierAddress: address,
      POSDatabase.supplierTotalPurchases: totalPurchases,
      POSDatabase.supplierIsActive: isActive ? 1 : 0,
      POSDatabase.supplierCreatedAt: createdAt.toIso8601String(),
    };
  }

  /// إنشاء من Map من قاعدة البيانات
  factory SupplierModel.fromMap(Map<String, dynamic> map) {
    return SupplierModel(
      id: map[POSDatabase.supplierId],
      name: map[POSDatabase.supplierName] ?? '',
      company: map[POSDatabase.supplierCompany],
      phone: map[POSDatabase.supplierPhone],
      email: map[POSDatabase.supplierEmail],
      address: map[POSDatabase.supplierAddress],
      totalPurchases: map[POSDatabase.supplierTotalPurchases]?.toDouble() ?? 0.0,
      isActive: map[POSDatabase.supplierIsActive] == 1,
      createdAt: DateTime.parse(
        map[POSDatabase.supplierCreatedAt] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  String toString() {
    return 'SupplierModel{id: $id, name: $name, company: $company}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupplierModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// إحصائيات المورد
class SupplierStats {
  final int totalSuppliers;
  final int activeSuppliers;
  final double totalPurchaseAmount;
  final SupplierModel? topSupplier;

  const SupplierStats({
    required this.totalSuppliers,
    required this.activeSuppliers,
    required this.totalPurchaseAmount,
    this.topSupplier,
  });

  /// نسبة الموردين النشطين
  double get activePercentage {
    if (totalSuppliers == 0) return 0.0;
    return (activeSuppliers / totalSuppliers) * 100;
  }

  /// متوسط المشتريات لكل مورد
  double get averagePurchasePerSupplier {
    if (activeSuppliers == 0) return 0.0;
    return totalPurchaseAmount / activeSuppliers;
  }
}
