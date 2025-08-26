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
  List<String> get supportedCurrencies => ['دينار', 'ريال', 'دولار', 'يورو'];

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
    final isDark = _settings.isDarkMode;

    final base = isDark ? ThemeData.dark() : ThemeData.light();
    final colorScheme =
        (isDark ? const ColorScheme.dark() : const ColorScheme.light())
            .copyWith(
              primary: AppColors.accent,
              secondary: AppColors.accent,
              surface: AppColors.card,
              onPrimary: isDark ? Colors.black : Colors.white,
              onSecondary: isDark ? Colors.black : Colors.white,
              onSurface: AppColors.textMain,
              error: AppColors.error,
              onError: isDark ? Colors.black : Colors.white,
            );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.accent,
      cardColor: AppColors.card,
      shadowColor: AppColors.shadow,
      dividerColor: AppColors.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.accent,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        centerTitle: true,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textMain,
        displayColor: AppColors.textMain,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accent, width: 1.2),
        ),
        hintStyle: TextStyle(color: AppColors.textMain),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: BorderSide(color: AppColors.accent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: isDark
            ? Colors.white
            : Colors.black,
        selectedColor: AppColors.accent,
        labelStyle: TextStyle(color: AppColors.textMain),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textMain,
        textColor: AppColors.textMain,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: AppColors.textMain,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: AppColors.textMain,
        ),
      ),
    );
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
