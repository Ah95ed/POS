import 'package:flutter/foundation.dart';
import 'package:pos/Model/UserModel.dart';
import 'package:pos/Repository/UserRepository.dart';

/// مزود حالة المستخدمين - User Provider
/// يدير جميع العمليات والحالات المتعلقة بالمستخدمين والصلاحيات
class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();

  // الحالة العامة
  bool _isLoading = false;
  String _errorMessage = '';

  // المستخدم الحالي
  UserModel? _currentUser;
  bool _isLoggedIn = false;

  // قائمة المستخدمين
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];

  // إحصائيات المستخدمين
  Map<String, dynamic> _userStats = {};

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  List<UserModel> get users => _users;
  List<UserModel> get filteredUsers => _filteredUsers;
  Map<String, dynamic> get userStats => _userStats;

  /// تحديث حالة التحميل
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// تحديث رسالة الخطأ
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// مسح رسالة الخطأ
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  /// تسجيل الدخول
  Future<bool> login(String usernameOrEmail, String password) async {
    _setLoading(true);
    clearError();

    try {
      final result = await _userRepository.login(usernameOrEmail, password);

      if (result.isSuccess && result.data != null) {
        _currentUser = result.data!;
        _isLoggedIn = true;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('خطأ في تسجيل الدخول: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// تسجيل الخروج
  void logout() {
    _currentUser = null;
    _isLoggedIn = false;
    clearError();
    notifyListeners();
  }

  /// جلب جميع المستخدمين
  Future<bool> loadUsers() async {
    _setLoading(true);
    clearError();

    try {
      final result = await _userRepository.getAllUsers();

      if (result.isSuccess) {
        _users = result.data!;
        _filteredUsers = List.from(_users);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('خطأ في جلب المستخدمين: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// جلب المستخدمين النشطين فقط
  Future<bool> loadActiveUsers() async {
    _setLoading(true);
    clearError();

    try {
      final result = await _userRepository.getActiveUsers();

      if (result.isSuccess) {
        _users = result.data!;
        _filteredUsers = List.from(_users);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('خطأ في جلب المستخدمين النشطين: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// إضافة مستخدم جديد
  Future<bool> addUser(UserModel user) async {
    _setLoading(true);
    clearError();

    try {
      final result = await _userRepository.addUser(user);

      if (result.isSuccess) {
        _users.add(result.data!);
        _filteredUsers = List.from(_users);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('خطأ في إضافة المستخدم: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// تحديث مستخدم
  Future<bool> updateUser(UserModel user) async {
    _setLoading(true);
    clearError();

    try {
      final result = await _userRepository.updateUser(user);

      if (result.isSuccess) {
        final index = _users.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _users[index] = result.data!;
          _filteredUsers = List.from(_users);
        }

        // تحديث المستخدم الحالي إذا كان هو نفسه
        if (_currentUser?.id == user.id) {
          _currentUser = result.data!;
        }

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('خطأ في تحديث المستخدم: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// تحديث كلمة المرور
  Future<bool> updatePassword(
    int userId,
    String oldPassword,
    String newPassword,
  ) async {
    _setLoading(true);
    clearError();

    try {
      final result = await _userRepository.updatePassword(
        userId,
        oldPassword,
        newPassword,
      );

      if (result.isSuccess) {
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('خطأ في تحديث كلمة المرور: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// تفعيل/إلغاء تفعيل مستخدم
  Future<bool> toggleUserStatus(int userId, bool isActive) async {
    _setLoading(true);
    clearError();

    try {
      final result = await _userRepository.toggleUserStatus(userId, isActive);

      if (result.isSuccess) {
        final index = _users.indexWhere((u) => u.id == userId);
        if (index != -1) {
          _users[index] = _users[index].copyWith(isActive: isActive);
          _filteredUsers = List.from(_users);
        }

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('خطأ في تحديث حالة المستخدم: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// حذف مستخدم
  Future<bool> deleteUser(int userId) async {
    _setLoading(true);
    clearError();

    try {
      final result = await _userRepository.deleteUser(userId);

      if (result.isSuccess) {
        _users.removeWhere((u) => u.id == userId);
        _filteredUsers = List.from(_users);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('خطأ في حذف المستخدم: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// البحث في المستخدمين
  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _filteredUsers = List.from(_users);
      notifyListeners();
      return;
    }

    clearError();

    try {
      final result = await _userRepository.searchUsers(query);

      if (result.isSuccess) {
        _filteredUsers = result.data!;
        notifyListeners();
      } else {
        _setError(result.errorMessage);
      }
    } catch (e) {
      _setError('خطأ في البحث: ${e.toString()}');
    }
  }

  /// تصفية المستخدمين حسب الدور
  void filterUsersByRole(UserRole? role) {
    if (role == null) {
      _filteredUsers = List.from(_users);
    } else {
      _filteredUsers = _users.where((user) => user.role == role).toList();
    }
    notifyListeners();
  }

  /// تصفية المستخدمين حسب الحالة
  void filterUsersByStatus(bool? isActive) {
    if (isActive == null) {
      _filteredUsers = List.from(_users);
    } else {
      _filteredUsers = _users
          .where((user) => user.isActive == isActive)
          .toList();
    }
    notifyListeners();
  }

  /// جلب المستخدمين حسب الدور
  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      final result = await _userRepository.getUsersByRole(role);
      return result.isSuccess ? result.data! : [];
    } catch (e) {
      _setError('خطأ في جلب المستخدمين: ${e.toString()}');
      return [];
    }
  }

  /// جلب إحصائيات المستخدمين
  Future<bool> loadUserStats() async {
    clearError();

    try {
      final result = await _userRepository.getUsersStats();

      if (result.isSuccess) {
        _userStats = result.data!;
        notifyListeners();
        return true;
      } else {
        _setError(result.errorMessage);
        return false;
      }
    } catch (e) {
      _setError('خطأ في جلب الإحصائيات: ${e.toString()}');
      return false;
    }
  }

  /// التحقق من صلاحية المستخدم الحالي
  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    return _currentUser!.hasPermission(permission);
  }

  /// التحقق من إمكانية إدارة المنتجات
  bool get canManageProducts {
    return _currentUser?.canManageProducts ?? false;
  }

  /// التحقق من إمكانية إدارة المبيعات
  bool get canManageSales {
    return _currentUser?.canManageSales ?? false;
  }

  /// التحقق من إمكانية عرض التقارير
  bool get canViewReports {
    return _currentUser?.canViewReports ?? false;
  }

  /// التحقق من إمكانية إدارة العملاء
  bool get canManageCustomers {
    return _currentUser?.canManageCustomers ?? false;
  }

  /// التحقق من إمكانية إدارة الديون
  bool get canManageDebts {
    return _currentUser?.canManageDebts ?? false;
  }

  /// التحقق من كون المستخدم مدير
  bool get isAdmin {
    return _currentUser?.role == UserRole.admin;
  }

  /// التحقق من كون المستخدم مدير أو مدير عام
  bool get isManagerOrAdmin {
    return _currentUser?.role == UserRole.admin ||
        _currentUser?.role == UserRole.manager;
  }

  /// إعادة تحميل البيانات
  Future<void> refresh() async {
    await Future.wait([loadUsers(), loadUserStats()]);
  }

  /// مسح جميع البيانات
  void clear() {
    _users.clear();
    _filteredUsers.clear();
    _userStats.clear();
    _currentUser = null;
    _isLoggedIn = false;
    clearError();
    notifyListeners();
  }
}
