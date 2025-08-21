import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pos/Controller/DashboardProvider.dart';
import 'package:pos/Controller/ProductProvider.dart';
import 'package:pos/Controller/SaleProvider.dart';
import 'package:pos/Helper/Locale/LanguageController.dart';
import 'package:pos/Helper/Service/Service.dart';
import 'package:pos/View/Screens/MainLayout.dart';
import 'package:provider/provider.dart';
import 'package:smart_sizer/smart_sizer.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitDown,
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await initService();
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LanguageController()),
            ChangeNotifierProvider(create: (_) => DashboardProvider()),
            ChangeNotifierProvider(create: (_) => ProductProvider()),
            ChangeNotifierProvider(create: (_) => SaleProvider()),
          ],
          child: const MyApp(),
          // child: DevicePreview(
          //   enabled: !kReleaseMode,
          //   builder: (context) =>  MyApp(),
          // ),
        ),
      );
    },
    (error, stackTrace) {
      // Logger.logger('error: $error || stackTrace: $stackTrace');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageController>(
      builder: (context, value, child) {
        return SizeBuilder(
          baseSize: Size(360, 650),
          height: context.screenHeight,
          width: context.screenWidth,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: value.language,
            supportedLocales: value.supportLanguage,
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
                        title: 'POS',
            // theme: AppThemes.lightTheme,
            // darkTheme: AppThemes.darkTheme,
            themeMode: ThemeMode.system, // Or ThemeMode.light, ThemeMode.dark
            home: const MainLayout(),
          ),
        );
      },
    );
  }
}
