import 'dart:io';

import 'package:path/path.dart';
import 'package:pos/Helper/Log/LogApp.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DataBaseSqflite {
  static const version = 1;
  static const tableName = 'Items';
  static const tableAccount = 'Account';
  static const dbName = 'Point.db';
  static const id = 'ID';
  static const name = 'Name';
  static const codeItem = 'Code';
  static const sale = 'Sale';
  static const buy = 'Buy';
  static const quantity = 'Quantity';
  static const company = 'Company';
  static const date = 'Date';
  static const time = 'Time';

  static Database? _database;

  DataBaseSqflite() {
    databasesq;
  }

  static Future<Database?> get databasesq async {
    if (_database != null) {
      return _database;
    } else if (Platform.isWindows || Platform.isLinux) {
      return await windowsApp();
    } else {
      return await mobileApp();
    }
  }

  static Future<Database> mobileApp() async {
    var datPath = await getDatabasesPath();
    String path = join(datPath, dbName);
    return await openDatabase(
      path,
      version: version,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE IF NOT EXISTS $tableName 
          ($id INTEGER PRIMARY KEY AUTOINCREMENT  ,
           $name TEXT ,
            $codeItem TEXT 
            , $sale TEXT
             , $buy TEXT
             , $quantity TEXT 
             ,$company TEXT
            ,$date TEXT )''');
      },
    );
  }

  static Future<Database?> windowsApp() async {
    final path = await getDatabasesPath();
    final pathFile = join(path, dbName);
    return await databaseFactoryFfi.openDatabase(
      pathFile,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: (db, version) async {
          await db.execute('''CREATE TABLE IF NOT EXISTS
             $tableName ($id INTEGER PRIMARY KEY AUTOINCREMENT  ,
             $name TEXT ,
              $codeItem TEXT ,
               $sale TEXT , 
               $buy TEXT ,
                $quantity TEXT ,
                $company TEXT ,
            $date TEXT )''');
        },
      ),
    );
  }

  Future<int> insert(Map<String, dynamic> data) async {
    _database = await databasesq;
    return _database!.insert(
      tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateItem(Map<String, dynamic> data, String i) async {
    Database? db = await databasesq;
    return db!.update(tableName, data, where: '$id = ?', whereArgs: [i]);
  }

  Future<List<Map<String, dynamic>?>> getAllUser(skip, limit) async {
    Database? db = await databasesq;
    var result = await db!.rawQuery(
      'SELECT * FROM $tableName  WHERE ID > $skip ORDER BY ID LIMIT $limit',
    );

    return result.toList();
  }

  Future<List<Map<String, dynamic>?>> getAllData() async {
    Database? db = await databasesq;
    var result = await db!.rawQuery('SELECT * FROM $tableName');
    logInfo("message ${result.toList().length}");
    return result.toList();
  }

  // delete
  Future<int> delete(String i) async {
    _database = await databasesq;
    return await _database!.rawDelete('DELETE FROM $tableName WHERE ID = ?', [
      i,
    ]);
  }

  Future<List<Map<String, dynamic>>> searchInDatabase(String query) async {
    _database = await databasesq;
    return await _database!.query(
      tableName,
      where: '$name LIKE ?',
      whereArgs: ['%$query%'],
    );
  }

  Future<List<Map<String, dynamic>>> searchInDatabaseCode(String code) async {
    _database = await databasesq;
    return await _database!.query(
      tableName,
      where: '$codeItem LIKE ?',
      whereArgs: ['%$code%'],
    );
  }

  Future<void> updateCostCol(double newValue) async {
    final db = await databasesq;
    List<Map<String, dynamic>> rows = await db!.query(tableName);
    List<Map<String, dynamic>> updatedRows = rows.map((row) {
      String num = row[sale].toString().replaceAll(RegExp(r'[^0-9.]'), '');

      double oldValue = double.parse(num);
      double updatedValue = oldValue + newValue;
      return {...row, sale: updatedValue};
    }).toList();
    Batch batch = db.batch();
    for (var row in updatedRows) {
      batch.update(tableName, row, where: 'id = ?', whereArgs: [row[id]]);
    }
    await batch.commit();
  }

  Future<void> updateBuyCol(double newValue) async {
    final db = await databasesq;
    List<Map<String, dynamic>> rows = await db!.query(tableName);
    List<Map<String, dynamic>> updatedRows = rows.map((row) {
      String num = row[buy].toString().replaceAll(RegExp(r'[^0-9.]'), '');

      double oldValue = double.parse(num);
      double updatedValue = oldValue + newValue;
      return {...row, buy: updatedValue};
    }).toList();
    Batch batch = db.batch();
    for (var row in updatedRows) {
      batch.update(tableName, row, where: 'id = ?', whereArgs: [row[id]]);
    }
    await batch.commit();
  }
}
