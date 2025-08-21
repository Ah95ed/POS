import 'dart:io';
import 'package:pos/Helper/Locale/Language.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

late SharedPreferences shared;
late String langApp ;
Future<void> initService() async {
  shared = await SharedPreferences.getInstance();
  if (Platform.isWindows || Platform.isLinux) {
    databaseFactory = databaseFactoryFfi;

  }
  

await initLang( shared.getString('lang') ?? 'ar');

}
  Map trans = {};
late String language;

initLang(String lang) async {
  if (lang == 'ar') {
    trans = Language.keyMap['ar']! ;

  } else {
    trans = Language.keyMap['en']!;

  }

}