/// نموذج الإعدادات - Settings Model
/// يحتوي على جميع إعدادات التطبيق القابلة للتخصيص
class SettingsModel {
  final int? id;
  final String language;
  final bool isDarkMode;
  final String currency;
  final bool notificationsEnabled;
  final String storeName;
  final String phoneNumber;

  const SettingsModel({
    this.id,
    required this.language,
    required this.isDarkMode,
    required this.currency,
    required this.notificationsEnabled,
    required this.storeName,
    required this.phoneNumber,
  });

  /// إنشاء نسخة افتراضية من الإعدادات
  factory SettingsModel.defaultSettings() {
    return const SettingsModel(
      language: 'ar',
      isDarkMode: false,
      currency: 'دينار',
      notificationsEnabled: true,
      storeName: 'متجري',
      phoneNumber: '',
    );
  }

  /// إنشاء إعدادات من Map (من قاعدة البيانات)
  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      id: map['id'] as int?,
      language: map['language'] as String? ?? 'ar',
      isDarkMode: (map['theme'] as int?) == 1,
      currency: map['currency'] as String? ?? 'دينار',
      notificationsEnabled: (map['notifications'] as int?) == 1,
      storeName: map['storeName'] as String? ?? 'متجري',
      phoneNumber: map['phone'] as String? ?? '',
    );
  }

  /// تحويل الإعدادات إلى Map (لقاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'language': language,
      'theme': isDarkMode ? 1 : 0,
      'currency': currency,
      'notifications': notificationsEnabled ? 1 : 0,
      'storeName': storeName,
      'phone': phoneNumber,
    };
  }

  /// تحويل الإعدادات إلى JSON (للتخزين)
  Map<String, dynamic> toJson() => toMap();

  /// إنشاء إعدادات من JSON (من التخزين)
  factory SettingsModel.fromJson(Map<String, dynamic> json) => 
      SettingsModel.fromMap(json);

  /// إنشاء نسخة محدثة من الإعدادات
  SettingsModel copyWith({
    int? id,
    String? language,
    bool? isDarkMode,
    String? currency,
    bool? notificationsEnabled,
    String? storeName,
    String? phoneNumber,
  }) {
    return SettingsModel(
      id: id ?? this.id,
      language: language ?? this.language,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      currency: currency ?? this.currency,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      storeName: storeName ?? this.storeName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  @override
  String toString() {
    return 'SettingsModel(id: $id, language: $language, isDarkMode: $isDarkMode, '
        'currency: $currency, notificationsEnabled: $notificationsEnabled, '
        'storeName: $storeName, phoneNumber: $phoneNumber)';
  }
}