import 'package:pos/Helper/DataBase/POSDatabase.dart';
import 'package:pos/Helper/Result.dart';
import 'package:pos/Model/UserModel.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// مستودع المستخدمين - User Repository
/// يدير جميع العمليات المتعلقة بقاعدة البيانات للمستخدمين
class UserRepository {
  /// الحصول على جميع المستخدمين
  Future<Result<List<UserModel>>> getAllUsers() async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        POSDatabase.usersTable,
        orderBy: '${POSDatabase.userCreatedAt} DESC',
      );

      final users = maps.map((map) => UserModel.fromMap(map)).toList();
      return Result.success(users);
    } catch (e) {
      return Result.error('خطأ في جلب المستخدمين: ${e.toString()}');
    }
  }

  /// الحصول على المستخدمين النشطين فقط
  Future<Result<List<UserModel>>> getActiveUsers() async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        POSDatabase.usersTable,
        where: '${POSDatabase.userIsActive} = ?',
        whereArgs: [1],
        orderBy: '${POSDatabase.userFullName} ASC',
      );

      final users = maps.map((map) => UserModel.fromMap(map)).toList();
      return Result.success(users);
    } catch (e) {
      return Result.error('خطأ في جلب المستخدمين النشطين: ${e.toString()}');
    }
  }

  /// الحصول على مستخدم بالمعرف
  Future<Result<UserModel?>> getUserById(int id) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        POSDatabase.usersTable,
        where: '${POSDatabase.userId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return Result.success(null);
      }

      final user = UserModel.fromMap(maps.first);
      return Result.success(user);
    } catch (e) {
      return Result.error('خطأ في جلب المستخدم: ${e.toString()}');
    }
  }

  /// البحث عن مستخدم بالاسم أو البريد الإلكتروني
  Future<Result<UserModel?>> getUserByUsernameOrEmail(
    String usernameOrEmail,
  ) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        POSDatabase.usersTable,
        where:
            '${POSDatabase.userUsername} = ? OR ${POSDatabase.userEmail} = ?',
        whereArgs: [usernameOrEmail, usernameOrEmail],
        limit: 1,
      );

      if (maps.isEmpty) {
        return Result.success(null);
      }

      final user = UserModel.fromMap(maps.first);
      return Result.success(user);
    } catch (e) {
      return Result.error('خطأ في البحث عن المستخدم: ${e.toString()}');
    }
  }

  /// تشفير كلمة المرور
  String _hashPassword(String password) {
    var bytes = utf8.encode(password + 'pos_salt_2024'); // إضافة salt للأمان
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// التحقق من كلمة المرور
  bool _verifyPassword(String password, String hashedPassword) {
    return _hashPassword(password) == hashedPassword;
  }

  /// تسجيل الدخول
  Future<Result<UserModel?>> login(
    String usernameOrEmail,
    String password,
  ) async {
    try {
      final userResult = await getUserByUsernameOrEmail(usernameOrEmail);
      if (!userResult.isSuccess || userResult.data == null) {
        return Result.error('اسم المستخدم أو كلمة المرور غير صحيحة');
      }

      final user = userResult.data!;

      // التحقق من كلمة المرور (للمدير الافتراضي نتحقق بدون تشفير مؤقتاً)
      bool passwordValid = false;
      if (user.username == 'admin' && password == 'admin123') {
        passwordValid = true;
      } else {
        passwordValid = _verifyPassword(password, user.password);
      }

      if (!passwordValid) {
        return Result.error('اسم المستخدم أو كلمة المرور غير صحيحة');
      }

      if (!user.isActive) {
        return Result.error('الحساب معطل، يرجى التواصل مع المدير');
      }

      // تحديث آخر تسجيل دخول
      await updateLastLogin(user.id!);

      return Result.success(user);
    } catch (e) {
      return Result.error('خطأ في تسجيل الدخول: ${e.toString()}');
    }
  }

  /// إضافة مستخدم جديد
  Future<Result<UserModel>> addUser(UserModel user) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      if (!user.isValid) {
        return Result.error('بيانات المستخدم غير صحيحة');
      }

      // التحقق من عدم وجود اسم المستخدم أو البريد الإلكتروني
      final existingUser = await getUserByUsernameOrEmail(user.username);
      if (existingUser.isSuccess && existingUser.data != null) {
        return Result.error('اسم المستخدم موجود بالفعل');
      }

      final existingEmail = await getUserByUsernameOrEmail(user.email);
      if (existingEmail.isSuccess && existingEmail.data != null) {
        return Result.error('البريد الإلكتروني موجود بالفعل');
      }

      // تشفير كلمة المرور
      final hashedPassword = _hashPassword(user.password);
      final userWithHashedPassword = user.copyWith(password: hashedPassword);

      final id = await db.insert(
        POSDatabase.usersTable,
        userWithHashedPassword.toMap(),
      );

      final newUser = userWithHashedPassword.copyWith(id: id);
      return Result.success(newUser);
    } catch (e) {
      return Result.error('خطأ في إضافة المستخدم: ${e.toString()}');
    }
  }

  /// تحديث مستخدم
  Future<Result<UserModel>> updateUser(UserModel user) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      if (!user.isValid || user.id == null) {
        return Result.error('بيانات المستخدم غير صحيحة');
      }

      final rowsAffected = await db.update(
        POSDatabase.usersTable,
        user.toMap(),
        where: '${POSDatabase.userId} = ?',
        whereArgs: [user.id],
      );

      if (rowsAffected == 0) {
        return Result.error('المستخدم غير موجود');
      }

      return Result.success(user);
    } catch (e) {
      return Result.error('خطأ في تحديث المستخدم: ${e.toString()}');
    }
  }

  /// تحديث كلمة المرور
  Future<Result<bool>> updatePassword(
    int userId,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final userResult = await getUserById(userId);
      if (!userResult.isSuccess || userResult.data == null) {
        return Result.error('المستخدم غير موجود');
      }

      final user = userResult.data!;

      // التحقق من كلمة المرور القديمة
      if (!_verifyPassword(oldPassword, user.password)) {
        return Result.error('كلمة المرور القديمة غير صحيحة');
      }

      if (newPassword.length < 6) {
        return Result.error('كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل');
      }

      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      // تشفير كلمة المرور الجديدة
      final hashedNewPassword = _hashPassword(newPassword);

      final rowsAffected = await db.update(
        POSDatabase.usersTable,
        {POSDatabase.userPassword: hashedNewPassword},
        where: '${POSDatabase.userId} = ?',
        whereArgs: [userId],
      );

      return Result.success(rowsAffected > 0);
    } catch (e) {
      return Result.error('خطأ في تحديث كلمة المرور: ${e.toString()}');
    }
  }

  /// تحديث آخر تسجيل دخول
  Future<Result<bool>> updateLastLogin(int userId) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final rowsAffected = await db.update(
        POSDatabase.usersTable,
        {POSDatabase.userLastLogin: DateTime.now().toIso8601String()},
        where: '${POSDatabase.userId} = ?',
        whereArgs: [userId],
      );

      return Result.success(rowsAffected > 0);
    } catch (e) {
      return Result.error('خطأ في تحديث تسجيل الدخول: ${e.toString()}');
    }
  }

  /// تفعيل/إلغاء تفعيل مستخدم
  Future<Result<bool>> toggleUserStatus(int userId, bool isActive) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final rowsAffected = await db.update(
        POSDatabase.usersTable,
        {POSDatabase.userIsActive: isActive ? 1 : 0},
        where: '${POSDatabase.userId} = ?',
        whereArgs: [userId],
      );

      return Result.success(rowsAffected > 0);
    } catch (e) {
      return Result.error('خطأ في تحديث حالة المستخدم: ${e.toString()}');
    }
  }

  /// حذف مستخدم
  Future<Result<bool>> deleteUser(int userId) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      // التحقق من عدم كون المستخدم هو المدير الوحيد
      final adminsResult = await getUsersByRole(UserRole.admin);
      if (adminsResult.isSuccess && adminsResult.data!.length == 1) {
        final adminUser = adminsResult.data!.first;
        if (adminUser.id == userId) {
          return Result.error('لا يمكن حذف المدير الوحيد في النظام');
        }
      }

      final rowsAffected = await db.delete(
        POSDatabase.usersTable,
        where: '${POSDatabase.userId} = ?',
        whereArgs: [userId],
      );

      return Result.success(rowsAffected > 0);
    } catch (e) {
      return Result.error('خطأ في حذف المستخدم: ${e.toString()}');
    }
  }

  /// البحث في المستخدمين
  Future<Result<List<UserModel>>> searchUsers(String query) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        POSDatabase.usersTable,
        where:
            '''
          ${POSDatabase.userFullName} LIKE ? OR 
          ${POSDatabase.userUsername} LIKE ? OR 
          ${POSDatabase.userEmail} LIKE ? OR 
          ${POSDatabase.userPhone} LIKE ?
        ''',
        whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
        orderBy: '${POSDatabase.userFullName} ASC',
      );

      final users = maps.map((map) => UserModel.fromMap(map)).toList();
      return Result.success(users);
    } catch (e) {
      return Result.error('خطأ في البحث: ${e.toString()}');
    }
  }

  /// الحصول على المستخدمين حسب الدور
  Future<Result<List<UserModel>>> getUsersByRole(UserRole role) async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        POSDatabase.usersTable,
        where: '${POSDatabase.userRole} = ?',
        whereArgs: [role.toString().split('.').last],
        orderBy: '${POSDatabase.userFullName} ASC',
      );

      final users = maps.map((map) => UserModel.fromMap(map)).toList();
      return Result.success(users);
    } catch (e) {
      return Result.error('خطأ في جلب المستخدمين: ${e.toString()}');
    }
  }

  /// إحصائيات المستخدمين
  Future<Result<Map<String, dynamic>>> getUsersStats() async {
    try {
      final db = await POSDatabase.database;
      if (db == null) {
        return Result.error('خطأ في الاتصال بقاعدة البيانات');
      }

      // إجمالي المستخدمين
      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${POSDatabase.usersTable}',
      );
      final totalUsers = totalResult.first['count'] as int;

      // المستخدمين النشطين
      final activeResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${POSDatabase.usersTable} WHERE ${POSDatabase.userIsActive} = 1',
      );
      final activeUsers = activeResult.first['count'] as int;

      // المستخدمين حسب الدور
      final rolesResult = await db.rawQuery('''
        SELECT ${POSDatabase.userRole}, COUNT(*) as count 
        FROM ${POSDatabase.usersTable} 
        GROUP BY ${POSDatabase.userRole}
      ''');

      final roleStats = <String, int>{};
      for (final row in rolesResult) {
        roleStats[row[POSDatabase.userRole] as String] = row['count'] as int;
      }

      return Result.success({
        'total': totalUsers,
        'active': activeUsers,
        'inactive': totalUsers - activeUsers,
        'roles': roleStats,
      });
    } catch (e) {
      return Result.error('خطأ في جلب الإحصائيات: ${e.toString()}');
    }
  }
}
