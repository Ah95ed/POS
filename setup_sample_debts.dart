import 'package:pos/Helper/DataBase/POSDatabase.dart';
import 'package:pos/Model/DebtModel.dart';
import 'package:pos/Repository/DebtRepository.dart';

/// إعداد بيانات تجريبية لنظام الديون
/// يمكن تشغيل هذا الملف لإضافة بيانات تجريبية للاختبار
Future<void> main() async {
  print('🚀 بدء إعداد البيانات التجريبية...\n');

  try {
    // تهيئة قاعدة البيانات
    await POSDatabase.database;
    print('✅ تم تهيئة قاعدة البيانات');

    final repository = DebtRepository();

    // إنشاء ديون تجريبية للعملاء
    final customerDebts = [
      DebtModel(
        partyId: 1,
        partyType: 'customer',
        partyName: 'أحمد محمد علي',
        partyPhone: '07901234567',
        amount: 150000,
        paidAmount: 50000,
        remainingAmount: 100000,
        dueDate: DateTime.now().add(const Duration(days: 15)),
        status: 'partiallyPaid',
        archived: false,
        notes: 'دين على بضاعة مباعة - دفعة أولى مستلمة',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
      DebtModel(
        partyId: 2,
        partyType: 'customer',
        partyName: 'فاطمة حسن',
        partyPhone: '07912345678',
        amount: 75000,
        paidAmount: 0,
        remainingAmount: 75000,
        dueDate: DateTime.now().add(const Duration(days: 7)),
        status: 'unpaid',
        archived: false,
        notes: 'فاتورة رقم 1001',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
      ),
      DebtModel(
        partyId: 3,
        partyType: 'customer',
        partyName: 'محمد عبدالله',
        partyPhone: '07923456789',
        amount: 200000,
        paidAmount: 200000,
        remainingAmount: 0,
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
        status: 'paid',
        archived: false,
        notes: 'تم السداد كاملاً',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    // إنشاء ديون تجريبية للموردين
    final supplierDebts = [
      DebtModel(
        partyId: 4,
        partyType: 'supplier',
        partyName: 'شركة الأنوار التجارية',
        partyPhone: '07934567890',
        amount: 500000,
        paidAmount: 300000,
        remainingAmount: 200000,
        dueDate: DateTime.now().add(const Duration(days: 30)),
        status: 'partiallyPaid',
        archived: false,
        notes: 'فاتورة شراء بضاعة - دفعة جزئية',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
      ),
      DebtModel(
        partyId: 5,
        partyType: 'supplier',
        partyName: 'مؤسسة النجاح',
        partyPhone: '07945678901',
        amount: 120000,
        paidAmount: 0,
        remainingAmount: 120000,
        dueDate: DateTime.now().add(const Duration(days: 45)),
        status: 'unpaid',
        archived: false,
        notes: 'مستحقات شهر ديسمبر',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
      ),
    ];

    // إضافة الديون إلى قاعدة البيانات
    print('\n📝 إضافة ديون العملاء...');
    for (final debt in customerDebts) {
      final result = await repository.addDebt(debt);
      if (result.isSuccess) {
        print('   ✓ تم إضافة دين: ${debt.partyName} - ${debt.formattedAmount}');
      } else {
        print('   ❌ فشل في إضافة دين: ${debt.partyName} - ${result.error}');
      }
    }

    print('\n🏢 إضافة ديون الموردين...');
    for (final debt in supplierDebts) {
      final result = await repository.addDebt(debt);
      if (result.isSuccess) {
        print('   ✓ تم إضافة دين: ${debt.partyName} - ${debt.formattedAmount}');
      } else {
        print('   ❌ فشل في إضافة دين: ${debt.partyName} - ${result.error}');
      }
    }

    // إضافة بعض المعاملات التجريبية
    print('\n💳 إضافة معاملات تجريبية...');

    // إضافة دفعة على دين أحمد محمد
    final paymentResult1 = await repository.addPayment(
      1,
      25000,
      notes: 'دفعة جزئية إضافية',
    );
    if (paymentResult1.isSuccess) {
      print('   ✓ تم إضافة دفعة: 25000 د.ع لأحمد محمد');
    }

    // إضافة دفعة على دين شركة الأنوار
    final paymentResult2 = await repository.addPayment(
      4,
      100000,
      notes: 'دفعة من الأرباح',
    );
    if (paymentResult2.isSuccess) {
      print('   ✓ تم إضافة دفعة: 100000 د.ع لشركة الأنوار');
    }

    print('\n🎉 تم إعداد البيانات التجريبية بنجاح!');
    print('\nالبيانات المضافة:');
    print('• ${customerDebts.length} ديون عملاء');
    print('• ${supplierDebts.length} ديون موردين');
    print('• 2 معاملة دفع تجريبية');
    print('\nيمكنك الآن تشغيل التطبيق واستكشاف شاشة الديون والحسابات 🚀');
  } catch (e) {
    print('❌ خطأ في إعداد البيانات: $e');
  }
}

/// دالة مساعدة لطباعة ملخص الديون
void printDebtsSummary(List<DebtModel> debts) {
  if (debts.isEmpty) {
    print('لا توجد ديون');
    return;
  }

  double totalAmount = 0;
  double totalPaid = 0;
  double totalRemaining = 0;

  for (final debt in debts) {
    totalAmount += debt.amount;
    totalPaid += debt.paidAmount;
    totalRemaining += debt.remainingAmount;
  }

  print('📊 ملخص الديون:');
  print('   العدد الكلي: ${debts.length}');
  print('   إجمالي المبلغ: ${totalAmount.toStringAsFixed(0)} د.ع');
  print('   إجمالي المدفوع: ${totalPaid.toStringAsFixed(0)} د.ع');
  print('   إجمالي المتبقي: ${totalRemaining.toStringAsFixed(0)} د.ع');
}
