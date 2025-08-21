import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

late SharedPreferences shared;
Future<void> initService() async {
  shared = await SharedPreferences.getInstance();
  if (Platform.isWindows || Platform.isLinux) {
    databaseFactory = databaseFactoryFfi;

  }
}
