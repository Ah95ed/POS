import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/UserProvider.dart';
import 'package:pos/Model/UserModel.dart';

/// حوار نموذج المستخدم - User Form Dialog
/// حوار لإضافة أو تعديل مستخدم
class UserFormDialog extends StatefulWidget {
  final UserModel? user;

  const UserFormDialog({super.key, this.user});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  UserRole _selectedRole = UserRole.cashier;
  List<String> _selectedPermissions = [];
  bool _isActive = true;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _initializeFields();
    }
  }

  /// تهيئة الحقول للتعديل
  void _initializeFields() {
    final user = widget.user!;
    _usernameController.text = user.username;
    _emailController.text = user.email;
    _fullNameController.text = user.fullName;
    _phoneController.text = user.phone;
    _selectedRole = user.role;
    _selectedPermissions = List.from(user.permissions);
    _isActive = user.isActive;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// حفظ المستخدم
  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final user = UserModel(
      id: widget.user?.id,
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.isNotEmpty
          ? _passwordController.text
          : widget.user?.password ?? '',
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _selectedRole,
      permissions: _selectedPermissions,
      isActive: _isActive,
      createdAt: widget.user?.createdAt ?? DateTime.now(),
      lastLogin: widget.user?.lastLogin,
    );

    bool success;
    if (widget.user == null) {
      success = await userProvider.addUser(user);
    } else {
      success = await userProvider.updateUser(user);
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.user == null
                ? 'تم إضافة المستخدم بنجاح'
                : 'تم تحديث المستخدم بنجاح',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.user == null ? 'إضافة مستخدم' : 'تعديل مستخدم'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // اسم المستخدم
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المستخدم *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال اسم المستخدم';
                      }
                      if (value.length < 3) {
                        return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // البريد الإلكتروني
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني *',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال البريد الإلكتروني';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'يرجى إدخال بريد إلكتروني صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // كلمة المرور
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: widget.user == null
                          ? 'كلمة المرور *'
                          : 'كلمة المرور الجديدة',
                      hintText: widget.user != null
                          ? 'اتركها فارغة لعدم التغيير'
                          : null,
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: !_isPasswordVisible,
                    validator: (value) {
                      if (widget.user == null) {
                        // للمستخدمين الجدد
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال كلمة المرور';
                        }
                        if (value.length < 6) {
                          return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                        }
                      } else {
                        // للمستخدمين الموجودين
                        if (value != null &&
                            value.isNotEmpty &&
                            value.length < 6) {
                          return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // الاسم الكامل
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم الكامل *',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال الاسم الكامل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // رقم الهاتف
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف *',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال رقم الهاتف';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // الدور
                  DropdownButtonFormField<UserRole>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'الدور *',
                      prefixIcon: Icon(Icons.admin_panel_settings),
                      border: OutlineInputBorder(),
                    ),
                    items: UserRole.values
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(role.arabicName),
                                Text(
                                  role.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                        _selectedPermissions = value.defaultPermissions;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // الصلاحيات
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'الصلاحيات',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Divider(height: 1),
                        ..._buildPermissionCheckboxes(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // حالة التفعيل
                  SwitchListTile(
                    title: const Text('مستخدم نشط'),
                    subtitle: Text(
                      _isActive
                          ? 'يمكن للمستخدم تسجيل الدخول'
                          : 'لا يمكن للمستخدم تسجيل الدخول',
                    ),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // أزرار الحفظ والإلغاء
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Consumer<UserProvider>(
                          builder: (context, userProvider, child) {
                            return ElevatedButton(
                              onPressed: userProvider.isLoading
                                  ? null
                                  : _saveUser,
                              child: userProvider.isLoading
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(widget.user == null ? 'إضافة' : 'حفظ'),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  // رسالة الخطأ
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      if (userProvider.errorMessage.isNotEmpty) {
                        return Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red[200]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  userProvider.errorMessage,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// بناء خانات اختيار الصلاحيات
  List<Widget> _buildPermissionCheckboxes() {
    const permissions = {
      'manage_products': 'إدارة المنتجات',
      'manage_sales': 'إدارة المبيعات',
      'manage_customers': 'إدارة العملاء',
      'manage_debts': 'إدارة الديون',
      'view_reports': 'عرض التقارير',
      'manage_users': 'إدارة المستخدمين',
      'manage_settings': 'إدارة الإعدادات',
      'manage_suppliers': 'إدارة الموردين',
      'manage_purchases': 'إدارة المشتريات',
    };

    return permissions.entries.map((entry) {
      final permission = entry.key;
      final title = entry.value;
      final isChecked = _selectedPermissions.contains(permission);

      return CheckboxListTile(
        title: Text(title),
        value: isChecked,
        dense: true,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              if (!_selectedPermissions.contains(permission)) {
                _selectedPermissions.add(permission);
              }
            } else {
              _selectedPermissions.remove(permission);
            }
          });
        },
      );
    }).toList();
  }
}
