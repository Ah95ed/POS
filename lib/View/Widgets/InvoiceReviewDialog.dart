import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/SaleProvider.dart';
import 'package:pos/Model/SaleModel.dart';
import 'package:pos/Helper/Constants/AppConstants.dart';
import 'package:smart_sizer/smart_sizer.dart';

/// نافذة مراجعة الفاتورة
class InvoiceReviewDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const InvoiceReviewDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: context.screenWidth * 0.85,
        constraints: BoxConstraints(maxHeight: context.screenHeight * 0.8),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContent(context)),
            _buildActions(context),
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
          const Icon(Icons.receipt, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'مراجعة الفاتورة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Consumer<SaleProvider>(
            builder: (context, provider, child) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${provider.itemCount} عنصر',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// بناء محتوى النافذة
  Widget _buildContent(BuildContext context) {
    return Consumer<SaleProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInvoiceItems(provider),
              const SizedBox(height: 16),
              _buildCustomerInfo(provider),
              const SizedBox(height: 16),
              _buildInvoiceSummary(provider),
              const SizedBox(height: 16),
              _buildPaymentInfo(provider),
              if (provider.notes != null && provider.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildNotes(provider),
              ],
            ],
          ),
        );
      },
    );
  }

  /// بناء عناصر الفاتورة
  Widget _buildInvoiceItems(SaleProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'عناصر الفاتورة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${provider.totalQuantity} قطعة',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.currentSaleItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = provider.currentSaleItems[index];
                return _buildItemRow(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// بناء صف العنصر
  Widget _buildItemRow(SaleItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'كود: ${item.productCode}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${item.quantity}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              AppConstants.formatCurrency(item.unitPrice),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              AppConstants.formatCurrency(item.calculateTotal()),
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء معلومات العميل
  Widget _buildCustomerInfo(SaleProvider provider) {
    if (provider.customerName == null && provider.customerPhone == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'معلومات العميل',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.customerName != null)
              _buildInfoRow('الاسم:', provider.customerName!),
            if (provider.customerPhone != null)
              _buildInfoRow('الهاتف:', provider.customerPhone!),
          ],
        ),
      ),
    );
  }

  /// بناء ملخص الفاتورة
  Widget _buildInvoiceSummary(SaleProvider provider) {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'ملخص الفاتورة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('المجموع الفرعي:', provider.subtotal),
            if (provider.discount > 0)
              _buildSummaryRow('الخصم:', provider.discount, isNegative: true),
            _buildSummaryRow(
              'الضريبة (${provider.taxRate}%):',
              provider.taxAmount,
            ),
            const Divider(thickness: 2),
            _buildSummaryRow('الإجمالي:', provider.total, isTotal: true),
          ],
        ),
      ),
    );
  }

  /// بناء معلومات الدفع
  Widget _buildPaymentInfo(SaleProvider provider) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'معلومات الدفع',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('طريقة الدفع:', provider.paymentMethod),
            _buildSummaryRow('المبلغ المدفوع:', provider.paidAmount),
            if (provider.changeAmount > 0)
              _buildSummaryRow(
                'الباقي:',
                provider.changeAmount,
                isPositive: true,
              ),
          ],
        ),
      ),
    );
  }

  /// بناء الملاحظات
  Widget _buildNotes(SaleProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'ملاحظات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Text(
                provider.notes!,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء صف المعلومات
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  /// بناء صف الملخص
  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isNegative = false,
    bool isPositive = false,
  }) {
    Color? color;
    if (isTotal) color = Colors.green[700];
    if (isNegative) color = Colors.red[700];
    if (isPositive) color = Colors.blue[700];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: color ?? Colors.black87,
            ),
          ),
          Text(
            isNegative
                ? '- ${AppConstants.formatCurrency(amount)}'
                : AppConstants.formatCurrency(amount),
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء أزرار العمليات
  Widget _buildActions(BuildContext context) {
    return Container(
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
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.grey[400]!),
              ),
              child: const Text('تعديل', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle),
                  const SizedBox(width: 8),
                  Consumer<SaleProvider>(
                    builder: (context, provider, child) {
                      return Text(
                        'تأكيد الدفع (${AppConstants.formatCurrency(provider.total)})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
