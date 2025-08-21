/// نموذج المنتج - Product Model
/// يحتوي على جميع خصائص المنتج وطرق التحويل
class ProductModel {
  final int? id;
  final String name;
  final String code;
  final double salePrice;
  final double buyPrice;
  final int quantity;
  final String company;
  final String date;

  const ProductModel({
    this.id,
    required this.name,
    required this.code,
    required this.salePrice,
    required this.buyPrice,
    required this.quantity,
    required this.company,
    required this.date,
  });

  /// إنشاء منتج من Map (من قاعدة البيانات)
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['ID'] as int?,
      name: map['Name'] as String? ?? '',
      code: map['Code'] as String? ?? '',
      salePrice: _parseDouble(map['Sale']),
      buyPrice: _parseDouble(map['Buy']),
      quantity: _parseInt(map['Quantity']),
      company: map['Company'] as String? ?? '',
      date: map['Date'] as String? ?? '',
    );
  }

  /// تحويل المنتج إلى Map (لقاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'ID': id,
      'Name': name,
      'Code': code,
      'Sale': salePrice.toString(),
      'Buy': buyPrice.toString(),
      'Quantity': quantity.toString(),
      'Company': company,
      'Date': date,
    };
  }

  /// إنشاء نسخة محدثة من المنتج
  ProductModel copyWith({
    int? id,
    String? name,
    String? code,
    double? salePrice,
    double? buyPrice,
    int? quantity,
    String? company,
    String? date,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      salePrice: salePrice ?? this.salePrice,
      buyPrice: buyPrice ?? this.buyPrice,
      quantity: quantity ?? this.quantity,
      company: company ?? this.company,
      date: date ?? this.date,
    );
  }

  /// حساب الربح للوحدة الواحدة
  double get profitPerUnit => salePrice - buyPrice;

  /// حساب إجمالي قيمة المخزون (بسعر الشراء)
  double get totalBuyValue => buyPrice * quantity;

  /// حساب إجمالي قيمة المخزون (بسعر البيع)
  double get totalSaleValue => salePrice * quantity;

  /// حساب إجمالي الربح المتوقع
  double get totalProfit => profitPerUnit * quantity;

  /// التحقق من انخفاض المخزون
  bool get isLowStock => quantity < 10;

  /// التحقق من نفاد المخزون
  bool get isOutOfStock => quantity <= 0;

  /// التحقق من صحة البيانات
  bool get isValid {
    return name.isNotEmpty &&
        code.isNotEmpty &&
        salePrice > 0 &&
        buyPrice > 0 &&
        quantity >= 0;
  }

  /// تحويل إلى نص للعرض
  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, code: $code, salePrice: $salePrice, buyPrice: $buyPrice, quantity: $quantity, company: $company, date: $date)';
  }

  /// مقارنة المنتجات
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel &&
        other.id == id &&
        other.name == name &&
        other.code == code &&
        other.salePrice == salePrice &&
        other.buyPrice == buyPrice &&
        other.quantity == quantity &&
        other.company == company &&
        other.date == date;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      code,
      salePrice,
      buyPrice,
      quantity,
      company,
      date,
    );
  }

  /// دوال مساعدة لتحويل البيانات
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // إزالة الأحرف غير الرقمية والاحتفاظ بالأرقام والنقطة العشرية
      final cleanValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleanValue) ?? 0.0;
    }
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(cleanValue) ?? 0;
    }
    return 0;
  }
}

/// نموذج إحصائيات المخزن
class InventoryStats {
  final int totalProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final double totalInventoryValue;
  final double totalProfitPotential;

  const InventoryStats({
    required this.totalProducts,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.totalInventoryValue,
    required this.totalProfitPotential,
  });

  /// إنشاء إحصائيات من قائمة المنتجات
  factory InventoryStats.fromProducts(List<ProductModel> products) {
    int lowStock = 0;
    int outOfStock = 0;
    double totalValue = 0.0;
    double totalProfit = 0.0;

    for (final product in products) {
      if (product.isLowStock) lowStock++;
      if (product.isOutOfStock) outOfStock++;
      totalValue += product.totalBuyValue;
      totalProfit += product.totalProfit;
    }

    return InventoryStats(
      totalProducts: products.length,
      lowStockProducts: lowStock,
      outOfStockProducts: outOfStock,
      totalInventoryValue: totalValue,
      totalProfitPotential: totalProfit,
    );
  }
}
