import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/DebtProvider.dart';
import 'package:pos/Model/DebtModel.dart';
import 'package:pos/View/Widgets/DebtCard.dart';
import 'package:pos/View/Widgets/DebtFormDialog.dart';
import 'package:pos/View/Widgets/DebtStatsWidget.dart';
import 'package:pos/View/Widgets/DebtPaymentDialog.dart';
import 'package:pos/View/style/app_colors.dart';
import 'package:smart_sizer/smart_sizer.dart';

/// شاشة إدارة الديون والحسابات
class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);

    // تحميل البيانات عند بدء الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DebtProvider>();
      provider.refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      final provider = context.read<DebtProvider>();
      if (!provider.isLoading && provider.hasMoreData) {
        provider.loadDebts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إدارة الديون والحسابات',
          style: TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.bold,
            fontSize: context.getFontSize(8),
          ),
        ),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textMain,
        elevation: 2,
        shadowColor: AppColors.shadow,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.textMain,
          indicatorWeight: 3,
          labelColor: AppColors.textMain,
          unselectedLabelColor: AppColors.textMain,
          labelStyle: TextStyle(
            fontSize: context.getFontSize(8),
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: context.getFontSize(8),
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.account_balance_wallet),
              text: 'الديون النشطة',
            ),
            Tab(icon: Icon(Icons.archive), text: 'الأرشيف'),
            Tab(icon: Icon(Icons.analytics), text: 'الإحصائيات'),
          ],
        ),
      ),
      backgroundColor: AppColors.background,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveDebtsTab(),
          _buildArchivedDebtsTab(),
          const DebtStatsWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDebtDialog,
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textMain,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: Text(
          'دين جديد',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: context.getFontSize(8),
          ),
        ),
      ),
    );
  }

  /// بناء شريط البحث والفلاتر
  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.all(context.getWidth(4)),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          bottom: BorderSide(
            color: AppColors.accent,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // شريط البحث
          TextField(
            controller: _searchController,
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: context.getFontSize(8),
            ),
            decoration: InputDecoration(
              hintText: 'البحث بالاسم أو رقم الهاتف...',
              hintStyle: TextStyle(
                color: AppColors.textMain,
                fontSize: context.getFontSize(8),
              ),
              prefixIcon: Icon(Icons.search, color: AppColors.accent),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: AppColors.textMain,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        context.read<DebtProvider>().setSearchQuery('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.accent,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.accent,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.accent, width: 2),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
            onChanged: (value) {
              context.read<DebtProvider>().setSearchQuery(value);
            },
          ),

          SizedBox(height: context.getHeight(3)),

          // فلاتر سريعة
          Consumer<DebtProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      'الكل',
                      provider.selectedPartyType.isEmpty &&
                          provider.selectedStatus.isEmpty,
                      () => provider.clearFilters(),
                    ),
                    SizedBox(width: context.getWidth(2)),
                    _buildFilterChip(
                      'العملاء',
                      provider.selectedPartyType == 'customer',
                      () => provider.setPartyTypeFilter(
                        provider.selectedPartyType == 'customer'
                            ? ''
                            : 'customer',
                      ),
                    ),
                    SizedBox(width: context.getWidth(2)),
                    _buildFilterChip(
                      'الموردين',
                      provider.selectedPartyType == 'supplier',
                      () => provider.setPartyTypeFilter(
                        provider.selectedPartyType == 'supplier'
                            ? ''
                            : 'supplier',
                      ),
                    ),
                    SizedBox(width: context.getWidth(2)),
                    _buildFilterChip(
                      'غير مدفوع',
                      provider.selectedStatus == 'unpaid',
                      () => provider.setStatusFilter(
                        provider.selectedStatus == 'unpaid' ? '' : 'unpaid',
                      ),
                    ),
                    SizedBox(width: context.getWidth(2)),
                    _buildFilterChip(
                      'مدفوع جزئياً',
                      provider.selectedStatus == 'partiallyPaid',
                      () => provider.setStatusFilter(
                        provider.selectedStatus == 'partiallyPaid'
                            ? ''
                            : 'partiallyPaid',
                      ),
                    ),
                    SizedBox(width: context.getWidth(2)),
                    _buildFilterChip(
                      'مدفوع',
                      provider.selectedStatus == 'paid',
                      () => provider.setStatusFilter(
                        provider.selectedStatus == 'paid' ? '' : 'paid',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// بناء رقاقة الفلتر
  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: context.getWidth(3),
          vertical: context.getWidth(2),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : AppColors.accent,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.textMain
                : AppColors.textMain,
            fontSize: context.getFontSize(8),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// بناء تبويب الديون النشطة
  Widget _buildActiveDebtsTab() {
    return Consumer<DebtProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.debts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(context.getWidth(6)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(context.getWidth(4)),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: context.getWidth(20),
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: context.getWidth(4)),
                  Text(
                    provider.errorMessage!,
                    style: TextStyle(
                      fontSize: context.getFontSize(8),
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: context.getWidth(6)),
                  ElevatedButton.icon(
                    onPressed: () => provider.refresh(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.textMain,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.getWidth(6),
                        vertical: context.getWidth(3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      'إعادة المحاولة',
                      style: TextStyle(
                        fontSize: context.getFontSize(8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.debts.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(context.getWidth(6)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(context.getWidth(6)),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: context.getWidth(14),
                      color: AppColors.accent,
                    ),
                  ),
                  SizedBox(height: context.getWidth(4)),
                  Text(
                    'لا توجد ديون',
                    style: TextStyle(
                      fontSize: context.getFontSize(8),
                      color: AppColors.textMain,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: context.getWidth(2)),
                  Text(
                    'اضغط على زر "دين جديد" لإضافة دين جديد',
                    style: TextStyle(
                      fontSize: context.getFontSize(8),
                      color: AppColors.textMain,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            _buildSearchAndFilters(),
            Expanded(
              flex: 2,
              // height: context.getHeight(275),
              child: RefreshIndicator(
                onRefresh: () => provider.refresh(),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(context.getWidth(4)),
                  itemCount:
                      provider.debts.length + (provider.hasMoreData ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.debts.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final debt = provider.debts[index];
                    return DebtCard(
                      debt: debt,
                      onEdit: () => _showEditDebtDialog(debt),
                      onDelete: () => _showDeleteConfirmation(debt),
                      onArchive: () => _showArchiveConfirmation(debt),
                      onAddPayment: () => _showAddPaymentDialog(debt),
                      onViewTransactions: () => _showTransactionsDialog(debt),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// بناء تبويب الديون المؤرشفة
  Widget _buildArchivedDebtsTab() {
    return Consumer<DebtProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.archivedDebts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.archivedDebts.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(context.getWidth(6)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(context.getWidth(6)),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.archive_outlined,
                      size: context.getWidth(20),
                      color: AppColors.accent,
                    ),
                  ),
                  SizedBox(height: context.getWidth(4)),
                  Text(
                    'لا توجد ديون مؤرشفة',
                    style: TextStyle(
                      fontSize: context.getFontSize(8),
                      color: AppColors.textMain,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: context.getWidth(2)),
                  Text(
                    'الديون المؤرشفة ستظهر هنا',
                    style: TextStyle(
                      fontSize: context.getFontSize(8),
                      color: AppColors.textMain,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadArchivedDebts(),
          child: ListView.builder(
            padding: EdgeInsets.all(context.getWidth(4)),
            itemCount: provider.archivedDebts.length,
            itemBuilder: (context, index) {
              final debt = provider.archivedDebts[index];
              return DebtCard(
                debt: debt,
                onEdit: () => _showEditDebtDialog(debt),
                onDelete: () => _showDeleteConfirmation(debt),
                onArchive: () => _showUnarchiveConfirmation(debt),
                onAddPayment: debt.status != 'paid'
                    ? () => _showAddPaymentDialog(debt)
                    : null,
                onViewTransactions: () => _showTransactionsDialog(debt),
                isArchived: true,
              );
            },
          ),
        );
      },
    );
  }

  /// عرض حوار إضافة دين جديد
  void _showAddDebtDialog() {
    showDialog(
      context: context,
      builder: (context) => DebtFormDialog(
        title: 'إضافة دين جديد',
        onSave: (debt) async {
          final provider = context.read<DebtProvider>();
          final success = await provider.addDebt(debt);
          if (success) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('تم إضافة الدين بنجاح'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.errorMessage ?? 'فشل في إضافة الدين'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  /// عرض حوار تعديل دين
  void _showEditDebtDialog(DebtModel debt) {
    showDialog(
      context: context,
      builder: (context) => DebtFormDialog(
        title: 'تعديل الدين',
        debt: debt,
        onSave: (updatedDebt) async {
          final provider = context.read<DebtProvider>();
          final success = await provider.updateDebt(updatedDebt);
          if (success) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تحديث الدين بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.errorMessage ?? 'فشل في تحديث الدين'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  /// عرض تأكيد الحذف
  void _showDeleteConfirmation(DebtModel debt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'تأكيد الحذف',
          style: TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف دين ${debt.partyName}؟',
          style: TextStyle(color: AppColors.textMain),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textMain.withOpacity(0.7),
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = context.read<DebtProvider>();
              final success = await provider.deleteDebt(debt.id!);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('تم حذف الدين بنجاح'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.errorMessage ?? 'فشل في حذف الدين'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  /// عرض تأكيد الأرشفة
  void _showArchiveConfirmation(DebtModel debt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الأرشفة'),
        content: Text('هل أنت متأكد من أرشفة دين ${debt.partyName}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = context.read<DebtProvider>();
              final success = await provider.archiveDebt(debt.id!, true);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم أرشفة الدين بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      provider.errorMessage ?? 'فشل في أرشفة الدين',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('أرشفة'),
          ),
        ],
      ),
    );
  }

  /// عرض تأكيد إلغاء الأرشفة
  void _showUnarchiveConfirmation(DebtModel debt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد إلغاء الأرشفة'),
        content: Text('هل أنت متأكد من إلغاء أرشفة دين ${debt.partyName}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = context.read<DebtProvider>();
              final success = await provider.archiveDebt(debt.id!, false);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إلغاء أرشفة الدين بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      provider.errorMessage ?? 'فشل في إلغاء أرشفة الدين',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('إلغاء الأرشفة'),
          ),
        ],
      ),
    );
  }

  /// عرض حوار إضافة دفعة
  void _showAddPaymentDialog(DebtModel debt) {
    showDialog(
      context: context,
      builder: (context) => DebtPaymentDialog(
        title: 'إضافة دفعة',
        maxAmount: debt.remainingAmount,
        currency: 'د.ع',
        onSave: (amount, notes) async {
          final provider = context.read<DebtProvider>();
          final success = await provider.addPayment(
            debt.id!,
            amount,
            notes: notes,
          );
          if (success) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إضافة الدفعة بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.errorMessage ?? 'فشل في إضافة الدفعة'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  /// عرض حوار معاملات الدين
  void _showTransactionsDialog(DebtModel debt) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: context.getWidth(90),
          height: context.getHeight(70),
          padding: EdgeInsets.all(context.getWidth(6)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'معاملات الدين - ${debt.partyName}',
                      style: TextStyle(
                        fontSize: context.getFontSize(18),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: AppColors.textMain,
                    ),
                  ),
                ],
              ),

              SizedBox(height: context.getWidth(4)),

              // قائمة المعاملات
              Expanded(
                child: Consumer<DebtProvider>(
                  builder: (context, provider, child) {
                    // تحميل المعاملات عند فتح الحوار
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      provider.loadDebtTransactions(debt.id!);
                    });

                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (provider.debtTransactions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: context.getWidth(15),
                              color: AppColors.accent,
                            ),
                            SizedBox(height: context.getWidth(3)),
                            Text(
                              'لا توجد معاملات لهذا الدين',
                              style: TextStyle(
                                color: AppColors.textMain.withOpacity(0.7),
                                fontSize: context.getFontSize(14),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: provider.debtTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = provider.debtTransactions[index];
                        return Card(
                          color: AppColors.background,
                          elevation: 2,
                          margin: EdgeInsets.only(bottom: context.getWidth(2)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.withOpacity(0.1),
                              child: Icon(
                                Icons.payment,
                                color: Colors.green[700],
                              ),
                            ),
                            title: Text(
                              transaction.formattedAmount,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMain,
                                fontSize: context.getFontSize(14),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'التاريخ: ${transaction.formattedDate}',
                                  style: TextStyle(
                                    color: AppColors.textMain.withOpacity(0.7),
                                    fontSize: context.getFontSize(12),
                                  ),
                                ),
                                if (transaction.notes != null)
                                  Text(
                                    'ملاحظات: ${transaction.notes}',
                                    style: TextStyle(
                                      color: AppColors.textMain.withOpacity(
                                        0.7,
                                      ),
                                      fontSize: context.getFontSize(12),
                                    ),
                                  ),
                              ],
                            ),
                            isThreeLine: transaction.notes != null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
