import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/SaleProvider.dart';
import 'package:pos/Model/CustomerModel.dart';

/// نافذة اختيار العملاء
class CustomerSelectionDialog extends StatefulWidget {
  const CustomerSelectionDialog({super.key});

  @override
  State<CustomerSelectionDialog> createState() =>
      _CustomerSelectionDialogState();
}

class _CustomerSelectionDialogState extends State<CustomerSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _showAddForm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 500,
        height: 600,
        child: Column(
          children: [
            _buildHeader(),
            if (_showAddForm) _buildAddForm() else _buildSearchAndList(),
          ],
        ),
      ),
    );
  }

  /// بناء رأس النافذة
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _showAddForm ? Icons.person_add : Icons.people,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _showAddForm ? 'إضافة عميل جديد' : 'اختيار عميل',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!_showAddForm)
            IconButton(
              onPressed: () {
                setState(() {
                  _showAddForm = true;
                });
              },
              icon: const Icon(Icons.person_add, color: Colors.white),
              tooltip: 'إضافة عميل جديد',
            ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// بناء البحث والقائمة
  Widget _buildSearchAndList() {
    return Expanded(
      child: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'البحث عن عميل بالاسم أو الهاتف...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<SaleProvider>().searchCustomers('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context.read<SaleProvider>().searchCustomers(value);
                setState(() {});
              },
            ),
          ),

          // قائمة العملاء
          Expanded(
            child: Consumer<SaleProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final customers = provider.filteredCustomers;

                if (customers.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return _buildCustomerCard(customer);
                  },
                );
              },
            ),
          ),

          // زر عدم تحديد عميل
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  context.read<SaleProvider>().selectCustomer(
                    CustomerModel(
                      name: '',
                      phone: '',
                      createdAt: DateTime.now(),
                    ),
                  );
                  Navigator.of(context).pop();
                },
                child: const Text('بدون عميل'),
              ),
            ),
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
            'لا توجد عملاء',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة عملاء جدد',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _showAddForm = true;
              });
            },
            icon: const Icon(Icons.person_add),
            label: const Text('إضافة عميل جديد'),
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة العميل
  Widget _buildCustomerCard(CustomerModel customer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '؟',
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.phone, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(customer.phone),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          context.read<SaleProvider>().selectCustomer(customer);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// بناء نموذج الإضافة
  Widget _buildAddForm() {
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'بيانات العميل الجديد',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // اسم العميل
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'اسم العميل *',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // رقم الهاتف
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 24),

                  // ملاحظة
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'سيتم حفظ العميل تلقائياً عند إتمام الفاتورة',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // أزرار العمليات
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showAddForm = false;
                        _nameController.clear();
                        _phoneController.clear();
                      });
                    },
                    child: const Text('رجوع'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _nameController.text.trim().isNotEmpty
                        ? _addCustomer
                        : null,
                    child: const Text('إضافة'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// إضافة عميل جديد
  void _addCustomer() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اسم العميل مطلوب'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // إنشاء عميل جديد
    final customer = CustomerModel(
      name: name,
      phone: phone.isNotEmpty ? phone : '',
      createdAt: DateTime.now(),
    );

    // اختيار العميل
    context.read<SaleProvider>().selectCustomer(customer);

    // إغلاق النافذة
    Navigator.of(context).pop();

    // عرض رسالة تأكيد
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إضافة العميل: $name'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
