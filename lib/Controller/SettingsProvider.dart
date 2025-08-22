import 'package:flutter/material.dart';
import 'package:pos/Helper/DataBase/DataBaseSqflite.dart';
import 'package:pos/Helper/Service/Service.dart';
import 'package:pos/Model/SettingsModel.dart';
import 'package:pos/Repository/SettingsRepository.dart';
import 'package:pos/View/style/app_colors.dart';

/// مزود الإعدادات - Settings Provider
/// يدير حالة إعدادات التطبيق ويوفر وظائف لتحديثها
class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repository;

  // حالة الإعدادات
  bool _isLoading = false;
  String _errorMessage = '';
  SettingsModel _settings = SettingsModel.defaultSettings();

  // قاموس الترجمة
  final Map<String, Map<String, String>> _translations = {
    'ar': {
      'settings': 'الإعدادات',
      'language': 'اللغة',
      'theme': 'المظهر',
      'darkMode': 'الوضع الليلي',
      'lightMode': 'الوضع النهاري',
      'currency': 'العملة',
      'notifications': 'الإشعارات',
      'storeName': 'اسم المتجر',
      'phoneNumber': 'رقم الهاتف',
      'save': 'حفظ',
      'arabic': 'العربية',
      'english': 'الإنجليزية',
      'dinar': 'دينار',
      'dollar': 'دولار',
      'euro': 'يورو',
      'settingsSaved': 'تم حفظ الإعدادات بنجاح',
      'error': 'خطأ',
      'enterStoreName': 'أدخل اسم المتجر',
      'enterPhoneNumber': 'أدخل رقم الهاتف',
      'cancel': 'إلغاء',
    },
    'en': {
      'settings': 'Settings',
      'language': 'Language',
      'theme': 'Theme',
      'darkMode': 'Dark Mode',
      'lightMode': 'Light Mode',
      'currency': 'Currency',
      'notifications': 'Notifications',
      'storeName': 'Store Name',
      'phoneNumber': 'Phone Number',
      'save': 'Save',
      'arabic': 'Arabic',
      'english': 'English',
      'dinar': 'Dinar',
      'dollar': 'Dollar',
      'euro': 'Euro',
      'settingsSaved': 'Settings saved successfully',
      'error': 'Error',
      'enterStoreName': 'Enter store name',
      'enterPhoneNumber': 'Enter phone number',
      'cancel': 'Cancel',
    },
  };

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  SettingsModel get settings => _settings;
  bool get isDarkMode => _settings.isDarkMode;
  String get language => _settings.language;
  String get currency => _settings.currency;
  bool get notificationsEnabled => _settings.notificationsEnabled;
  String get storeName => _settings.storeName;
  String get phoneNumber => _settings.phoneNumber;

  // قائمة اللغات المدعومة
  List<String> get supportedLanguages => ['ar', 'en'];

  // قائمة العملات المدعومة
  List<String> get supportedCurrencies => ['دينار', 'دولار', 'يورو'];

  // الحصول على النص المترجم
  String translate(String key) {
    return _translations[_settings.language]?[key] ?? key;
  }

  // الحصول على اتجاه النص (RTL للعربية، LTR للإنجليزية)
  TextDirection get textDirection =>
      _settings.language == 'ar' ? TextDirection.rtl : TextDirection.ltr;

  SettingsProvider() : _repository = SettingsRepository(DataBaseSqflite()) {
    loadSettings();
  }

  /// تحميل الإعدادات من قاعدة البيانات
  Future<void> loadSettings() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _repository.getSettings();

      if (result.isSuccess) {
        if (result.data != null) {
          _settings = result.data!;
        } else {
          // استخدام الإعدادات الافتراضية إذا لم تكن هناك إعدادات محفوظة
          _settings = SettingsModel.defaultSettings();
          await _repository.saveSettings(_settings);
        }
      } else {
        _setError(result.error!);
      }
    } catch (e) {
      _setError('خطأ في تحميل الإعدادات: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// تحديث الإعدادات
  Future<bool> updateSettings(SettingsModel newSettings) async {
    _setLoading(true);
    _clearError();

    try {
      // تحديث القيمة في SharedPreferences للثيم
      await shared.setBool('access_isDarkMode', newSettings.isDarkMode);

      final result = await _repository.saveSettings(newSettings);

      if (result.isSuccess) {
        _settings = newSettings;
        notifyListeners();
        return true;
      } else {
        _setError(result.error!);
        return false;
      }
    } catch (e) {
      _setError('خطأ في تحديث الإعدادات: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// تغيير لغة التطبيق
  Future<bool> changeLanguage(String language) async {
    if (!supportedLanguages.contains(language)) {
      _setError('اللغة غير مدعومة');
      return false;
    }

    final newSettings = _settings.copyWith(language: language);
    return await updateSettings(newSettings);
  }

  /// تبديل وضع السمة (ليلي/نهاري)
  Future<bool> toggleTheme() async {
    final newIsDarkMode = !_settings.isDarkMode;
    // تحديث القيمة في SharedPreferences
    await shared.setBool('access_isDarkMode', newIsDarkMode);

    final newSettings = _settings.copyWith(isDarkMode: newIsDarkMode);
    return await updateSettings(newSettings);
  }

  /// تغيير العملة
  Future<bool> changeCurrency(String currency) async {
    if (!supportedCurrencies.contains(currency)) {
      _setError('العملة غير مدعومة');
      return false;
    }

    final newSettings = _settings.copyWith(currency: currency);
    return await updateSettings(newSettings);
  }

  /// تبديل حالة الإشعارات
  Future<bool> toggleNotifications() async {
    final newSettings = _settings.copyWith(
      notificationsEnabled: !_settings.notificationsEnabled,
    );
    return await updateSettings(newSettings);
  }

  /// تحديث اسم المتجر
  Future<bool> updateStoreName(String name) async {
    final newSettings = _settings.copyWith(storeName: name);
    return await updateSettings(newSettings);
  }

  /// تحديث رقم الهاتف
  Future<bool> updatePhoneNumber(String phone) async {
    final newSettings = _settings.copyWith(phoneNumber: phone);
    return await updateSettings(newSettings);
  }

  /// الحصول على سمة التطبيق بناءً على الإعدادات
  ThemeData getTheme(BuildContext context) {
    if (_settings.isDarkMode) {
      return ThemeData.dark().copyWith(
        primaryColor: Colors.teal,
        colorScheme: ColorScheme.dark(
          primary: Colors.teal,
          secondary: Colors.tealAccent,
          surface: AppColors.darkCard,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        cardColor: AppColors.darkCard,
        shadowColor: AppColors.darkShadow,
        appBarTheme: AppBarTheme(backgroundColor: Colors.teal.shade800),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: AppColors.darkTextMain),
          bodyMedium: TextStyle(color: AppColors.darkTextMain),
          titleLarge: TextStyle(color: AppColors.darkTextMain),
        ),
      );
    } else {
      return ThemeData.light().copyWith(
        primaryColor: Colors.teal,
        colorScheme: ColorScheme.light(
          primary: Colors.teal,
          secondary: Colors.tealAccent,
          surface: AppColors.lightCard,
        ),
        scaffoldBackgroundColor: AppColors.lightBackground,
        cardColor: AppColors.lightCard,
        shadowColor: AppColors.lightShadow,
        appBarTheme: AppBarTheme(backgroundColor: Colors.teal),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: AppColors.lightTextMain),
          bodyMedium: TextStyle(color: AppColors.lightTextMain),
          titleLarge: TextStyle(color: AppColors.lightTextMain),
        ),
      );
    }
  }

  /// مسح رسالة الخطأ
  void clearError() {
    _clearError();
    notifyListeners();
  }

  /// دوال مساعدة لإدارة الحالة
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }
}
