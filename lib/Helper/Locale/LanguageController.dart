

import 'package:flutter/material.dart';
import 'package:pos/Helper/Service/Service.dart';

class LanguageController with ChangeNotifier {
  final supportLanguage = [
    const Locale.fromSubtags(languageCode: 'ar'),
    const Locale.fromSubtags(languageCode: 'en'),
  ];

  Locale language = shared.getString("lang") == null
      ? const Locale('ar')
      : Locale(
          shared.getString("lang")!,
        );

  void changeLanguage(String? lang) async {
    language = Locale(lang ?? "ar");
    await shared.setString("lang", lang!);
    await initLang(lang);
    notifyListeners();
  }


  // void changeLanguage() async {
  //   //
  //   if (shared.getString('lang') == 'ar') {
  //     await shared.setString("lang", 'en');
  //     language = const Locale('en');
  //     // await initLang('en');
  //     await initLang('en');
  //   } else {
  //     await shared.setString("lang", 'ar');
  //     language = const Locale('ar');
  //     // await initLang('ar');
  //     await initLang('ar');
  //   }
  //   notifyListeners();
  // }
}


