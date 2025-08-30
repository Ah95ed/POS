import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos/Controller/SaleProvider.dart';
import 'package:pos/Model/ProductModel.dart';
import 'package:pos/Helper/Constants/AppConstants.dart';

/// بطاقة منتج محسنة مع تصميم أفضل
class EnhancedProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final bool showAddButton;

  const EnhancedProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap ?? () => _addToCart(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة المنتج مع شارة الحالة
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.blue[50]!, Colors.blue[100]!],
                        ),
                      ),
                      child: _buildDefaultIcon(),
                    ),

                    // شارة الحالة
                    Positioned(top: 8, right: 8, child: _buildStatusBadge()),

                    // زر الإضافة السريعة
                    if (showAddButton)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: _buildQuickAddButton(context),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // معلومات المنتج
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم المنتج
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // كود المنتج
                    Text(
                      'كود: ${product.code}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),

                    const Spacer(),

                    // السعر والكمية
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // السعر
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.formatCurrency(product.salePrice),
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (product.buyPrice < product.salePrice)
                              Text(
                                'ربح: ${AppConstants.formatCurrency(product.profitPerUnit)}',
                                style: TextStyle(
                                  color: Colors.orange[600],
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),

                        // الكمية المتوفرة
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getQuantityColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getQuantityColor(),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${product.quantity}',
                            style: TextStyle(
                              color: _getQuantityColor(),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 40,
        color: Colors.blue[300],
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (product.isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'نفذ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (product.isLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'قليل',
          style: TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildQuickAddButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green[600],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _addToCart(context),
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.add, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  Color _getQuantityColor() {
    if (product.isOutOfStock) {
      return Colors.red;
    } else if (product.isLowStock) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  void _addToCart(BuildContext context) {
    if (product.isOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('المنتج "${product.name}" غير متوفر'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<SaleProvider>().addProductToSale(product);

    // إظهار رسالة تأكيد
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إضافة "${product.name}" للفاتورة'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
