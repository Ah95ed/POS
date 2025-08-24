import 'package:flutter/material.dart';
import 'package:pos/Model/DebtModel.dart';
import 'package:pos/Repository/DebtRepository.dart';
import 'package:pos/Controller/DebtProvider.dart';

/// ملف اختبار بسيط لنظام الديون
/// يمكن تشغيله للتأكد من عمل النظام بشكل صحيح
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🧪 بدء اختبار نظام الديون...\n');

  // اختبار إنشاء نموذج دين
  await testDebtModel();

  // اختبار مزود الديون
  await testDebtProvider();

  print('\n✅ تم الانتهاء من جميع الاختبارات بنجاح!');
}

/// اختبار نموذج الدين
Future<void> testDebtModel() async {
  print('📋 اختبار نموذج الدين...');

  // إنشاء دين جديد
  final debt = DebtModel(
    id: 1,
    partyId: 1,
    partyType: 'customer',
    partyName: 'أحمد محمد',
    partyPhone: '07901234567',
    amount: 100000,
    paidAmount: 30000,
    remainingAmount: 70000,
    dueDate: DateTime.now().add(const Duration(days: 30)),
    status: 'partiallyPaid',
    archived: false,
    notes: 'دين على بضاعة مباعة',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  // اختبار التحقق من صحة البيانات
  assert(debt.isValid, 'فشل في التحقق من صحة البيانات');
  print('   ✓ التحقق من صحة البيانات');

  // اختبار تنسيق العملة
  assert(debt.formattedAmount == '100000 د.ع', 'فشل في تنسيق المبلغ');
  print('   ✓ تنسيق العملة');

  // اختبار حالة الدين
  assert(debt.statusText == 'مدفوع جزئياً', 'فشل في ترجمة حالة الدين');
  print('   ✓ ترجمة حالة الدين');

  // اختبار تحويل إلى Map
  final map = debt.toMap();
  assert(map['party_name'] == 'أحمد محمد', 'فشل في تحويل إلى Map');
  print('   ✓ تحويل إلى Map');

  // اختبار إنشاء من Map
  final debtFromMap = DebtModel.fromMap(map);
  assert(debtFromMap.partyName == debt.partyName, 'فشل في الإنشاء من Map');
  print('   ✓ إنشاء من Map');

  print('✅ نجح اختبار نموذج الدين\n');
}

/// اختبار مزود الديون
Future<void> testDebtProvider() async {
  print('🎛️ اختبار مزود الديون...');

  final provider = DebtProvider();

  // اختبار الحالة الأولية
  assert(provider.debts.isEmpty, 'قائمة الديون يجب أن تكون فارغة في البداية');
  assert(!provider.isLoading, 'حالة التحميل يجب أن تكون false في البداية');
  assert(
    provider.errorMessage == null,
    'رسالة الخطأ يجب أن تكون null في البداية',
  );
  print('   ✓ الحالة الأولية صحيحة');

  // اختبار تغيير الفلاتر
  provider.setPartyTypeFilter('customer');
  assert(
    provider.selectedPartyType == 'customer',
    'فشل في تعيين فلتر نوع الطرف',
  );
  print('   ✓ تعيين الفلاتر');

  provider.setStatusFilter('paid');
  assert(provider.selectedStatus == 'paid', 'فشل في تعيين فلتر الحالة');
  print('   ✓ تعيين فلتر الحالة');

  // اختبار البحث
  provider.setSearchQuery('أحمد');
  assert(provider.searchQuery == 'أحمد', 'فشل في تعيين استعلام البحث');
  print('   ✓ تعيين استعلام البحث');

  print('✅ نجح اختبار مزود الديون\n');
}

/// اختبار معاملة الدين
void testDebtTransaction() {
  print('💳 اختبار معاملة الدين...');

  final transaction = DebtTransactionModel(
    id: 1,
    debtId: 1,
    amountPaid: 25000,
    date: DateTime.now(),
    notes: 'دفعة جزئية',
    createdAt: DateTime.now(),
  );

  // اختبار تنسيق المبلغ
  assert(
    transaction.formattedAmount == '25000 د.ع',
    'فشل في تنسيق مبلغ المعاملة',
  );
  print('   ✓ تنسيق مبلغ المعاملة');

  // اختبار تحويل إلى Map
  final map = transaction.toMap();
  assert(map['amount_paid'] == 25000, 'فشل في تحويل معاملة إلى Map');
  print('   ✓ تحويل معاملة إلى Map');

  print('✅ نجح اختبار معاملة الدين\n');
}
