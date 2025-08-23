import 'dart:io';
import 'package:path/path.dart';
import 'package:pos/Helper/Log/LogApp.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// قاعدة بيانات نقطة البيع الشاملة
class POSDatabase {
  static const version = 5;
  static const dbName = 'POS_System.db';
  static Database? _database;

  // جداول قاعدة البيانات
  static const String itemsTable = 'Items';
  static const String salesTable = 'Sales';
  static const String saleItemsTable = 'SaleItems';
  static const String customersTable = 'Customers';
  static const String paymentMethodsTable = 'PaymentMethods';
  static const String categoriesTable = 'Categories';
  static const String invoicesTable = 'Invoices';
  static const String invoiceItemsTable = 'InvoiceItems';

  // حقول جدول المنتجات (Items)
  static const String itemId = 'id';
  static const String itemName = 'name';
  static const String itemCode = 'code';
  static const String itemSalePrice = 'sale_price';
  static const String itemBuyPrice = 'buy_price';
  static const String itemQuantity = 'quantity';
  static const String itemCompany = 'company';
  static const String itemCategoryId = 'category_id';
  static const String itemBarcode = 'barcode';
  static const String itemImage = 'image';
  static const String itemDescription = 'description';
  static const String itemMinStock = 'min_stock';
  static const String itemIsActive = 'is_active';
  static const String itemIsArchived = 'is_archived';
  static const String itemCreatedAt = 'created_at';
  static const String itemUpdatedAt = 'updated_at';

  // حقول جدول المبيعات (Sales)
  static const String saleId = 'id';
  static const String saleInvoiceNumber = 'invoice_number';
  static const String saleCustomerId = 'customer_id';
  static const String saleSubtotal = 'subtotal';
  static const String saleTax = 'tax';
  static const String saleDiscount = 'discount';
  static const String saleTotal = 'total';
  static const String salePaidAmount = 'paid_amount';
  static const String saleChangeAmount = 'change_amount';
  static const String salePaymentMethod = 'payment_method';
  static const String saleStatus = 'status';
  static const String saleNotes = 'notes';
  static const String saleCashierId = 'cashier_id';
  static const String saleCreatedAt = 'created_at';

  // حقول جدول عناصر المبيعات (SaleItems)
  static const String saleItemId = 'id';
  static const String saleItemSaleId = 'sale_id';
  static const String saleItemProductId = 'product_id';
  static const String saleItemProductName = 'product_name';
  static const String saleItemProductCode = 'product_code';
  static const String saleItemQuantity = 'quantity';
  static const String saleItemUnitPrice = 'unit_price';
  static const String saleItemDiscount = 'discount';
  static const String saleItemTotal = 'total';

  // حقول جدول العملاء (Customers)
  static const String customerId = 'id';
  static const String customerName = 'name';
  static const String customerPhone = 'phone';
  static const String customerEmail = 'email';
  static const String customerAddress = 'address';
  static const String customerPoints = 'points';
  static const String customerTotalPurchases = 'total_purchases';
  static const String customerIsVip = 'is_vip';
  static const String customerCreatedAt = 'created_at';

  // حقول جدول طرق الدفع (PaymentMethods)
  static const String paymentId = 'id';
  static const String paymentName = 'name';
  static const String paymentNameAr = 'name_ar';
  static const String paymentIsActive = 'is_active';
  static const String paymentIcon = 'icon';

  // حقول جدول الفئات (Categories)
  static const String categoryId = 'id';
  static const String categoryName = 'name';
  static const String categoryNameAr = 'name_ar';
  static const String categoryDescription = 'description';
  static const String categoryIcon = 'icon';
  static const String categoryColor = 'color';
  static const String categoryIsActive = 'is_active';

  // حقول جدول الفواتير (Invoices)
  static const String invoiceId = 'id';
  static const String invoiceCustomerId = 'customer_id';
  static const String invoiceNumber = 'invoice_number';
  static const String invoiceDate = 'date';
  static const String invoiceTotalAmount = 'total_amount';
  static const String invoiceStatus = 'status';
  static const String invoiceCustomerName = 'customer_name';
  static const String invoiceCustomerPhone = 'customer_phone';
  static const String invoiceCreatedAt = 'created_at';
  static const String invoiceUpdatedAt = 'updated_at';
  static const String invoiceNotes = 'notes';

  // حقول جدول عناصر الفواتير (InvoiceItems)
  static const String invoiceItemId = 'id';
  static const String invoiceItemInvoiceId = 'invoice_id';
  static const String invoiceItemProductId = 'product_id';
  static const String invoiceItemProductName = 'product_name';
  static const String invoiceItemProductCode = 'product_code';
  static const String invoiceItemQuantity = 'quantity';
  static const String invoiceItemPrice = 'price';
  static const String invoiceItemTotal = 'total';

  POSDatabase() {
    database;
  }

  static Future<Database?> get database async {
    if (_database != null) {
      return _database;
    } else if (Platform.isWindows || Platform.isLinux) {
      return await _initWindowsDatabase();
    } else {
      return await _initMobileDatabase();
    }
  }

  /// تهيئة قاعدة البيانات للهواتف
  static Future<Database> _initMobileDatabase() async {
    var databasePath = await getDatabasesPath();
    String path = join(databasePath, dbName);

    return await openDatabase(
      path,
      version: version,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  /// تهيئة قاعدة البيانات لسطح المكتب
  static Future<Database?> _initWindowsDatabase() async {
    final path = await getDatabasesPath();
    final pathFile = join(path, dbName);

    return await databaseFactoryFfi.openDatabase(
      pathFile,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: _createTables,
        onUpgrade: _upgradeTables,
      ),
    );
  }

  /// إنشاء الجداول
  static Future<void> _createTables(Database db, int version) async {
    // جدول المنتجات
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $itemsTable (
        $itemId INTEGER PRIMARY KEY AUTOINCREMENT,
        $itemName TEXT NOT NULL,
        $itemCode TEXT UNIQUE NOT NULL,
        $itemSalePrice REAL NOT NULL DEFAULT 0,
        $itemBuyPrice REAL NOT NULL DEFAULT 0,
        $itemQuantity INTEGER NOT NULL DEFAULT 0,
        $itemCompany TEXT,
        $itemCategoryId INTEGER,
        $itemBarcode TEXT,
        $itemImage TEXT,
        $itemDescription TEXT,
        $itemMinStock INTEGER DEFAULT 10,
        $itemIsActive INTEGER DEFAULT 1,
        $itemIsArchived INTEGER DEFAULT 0,
        $itemCreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        $itemUpdatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY ($itemCategoryId) REFERENCES $categoriesTable ($categoryId)
      )
    ''');

    // جدول المبيعات
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $salesTable (
        $saleId INTEGER PRIMARY KEY AUTOINCREMENT,
        $saleInvoiceNumber TEXT UNIQUE NOT NULL,
        $saleCustomerId INTEGER,
        $saleSubtotal REAL NOT NULL DEFAULT 0,
        $saleTax REAL NOT NULL DEFAULT 0,
        $saleDiscount REAL NOT NULL DEFAULT 0,
        $saleTotal REAL NOT NULL DEFAULT 0,
        $salePaidAmount REAL NOT NULL DEFAULT 0,
        $saleChangeAmount REAL NOT NULL DEFAULT 0,
        $salePaymentMethod TEXT NOT NULL DEFAULT 'cash',
        $saleStatus TEXT NOT NULL DEFAULT 'completed',
        $saleNotes TEXT,
        $saleCashierId INTEGER,
        $saleCreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY ($saleCustomerId) REFERENCES $customersTable ($customerId)
      )
    ''');

    // جدول عناصر المبيعات
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $saleItemsTable (
        $saleItemId INTEGER PRIMARY KEY AUTOINCREMENT,
        $saleItemSaleId INTEGER NOT NULL,
        $saleItemProductId INTEGER NOT NULL,
        $saleItemProductName TEXT NOT NULL,
        $saleItemProductCode TEXT NOT NULL,
        $saleItemQuantity INTEGER NOT NULL DEFAULT 1,
        $saleItemUnitPrice REAL NOT NULL DEFAULT 0,
        $saleItemDiscount REAL NOT NULL DEFAULT 0,
        $saleItemTotal REAL NOT NULL DEFAULT 0,
        FOREIGN KEY ($saleItemSaleId) REFERENCES $salesTable ($saleId) ON DELETE CASCADE,
        FOREIGN KEY ($saleItemProductId) REFERENCES $itemsTable ($itemId)
      )
    ''');

    // جدول العملاء
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $customersTable (
        $customerId INTEGER PRIMARY KEY AUTOINCREMENT,
        $customerName TEXT NOT NULL,
        $customerPhone TEXT UNIQUE,
        $customerEmail TEXT,
        $customerAddress TEXT,
        $customerPoints INTEGER DEFAULT 0,
        $customerTotalPurchases REAL DEFAULT 0,
        $customerIsVip INTEGER DEFAULT 0,
        $customerCreatedAt TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // جدول طرق الدفع
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $paymentMethodsTable (
        $paymentId INTEGER PRIMARY KEY AUTOINCREMENT,
        $paymentName TEXT NOT NULL,
        $paymentNameAr TEXT NOT NULL,
        $paymentIsActive INTEGER DEFAULT 1,
        $paymentIcon TEXT
      )
    ''');

    // جدول الفئات
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $categoriesTable (
        $categoryId INTEGER PRIMARY KEY AUTOINCREMENT,
        $categoryName TEXT NOT NULL,
        $categoryNameAr TEXT NOT NULL,
        $categoryDescription TEXT,
        $categoryIcon TEXT,
        $categoryColor TEXT,
        $categoryIsActive INTEGER DEFAULT 1
      )
    ''');

    // جدول الفواتير
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $invoicesTable (
        $invoiceId INTEGER PRIMARY KEY AUTOINCREMENT,
        $invoiceCustomerId INTEGER,
        $invoiceNumber TEXT UNIQUE NOT NULL,
        $invoiceDate TEXT NOT NULL,
        $invoiceTotalAmount REAL NOT NULL DEFAULT 0,
        $invoiceStatus TEXT NOT NULL DEFAULT 'pending',
        $invoiceCustomerName TEXT,
        $invoiceCustomerPhone TEXT,
        $invoiceCreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        $invoiceUpdatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        $invoiceNotes TEXT,
        FOREIGN KEY ($invoiceCustomerId) REFERENCES $customersTable ($customerId)
      )
    ''');

    // جدول عناصر الفواتير
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $invoiceItemsTable (
        $invoiceItemId INTEGER PRIMARY KEY AUTOINCREMENT,
        $invoiceItemInvoiceId INTEGER NOT NULL,
        $invoiceItemProductId INTEGER NOT NULL,
        $invoiceItemProductName TEXT NOT NULL,
        $invoiceItemProductCode TEXT NOT NULL,
        $invoiceItemQuantity INTEGER NOT NULL DEFAULT 1,
        $invoiceItemPrice REAL NOT NULL DEFAULT 0,
        $invoiceItemTotal REAL NOT NULL DEFAULT 0,
        FOREIGN KEY ($invoiceItemInvoiceId) REFERENCES $invoicesTable ($invoiceId) ON DELETE CASCADE,
        FOREIGN KEY ($invoiceItemProductId) REFERENCES $itemsTable ($itemId)
      )
    ''');

    // إدراج البيانات الأولية
    await _insertInitialData(db);
  }

  /// ترقية الجداول
  static Future<void> _upgradeTables(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // إضافة حقول جديدة أو تعديل الجداول
      await db.execute('ALTER TABLE $itemsTable ADD COLUMN $itemBarcode TEXT');
      await db.execute('ALTER TABLE $itemsTable ADD COLUMN $itemImage TEXT');
      await db.execute(
        'ALTER TABLE $itemsTable ADD COLUMN $itemDescription TEXT',
      );
    }

    if (oldVersion < 3) {
      // إضافة حقل الأرشفة
      await db.execute(
        'ALTER TABLE $itemsTable ADD COLUMN $itemIsArchived INTEGER DEFAULT 0',
      );
    }

    if (oldVersion < 4) {
      // إضافة جداول الفواتير
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $invoicesTable (
          $invoiceId INTEGER PRIMARY KEY AUTOINCREMENT,
          $invoiceCustomerId INTEGER,
          $invoiceNumber TEXT UNIQUE NOT NULL,
          $invoiceDate TEXT NOT NULL,
          $invoiceTotalAmount REAL NOT NULL DEFAULT 0,
          $invoiceStatus TEXT NOT NULL DEFAULT 'pending',
          $invoiceCreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
          $invoiceUpdatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
          $invoiceNotes TEXT,
          FOREIGN KEY ($invoiceCustomerId) REFERENCES $customersTable ($customerId)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS $invoiceItemsTable (
          $invoiceItemId INTEGER PRIMARY KEY AUTOINCREMENT,
          $invoiceItemInvoiceId INTEGER NOT NULL,
          $invoiceItemProductId INTEGER NOT NULL,
          $invoiceItemProductName TEXT NOT NULL,
          $invoiceItemProductCode TEXT NOT NULL,
          $invoiceItemQuantity INTEGER NOT NULL DEFAULT 1,
          $invoiceItemPrice REAL NOT NULL DEFAULT 0,
          $invoiceItemTotal REAL NOT NULL DEFAULT 0,
          FOREIGN KEY ($invoiceItemInvoiceId) REFERENCES $invoicesTable ($invoiceId) ON DELETE CASCADE,
          FOREIGN KEY ($invoiceItemProductId) REFERENCES $itemsTable ($itemId)
        )
      ''');
    }

    if (oldVersion < 5) {
      // إضافة حقول العميل إلى جدول الفواتير
      await db.execute(
        'ALTER TABLE $invoicesTable ADD COLUMN $invoiceCustomerName TEXT',
      );
      await db.execute(
        'ALTER TABLE $invoicesTable ADD COLUMN $invoiceCustomerPhone TEXT',
      );
    }
  }

  /// إدراج البيانات الأولية
  static Future<void> _insertInitialData(Database db) async {
    // إدراج طرق الدفع الافتراضية
    await db.insert(paymentMethodsTable, {
      paymentName: 'Cash',
      paymentNameAr: 'نقدي',
      paymentIsActive: 1,
      paymentIcon: 'money',
    });

    await db.insert(paymentMethodsTable, {
      paymentName: 'Credit Card',
      paymentNameAr: 'بطاقة ائتمان',
      paymentIsActive: 1,
      paymentIcon: 'credit_card',
    });

    await db.insert(paymentMethodsTable, {
      paymentName: 'Bank Transfer',
      paymentNameAr: 'تحويل بنكي',
      paymentIsActive: 1,
      paymentIcon: 'account_balance',
    });

    await db.insert(paymentMethodsTable, {
      paymentName: 'Digital Wallet',
      paymentNameAr: 'محفظة إلكترونية',
      paymentIsActive: 1,
      paymentIcon: 'wallet',
    });

    // إدراج الفئات الافتراضية
    await db.insert(categoriesTable, {
      categoryName: 'Electronics',
      categoryNameAr: 'إلكترونيات',
      categoryDescription: 'Electronic devices and accessories',
      categoryIcon: 'devices',
      categoryColor: '#2196F3',
      categoryIsActive: 1,
    });

    await db.insert(categoriesTable, {
      categoryName: 'Clothing',
      categoryNameAr: 'ملابس',
      categoryDescription: 'Clothing and fashion items',
      categoryIcon: 'checkroom',
      categoryColor: '#E91E63',
      categoryIsActive: 1,
    });

    await db.insert(categoriesTable, {
      categoryName: 'Food & Beverages',
      categoryNameAr: 'طعام ومشروبات',
      categoryDescription: 'Food items and beverages',
      categoryIcon: 'restaurant',
      categoryColor: '#FF9800',
      categoryIsActive: 1,
    });

    await db.insert(categoriesTable, {
      categoryName: 'Books',
      categoryNameAr: 'كتب',
      categoryDescription: 'Books and educational materials',
      categoryIcon: 'menu_book',
      categoryColor: '#4CAF50',
      categoryIsActive: 1,
    });

    await db.insert(categoriesTable, {
      categoryName: 'General',
      categoryNameAr: 'عام',
      categoryDescription: 'General items',
      categoryIcon: 'category',
      categoryColor: '#9E9E9E',
      categoryIsActive: 1,
    });

    logInfo('تم إدراج البيانات الأولية بنجاح');
  }

  /// إنشاء رقم فاتورة فريد
  static Future<String> generateInvoiceNumber() async {
    final db = await database;
    final now = DateTime.now();
    final datePrefix =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    // البحث عن آخر فاتورة في نفس اليوم
    final result = await db!.query(
      salesTable,
      where: '$saleInvoiceNumber LIKE ?',
      whereArgs: ['$datePrefix%'],
      orderBy: '$saleInvoiceNumber DESC',
      limit: 1,
    );

    int sequence = 1;
    if (result.isNotEmpty) {
      final lastInvoice = result.first[saleInvoiceNumber] as String;
      final lastSequence = int.tryParse(lastInvoice.substring(8)) ?? 0;
      sequence = lastSequence + 1;
    }

    return '$datePrefix${sequence.toString().padLeft(4, '0')}';
  }

  /// إغلاق قاعدة البيانات
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// حذف قاعدة البيانات (للاختبار فقط)
  static Future<void> deleteDatabase() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, dbName);
    await databaseFactory.deleteDatabase(dbPath);
    _database = null;
  }
}
