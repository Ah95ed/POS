/// نموذج المنتج - Product Model
/// يحتوي على جميع خصائص المنتج وطرق التحويل
class ProductModel {
  final int? id;
  final String name;
  final String code; // باركود / كود SKU
  final double salePrice; // سعر البيع
  final double buyPrice; // سعر الشراء
  final int quantity; // الكمية المتوفرة
  final String company;
  final String date;
  final DateTime? expiryDate; // تاريخ انتهاء الصلاحية
  final String description; // وصف المنتج
  final bool isArchived; // للحذف الناعم (soft delete)
  final int lowStockThreshold; // حد التنبيه لانخفاض المخزون

  const ProductModel({
    this.id,
    required this.name,
    required this.code,
    required this.salePrice,
    required this.buyPrice,
    required this.quantity,
    required this.company,
    required this.date,
    this.expiryDate,
    this.description = '',
    this.isArchived = false,
    this.lowStockThreshold = 5,
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
      expiryDate: map['ExpiryDate'] != null
          ? DateTime.tryParse(map['ExpiryDate'] as String)
          : null,
      description: map['Description'] as String? ?? '',
      isArchived: map['IsArchived'] == 1 || map['IsArchived'] == true,
      lowStockThreshold: _parseInt(map['LowStockThreshold']) == 0
          ? 5
          : _parseInt(map['LowStockThreshold']),
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
      'ExpiryDate': expiryDate?.toIso8601String(),
      'Description': description,
      'IsArchived': isArchived ? 1 : 0,
      'LowStockThreshold': lowStockThreshold,
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
    DateTime? expiryDate,
    String? description,
    bool? isArchived,
    int? lowStockThreshold,
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
      expiryDate: expiryDate ?? this.expiryDate,
      description: description ?? this.description,
      isArchived: isArchived ?? this.isArchived,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
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
  bool get isLowStock => quantity <= lowStockThreshold && quantity > 0;

  /// التحقق من نفاد المخزون
  bool get isOutOfStock => quantity <= 0;

  /// التحقق من قرب انتهاء الصلاحية (خلال 30 يوم)
  bool get isNearExpiry {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final difference = expiryDate!.difference(now).inDays;
    return difference <= 30 && difference >= 0;
  }

  /// التحقق من انتهاء الصلاحية
  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  /// الحصول على عدد الأيام المتبقية للانتهاء
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    final difference = expiryDate!.difference(DateTime.now()).inDays;
    return difference >= 0 ? difference : 0;
  }

  /// التحقق من صحة البيانات
  bool get isValid {
    return name.isNotEmpty &&
        code.isNotEmpty &&
        salePrice > 0 &&
        buyPrice > 0 &&
        quantity >= 0;
  }

  /// التحقق من حالة المنتج النشط
  bool get isActive => !isArchived;

  /// حساب هامش الربح
  double get profitMargin => salePrice - buyPrice;

  /// حساب إجمالي قيمة المخزون
  double get totalStockValue => quantity * buyPrice;

  /// الحصول على الباركود
  String get barcode => code;

  /// الحصول على الصورة (افتراضية)
  String? get image => null;

  /// تنسيق تاريخ انتهاء الصلاحية
  String get formattedExpiryDate {
    if (expiryDate == null) return 'غير محدد';
    return '${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}';
  }

  /// تحويل إلى نص للعرض
  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, code: $code, salePrice: $salePrice, buyPrice: $buyPrice, quantity: $quantity, company: $company, date: $date, expiryDate: $expiryDate, description: $description, isArchived: $isArchived, lowStockThreshold: $lowStockThreshold)';
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
        other.date == date &&
        other.expiryDate == expiryDate &&
        other.description == description &&
        other.isArchived == isArchived &&
        other.lowStockThreshold == lowStockThreshold;
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
      expiryDate,
      description,
      isArchived,
      lowStockThreshold,
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
  final int nearExpiryProducts;
  final int expiredProducts;
  final int archivedProducts;
  final double totalInventoryValue;
  final double totalProfitPotential;
  final double totalSaleValue;

  const InventoryStats({
    required this.totalProducts,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.nearExpiryProducts,
    required this.expiredProducts,
    required this.archivedProducts,
    required this.totalInventoryValue,
    required this.totalProfitPotential,
    required this.totalSaleValue,
  });

  /// إنشاء إحصائيات من قائمة المنتجات
  factory InventoryStats.fromProducts(List<ProductModel> products) {
    int lowStock = 0;
    int outOfStock = 0;
    int nearExpiry = 0;
    int expired = 0;
    int archived = 0;
    double totalBuyValue = 0.0;
    double totalProfit = 0.0;
    double totalSaleValue = 0.0;

    for (final product in products) {
      if (product.isArchived) {
        archived++;
        continue; // لا نحسب المنتجات المؤرشفة في الإحصائيات الأخرى
      }

      if (product.isLowStock) lowStock++;
      if (product.isOutOfStock) outOfStock++;
      if (product.isNearExpiry) nearExpiry++;
      if (product.isExpired) expired++;

      totalBuyValue += product.totalBuyValue;
      totalProfit += product.totalProfit;
      totalSaleValue += product.totalSaleValue;
    }

    return InventoryStats(
      totalProducts: products.where((p) => !p.isArchived).length,
      lowStockProducts: lowStock,
      outOfStockProducts: outOfStock,
      nearExpiryProducts: nearExpiry,
      expiredProducts: expired,
      archivedProducts: archived,
      totalInventoryValue: totalBuyValue,
      totalProfitPotential: totalProfit,
      totalSaleValue: totalSaleValue,
    );
  }
}
