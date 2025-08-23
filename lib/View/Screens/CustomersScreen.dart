import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/CustomerProvider.dart';
import 'package:pos/Model/SaleModel.dart';
import 'package:pos/View/Widgets/CustomerCard.dart';
import 'package:pos/View/Widgets/CustomerFormDialog.dart';
import 'package:pos/View/Widgets/CustomerStatsWidget.dart';

/// شاشة إدارة العملاء
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  CustomerType _selectedFilter = CustomerType.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Consumer<CustomerProvider>(
        builder: (context, customerProvider, child) {
          if (customerProvider.isLoading &&
              customerProvider.customers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // إحصائيات العملاء
              // CustomerStatsWidget(stats: customerProvider.customerStats),

              // شريط البحث والتصفية
              _buildSearchAndFilterBar(customerProvider),

              // قائمة العملاء
              Expanded(child: _buildCustomersList(customerProvider)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('إضافة عميل'),
        backgroundColor: Colors.green[700],
      ),
    );
  }

  /// بناء شريط التطبيق
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'إدارة العملاء',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: Colors.green[700],
      elevation: 0,
      actions: [
        Consumer<CustomerProvider>(
          builder: (context, provider, child) {
            return IconButton(
              icon: Badge(
                label: Text('${provider.customersCount}'),
                child: const Icon(Icons.people, color: Colors.white),
              ),
              onPressed: () => _showCustomerStats(provider),
              tooltip: 'إحصائيات العملاء',
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'export':
                _exportCustomers();
                break;
              case 'import':
                _importCustomers();
                break;
              case 'backup':
                _backupCustomers();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.file_download),
                  SizedBox(width: 8),
                  Text('تصدير العملاء'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'import',
              child: Row(
                children: [
                  Icon(Icons.file_upload),
                  SizedBox(width: 8),
                  Text('استيراد العملاء'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'backup',
              child: Row(
                children: [
                  Icon(Icons.backup),
                  SizedBox(width: 8),
                  Text('نسخ احتياطي'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// بناء شريط البحث والتصفية
  Widget _buildSearchAndFilterBar(CustomerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // شريط البحث
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'البحث بالاسم أو رقم الهاتف أو البريد الإلكتروني...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        provider.clearSearch();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[700]!),
              ),
            ),
            onChanged: provider.searchCustomers,
          ),

          const SizedBox(height: 12),

          // أزرار التصفية
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: CustomerType.values.map((type) {
                final isSelected = _selectedFilter == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_getFilterLabel(type)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = type;
                      });
                    },
                    selectedColor: Colors.green[100],
                    checkmarkColor: Colors.green[700],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء قائمة العملاء
  Widget _buildCustomersList(CustomerProvider provider) {
    if (provider.errorMessage != null) {
      return _buildErrorState(provider);
    }

    final customers = provider.getCustomersByType(_selectedFilter);

    if (customers.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadCustomers(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: customers.length,
        itemBuilder: (context, index) {
          final customer = customers[index];
          return CustomerCard(
            customer: customer,
            onTap: () => _showCustomerDetails(customer),
            onEdit: () => _showEditCustomerDialog(customer),
            onDelete: () => _showDeleteConfirmation(customer),
            onToggleVip: () => _toggleVipStatus(customer),
          );
        },
      ),
    );
  }

  /// بناء حالة الخطأ
  Widget _buildErrorState(CustomerProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ',
            style: TextStyle(fontSize: 18, color: Colors.red[600]),
          ),
          const SizedBox(height: 8),
          Text(
            provider.errorMessage ?? 'خطأ غير معروف',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.loadCustomers(),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  /// بناء حالة القائمة الفارغة
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا يوجد عملاء',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة عميل جديد',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddCustomerDialog(),
            icon: const Icon(Icons.person_add),
            label: const Text('إضافة عميل'),
          ),
        ],
      ),
    );
  }

  /// عرض حوار إضافة عميل
  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomerFormDialog(
        title: 'إضافة عميل جديد',
        onSave: (customer) async {
          final provider = context.read<CustomerProvider>();
          final success = await provider.addCustomer(customer);

          if (success) {
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم إضافة العميل بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.errorMessage ?? 'خطأ في إضافة العميل'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  /// عرض حوار تعديل عميل
  void _showEditCustomerDialog(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => CustomerFormDialog(
        title: 'تعديل العميل',
        customer: customer,
        onSave: (updatedCustomer) async {
          final provider = context.read<CustomerProvider>();
          final success = await provider.updateCustomer(updatedCustomer);

          if (success) {
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تحديث العميل بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.errorMessage ?? 'خطأ في تحديث العميل'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  /// عرض تأكيد الحذف
  void _showDeleteConfirmation(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف العميل "${customer.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = context.read<CustomerProvider>();
              final success = await provider.deleteCustomer(customer.id!);

              if (success) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف العميل بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ?? 'خطأ في حذف العميل',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  /// تبديل حالة العميل المميز
  void _toggleVipStatus(CustomerModel customer) async {
    final provider = context.read<CustomerProvider>();
    final success = await provider.updateVipStatus(
      customer.id!,
      !customer.isVip,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              customer.isVip
                  ? 'تم إلغاء العضوية المميزة'
                  : 'تم تفعيل العضوية المميزة',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'خطأ في تحديث حالة العميل'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// عرض تفاصيل العميل
  void _showCustomerDetails(CustomerModel customer) {
    // TODO: تنفيذ شاشة تفاصيل العميل
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم تنفيذ شاشة تفاصيل العميل قريباً')),
    );
  }

  /// عرض إحصائيات العملاء
  void _showCustomerStats(CustomerProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إحصائيات العملاء'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: SingleChildScrollView(
            child: CustomerStatsWidget(stats: provider.customerStats),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  /// تصدير العملاء
  void _exportCustomers() {
    // TODO: تنفيذ تصدير العملاء
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم تنفيذ تصدير العملاء قريباً')),
    );
  }

  /// استيراد العملاء
  void _importCustomers() {
    // TODO: تنفيذ استيراد العملاء
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم تنفيذ استيراد العملاء قريباً')),
    );
  }

  /// نسخ احتياطي للعملاء
  void _backupCustomers() {
    // TODO: تنفيذ النسخ الاحتياطي
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم تنفيذ النسخ الاحتياطي قريباً')),
    );
  }

  /// الحصول على تسمية الفلتر
  String _getFilterLabel(CustomerType type) {
    switch (type) {
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
