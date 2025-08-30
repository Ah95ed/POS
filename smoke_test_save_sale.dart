// Simple smoke test to validate saving a sale and stock decrement across DBs

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:pos/Helper/DataBase/DataBaseSqflite.dart';
import 'package:pos/Helper/DataBase/POSDatabase.dart';
import 'package:pos/Repository/SaleRepository.dart';
import 'package:pos/Model/SaleModel.dart';

Future<void> main() async {
  // Initialize FFI for desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Clean test DBs for a fresh run
  try {
    // Delete both DB files
    final invPath = await getDatabasesPath();
    await databaseFactoryFfi.deleteDatabase(
      join(invPath, DataBaseSqflite.dbName),
    );
    await databaseFactoryFfi.deleteDatabase(join(invPath, POSDatabase.dbName));
  } catch (_) {}

  // Ensure POS DB is created
  await POSDatabase.database;

  // Seed inventory with one product
  final invDb = await DataBaseSqflite.databasesq;
  final seed = {
    DataBaseSqflite.name: 'Test Product',
    DataBaseSqflite.codeItem: 'TEST1',
    DataBaseSqflite.sale: '25.0',
    DataBaseSqflite.buy: '10.0',
    DataBaseSqflite.quantity: '10',
    DataBaseSqflite.company: 'ACME',
    DataBaseSqflite.date: DateTime.now().toIso8601String(),
    DataBaseSqflite.expiryDate: '',
    DataBaseSqflite.description: 'Seed item',
    DataBaseSqflite.isArchived: 0,
    DataBaseSqflite.lowStockThreshold: 5,
  };
  await invDb!.insert(DataBaseSqflite.tableName, seed);

  // Build sale model with that product
  final repo = SaleRepository();
  final invNoRes = await repo.generateInvoiceNumber();
  final invNo = invNoRes.isSuccess ? invNoRes.data! : 'INV-TEST-1';

  final sale = SaleModel(
    invoiceNumber: invNo,
    customerId: null,
    subtotal: 50.0,
    tax: 0.0,
    discount: 0.0,
    total: 50.0,
    paidAmount: 50.0,
    changeAmount: 0.0,
    paymentMethod: 'cash',
    status: 'completed',
    notes: null,
    createdAt: DateTime.now(),
    items: [
      SaleItemModel(
        productId: 1,
        productName: 'Test Product',
        productCode: 'TEST1',
        quantity: 2,
        unitPrice: 25.0,
        discount: 0.0,
        total: 50.0,
      ),
    ],
  );

  final res = await repo.saveSale(sale);
  print('saveSale isSuccess: ${res.isSuccess}, error: ${res.error}');

  if (res.isSuccess) {
    // Check inventory quantity decreased to 8
    final rows = await invDb.query(
      DataBaseSqflite.tableName,
      columns: [DataBaseSqflite.quantity],
      where: '${DataBaseSqflite.codeItem} = ?',
      whereArgs: ['TEST1'],
      limit: 1,
    );
    print('Remaining qty: ${rows.first[DataBaseSqflite.quantity]}');

    // Load sale back
    final loaded = await repo.getSaleById(res.data!);
    print(
      'loaded sale success: ${loaded.isSuccess}, items: ${loaded.data?.items.length}',
    );
  }
}
