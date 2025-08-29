import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/UserProvider.dart';
import 'package:pos/Model/UserModel.dart';
import 'package:pos/View/Widgets/UserFormDialog.dart';

/// شاشة إدارة المستخدمين - Users Management Screen
/// شاشة عرض وإدارة المستخدمين في النظام
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchController = TextEditingController();
  UserRole? _selectedRole;
  bool? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// تحميل البيانات
  Future<void> _loadData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await Future.wait([userProvider.loadUsers(), userProvider.loadUserStats()]);
  }

  /// إضافة مستخدم جديد
  void _addUser() {
    showDialog(context: context, builder: (context) => const UserFormDialog());
  }

  /// تعديل مستخدم
  void _editUser(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(user: user),
    );
  }

  /// حذف مستخدم
  void _deleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المستخدم "${user.fullName}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final userProvider = Provider.of<UserProvider>(
                context,
                listen: false,
              );
              final success = await userProvider.deleteUser(user.id!);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف المستخدم بنجاح')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  /// تفعيل/إلغاء تفعيل مستخدم
  void _toggleUserStatus(UserModel user) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await userProvider.toggleUserStatus(
      user.id!,
      !user.isActive,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user.isActive ? 'تم إلغاء تفعيل المستخدم' : 'تم تفعيل المستخدم',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        actions: [
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              if (userProvider.isAdmin) {
                return IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: _addUser,
                  tooltip: 'إضافة مستخدم',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          // بطاقات الإحصائيات
          _buildStatsCards(),

          // شريط البحث والفلاتر
          _buildSearchAndFilters(),

          // قائمة المستخدمين
          Expanded(child: _buildUsersList()),
        ],
      ),
    );
  }

  /// بناء بطاقات الإحصائيات
  Widget _buildStatsCards() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final stats = userProvider.userStats;

        return Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'إجمالي المستخدمين',
                  '${stats['total'] ?? 0}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'المستخدمين النشطين',
                  '${stats['active'] ?? 0}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'المستخدمين المعطلين',
                  '${stats['inactive'] ?? 0}',
                  Icons.person_off,
                  Colors.orange,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// بناء بطاقة إحصائية
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء شريط البحث والفلاتر
  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // شريط البحث
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'البحث في المستخدمين...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (_) => _performSearch(),
          ),
          const SizedBox(height: 8),

          // فلاتر الدور والحالة
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<UserRole?>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'الدور',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<UserRole?>(
                      value: null,
                      child: Text('جميع الأدوار'),
                    ),
                    ...UserRole.values.map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(role.arabicName),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedRole = value);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<bool?>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'الحالة',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem<bool?>(
                      value: null,
                      child: Text('جميع الحالات'),
                    ),
                    DropdownMenuItem<bool?>(value: true, child: Text('نشط')),
                    DropdownMenuItem<bool?>(value: false, child: Text('معطل')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// تنفيذ البحث
  void _performSearch() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.searchUsers(_searchController.text);
  }

  /// تطبيق الفلاتر
  void _applyFilters() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.filterUsersByRole(_selectedRole);
    userProvider.filterUsersByStatus(_selectedStatus);
  }

  /// بناء قائمة المستخدمين
  Widget _buildUsersList() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (userProvider.errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  userProvider.errorMessage,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        final users = userProvider.filteredUsers;

        if (users.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا توجد مستخدمين', style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _buildUserCard(user);
            },
          ),
        );
      },
    );
  }

  /// بناء بطاقة مستخدم
  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive ? Colors.green : Colors.grey,
          child: Text(
            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${user.username} • ${user.email}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getRoleColor(user.role)),
                  ),
                  child: Text(
                    user.role.arabicName,
                    style: TextStyle(
                      color: _getRoleColor(user.role),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: user.isActive ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Text(
                    user.isActive ? 'نشط' : 'معطل',
                    style: TextStyle(
                      color: user.isActive ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            if (userProvider.isAdmin) {
              return PopupMenuButton<String>(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('تعديل'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_status',
                    child: Row(
                      children: [
                        Icon(
                          user.isActive ? Icons.person_off : Icons.check_circle,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(user.isActive ? 'إلغاء التفعيل' : 'تفعيل'),
                      ],
                    ),
                  ),
                  if (user.id != userProvider.currentUser?.id)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('حذف', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editUser(user);
                      break;
                    case 'toggle_status':
                      _toggleUserStatus(user);
                      break;
                    case 'delete':
                      _deleteUser(user);
                      break;
                  }
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
        onTap: () => _editUser(user),
      ),
    );
  }

  /// الحصول على لون الدور
  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.manager:
        return Colors.orange;
      case UserRole.cashier:
        return Colors.blue;
      case UserRole.employee:
        return Colors.green;
    }
  }
}
