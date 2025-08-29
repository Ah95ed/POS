import 'package:pos/Helper/DataBase/POSDatabase.dart';

/// نموذج المستخدم - User Model
/// يمثل بيانات المستخدمين في النظام مع الصلاحيات والمعلومات الشخصية
class UserModel {
  final int? id;
  final String username;
  final String email;
  final String password;
  final String fullName;
  final String phone;
  final UserRole role;
  final List<String> permissions;
  final bool isActive;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const UserModel({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    required this.role,
    this.permissions = const [],
    this.isActive = true,
    this.profileImage,
    required this.createdAt,
    this.lastLogin,
  });

  /// التحقق من صحة البيانات
  bool get isValid {
    return username.trim().isNotEmpty &&
           email.trim().isNotEmpty &&
           _isValidEmail(email) &&
           password.length >= 6 &&
           fullName.trim().isNotEmpty &&
           phone.trim().isNotEmpty;
  }

  /// التحقق من صحة البريد الإلكتروني
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// التحقق من وجود صلاحية معينة
  bool hasPermission(String permission) {
    return permissions.contains(permission) || role == UserRole.admin;
  }

  /// التحقق من إمكانية إدارة المنتجات
  bool get canManageProducts {
    return hasPermission('manage_products') || role == UserRole.admin;
  }

  /// التحقق من إمكانية إدارة المبيعات
  bool get canManageSales {
    return hasPermission('manage_sales') || 
           role == UserRole.admin || 
           role == UserRole.cashier;
  }

  /// التحقق من إمكانية عرض التقارير
  bool get canViewReports {
    return hasPermission('view_reports') || 
           role == UserRole.admin || 
           role == UserRole.manager;
  }

  /// التحقق من إمكانية إدارة العملاء
  bool get canManageCustomers {
    return hasPermission('manage_customers') || role == UserRole.admin;
  }

  /// التحقق من إمكانية إدارة الديون
  bool get canManageDebts {
    return hasPermission('manage_debts') || 
           role == UserRole.admin || 
           role == UserRole.manager;
  }

  /// نسخ المستخدم مع تعديل بعض الخصائص
  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? password,
    String? fullName,
    String? phone,
    UserRole? role,
    List<String>? permissions,
    bool? isActive,
    String? profileImage,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  /// تحويل إلى Map لقاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      POSDatabase.userId: id,
      POSDatabase.userUsername: username,
      POSDatabase.userEmail: email,
      POSDatabase.userPassword: password,
      POSDatabase.userFullName: fullName,
      POSDatabase.userPhone: phone,
      POSDatabase.userRole: role.toString().split('.').last,
      POSDatabase.userPermissions: permissions.join(','),
      POSDatabase.userIsActive: isActive ? 1 : 0,
      POSDatabase.userProfileImage: profileImage,
      POSDatabase.userCreatedAt: createdAt.toIso8601String(),
      POSDatabase.userLastLogin: lastLogin?.toIso8601String(),
    };
  }

  /// إنشاء من Map من قاعدة البيانات
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map[POSDatabase.userId],
      username: map[POSDatabase.userUsername] ?? '',
      email: map[POSDatabase.userEmail] ?? '',
      password: map[POSDatabase.userPassword] ?? '',
      fullName: map[POSDatabase.userFullName] ?? '',
      phone: map[POSDatabase.userPhone] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map[POSDatabase.userRole],
        orElse: () => UserRole.cashier,
      ),
      permissions: map[POSDatabase.userPermissions] != null
          ? map[POSDatabase.userPermissions].split(',')
          : [],
      isActive: map[POSDatabase.userIsActive] == 1,
      profileImage: map[POSDatabase.userProfileImage],
      createdAt: DateTime.parse(map[POSDatabase.userCreatedAt] ?? DateTime.now().toIso8601String()),
      lastLogin: map[POSDatabase.userLastLogin] != null
          ? DateTime.parse(map[POSDatabase.userLastLogin])
          : null,
    );
  }

  @override
  String toString() {
    return 'UserModel{id: $id, username: $username, fullName: $fullName, role: $role}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// أدوار المستخدمين في النظام
enum UserRole {
  admin,    // مدير عام - جميع الصلاحيات
  manager,  // مدير - معظم الصلاحيات
  cashier,  // كاشير - مبيعات وعملاء
  employee, // موظف - صلاحيات محدودة
}

/// امتداد لأدوار المستخدمين
extension UserRoleExtension on UserRole {
  /// اسم الدور باللغة العربية
  String get arabicName {
    switch (this) {
      case UserRole.admin:
        return 'مدير عام';
      case UserRole.manager:
        return 'مدير';
      case UserRole.cashier:
        return 'كاشير';
      case UserRole.employee:
        return 'موظف';
    }
  }

  /// وصف الدور
  String get description {
    switch (this) {
      case UserRole.admin:
        return 'صلاحية كاملة لجميع أجزاء النظام';
      case UserRole.manager:
        return 'إدارة المخزون والتقارير والموظفين';
      case UserRole.cashier:
        return 'إدارة المبيعات والعملاء';
      case UserRole.employee:
        return 'عرض البيانات الأساسية فقط';
    }
  }

  /// الصلاحيات الافتراضية لكل دور
  List<String> get defaultPermissions {
    switch (this) {
      case UserRole.admin:
        return [
          'manage_products',
          'manage_sales',
          'manage_customers',
          'manage_debts',
          'view_reports',
          'manage_users',
          'manage_settings',
          'manage_suppliers',
          'manage_purchases',
        ];
      case UserRole.manager:
        return [
          'manage_products',
          'manage_sales',
          'manage_customers',
          'manage_debts',
          'view_reports',
          'manage_suppliers',
          'manage_purchases',
        ];
      case UserRole.cashier:
        return [
          'manage_sales',
          'manage_customers',
          'view_products',
        ];
      case UserRole.employee:
        return [
          'view_products',
          'view_sales',
        ];
    }
  }
}
