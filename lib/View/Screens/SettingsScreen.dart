import 'package:flutter/material.dart';
import 'package:pos/Controller/SettingsProvider.dart';
import 'package:pos/Helper/Locale/LanguageController.dart';
import 'package:pos/Helper/Log/LogApp.dart';
import 'package:pos/View/style/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:smart_sizer/smart_sizer.dart';

/// شاشة الإعدادات - Settings Screen
/// تعرض واجهة المستخدم لتعديل إعدادات التطبيق
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // متحكمات النص
  late TextEditingController _storeNameController;
  late TextEditingController _phoneController;

  // قيم مؤقتة للإعدادات
  String _selectedLanguage = 'ar';
  String _selectedCurrency = 'دينار';
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _storeNameController = TextEditingController();
    _phoneController = TextEditingController();

    // تأخير تهيئة القيم حتى يتم بناء الشجرة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeValues();
    });
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// تهيئة القيم من Provider
  void _initializeValues() {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

    setState(() {
      _selectedLanguage = settingsProvider.language;
      _selectedCurrency = settingsProvider.currency;
      _isDarkMode = settingsProvider.isDarkMode;
      _notificationsEnabled = settingsProvider.notificationsEnabled;
      _storeNameController.text = settingsProvider.storeName;
      _phoneController.text = settingsProvider.phoneNumber;
    });
  }

  /// حفظ الإعدادات
  Future<void> _saveSettings() async {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

    // إنشاء نسخة جديدة من الإعدادات بالقيم المحدثة
    final newSettings = settingsProvider.settings.copyWith(
      language: _selectedLanguage,
      isDarkMode: _isDarkMode,
      currency: _selectedCurrency,
      notificationsEnabled: _notificationsEnabled,
      storeName: _storeNameController.text,
      phoneNumber: _phoneController.text,
    );

    // حفظ الإعدادات
    final success = await settingsProvider.updateSettings(newSettings);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(settingsProvider.translate('settingsSaved')),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        // تعيين اتجاه النص بناءً على اللغة
        return Directionality(
          textDirection: settingsProvider.textDirection,
          child: Scaffold(
            appBar: AppBar(
              title: Text(settingsProvider.translate('settings')),
              backgroundColor: Theme.of(context).primaryColor,
              elevation: 0,
            ),
            body: settingsProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildSettingsForm(settingsProvider),
          ),
        );
      },
    );
  }

  /// بناء نموذج الإعدادات
  Widget _buildSettingsForm(SettingsProvider settingsProvider) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.getMinSize(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عرض رسالة الخطأ إذا وجدت
          if (settingsProvider.errorMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.getMinSize(4)),
              margin: EdgeInsets.only(bottom: context.getHeight(4)),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(context.getMinSize(2)),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error,
                    color: Colors.red,
                    size: context.getMinSize(6),
                  ),
                  SizedBox(width: context.getWidth(4)),
                  Expanded(
                    child: Text(
                      settingsProvider.errorMessage,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: context.getFontSize(12),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: context.getMinSize(5)),
                    onPressed: settingsProvider.clearError,
                  ),
                ],
              ),
            ),

          _buildSettingsSection(settingsProvider.translate('settings'), [
            // قسم اللغة
            _buildSettingItem(
              title: settingsProvider.translate('language'),
              icon: Icons.language,
              child: _buildLanguageDropdown(settingsProvider, context),
            ),

            // قسم المظهر
            _buildSettingItem(
              title: settingsProvider.translate('theme'),
              icon: Icons.dark_mode,
              child: _buildThemeSwitch(settingsProvider),
            ),

            // قسم العملة
            _buildSettingItem(
              title: settingsProvider.translate('currency'),
              icon: Icons.attach_money,
              child: _buildCurrencyDropdown(settingsProvider),
            ),

            // قسم الإشعارات
            _buildSettingItem(
              title: settingsProvider.translate('notifications'),
              icon: Icons.notifications,
              child: _buildNotificationsSwitch(settingsProvider),
            ),
          ]),

          SizedBox(height: context.getHeight(4)),

          _buildSettingsSection(settingsProvider.translate('storeName'), [
            // قسم معلومات المتجر
            _buildSettingItem(
              title: settingsProvider.translate('storeName'),
              icon: Icons.store,
              child: _buildTextField(
                controller: _storeNameController,
                hintText: settingsProvider.translate('enterStoreName'),
              ),
            ),

            _buildSettingItem(
              title: settingsProvider.translate('phoneNumber'),
              icon: Icons.phone,
              child: _buildTextField(
                controller: _phoneController,
                hintText: settingsProvider.translate('enterPhoneNumber'),
                keyboardType: TextInputType.phone,
              ),
            ),
          ]),

          SizedBox(height: context.getHeight(4)),

          // زر الحفظ
          SizedBox(
            width: double.infinity,
            height: context.getHeight(20),
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.getMinSize(2)),
                ),
              ),
              child: Text(
                settingsProvider.translate('save'),
                style: TextStyle(
                  fontSize: context.getFontSize(12),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء قسم إعدادات
  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: context.getHeight(2)),
          child: Text(
            title,
            style: TextStyle(
              fontSize: context.getFontSize(14),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(context.getMinSize(4)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  /// بناء عنصر إعدادات
  Widget _buildSettingItem({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.getHeight(1),
        horizontal: context.getWidth(2),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: context.getMinSize(4),
          ),
          SizedBox(width: context.getWidth(2)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.getFontSize(12),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: context.getHeight(1)),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء قائمة منسدلة للغات
  Widget _buildLanguageDropdown(
    SettingsProvider settingsProvider,
    BuildContext context,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.getWidth(2)),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(context.getMinSize(2)),
      ),
      child: DropdownButton<String>(
        value: _selectedLanguage,
        isExpanded: true,
        underline: const SizedBox(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            // logError("message  === $newValue");
            Provider.of<LanguageController>(
              context,
              listen: false,
            ).changeLanguage(newValue);
          }
        },
        items: [
          DropdownMenuItem(
            value: 'ar',
            child: Text(settingsProvider.translate('arabic')),
          ),
          DropdownMenuItem(
            value: 'en',
            child: Text(settingsProvider.translate('english')),
          ),
        ],
      ),
    );
  }

  /// بناء مفتاح تبديل المظهر
  Widget _buildThemeSwitch(SettingsProvider settingsProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _isDarkMode
              ? settingsProvider.translate('darkMode')
              : settingsProvider.translate('lightMode'),
          style: TextStyle(fontSize: context.getFontSize(12)),
        ),
        Switch(
          value: _isDarkMode,
          activeThumbColor: Theme.of(context).primaryColor,
          onChanged: (bool value) async {
            setState(() {
              _isDarkMode = value;
            });

            // تطبيق التغيير مباشرة للاختبار
            await settingsProvider.toggleTheme();
          },
        ),
      ],
    );
  }

  /// بناء قائمة منسدلة للعملات
  Widget _buildCurrencyDropdown(SettingsProvider settingsProvider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.getWidth(2)),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(context.getMinSize(1)),
      ),
      child: DropdownButton<String>(
        value: _selectedCurrency,
        isExpanded: true,
        underline: const SizedBox(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedCurrency = newValue;
            });
          }
        },
        items: [
          DropdownMenuItem(
            value: 'دينار',
            child: Text(settingsProvider.translate('dinar')),
          ),
          DropdownMenuItem(
            value: 'دولار',
            child: Text(settingsProvider.translate('dollar')),
          ),
          DropdownMenuItem(
            value: 'يورو',
            child: Text(settingsProvider.translate('euro')),
          ),
        ],
      ),
    );
  }

  /// بناء مفتاح تبديل الإشعارات
  Widget _buildNotificationsSwitch(SettingsProvider settingsProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          settingsProvider.translate('notifications'),
          style: TextStyle(fontSize: context.getFontSize(14)),
        ),
        Switch(
          value: _notificationsEnabled,
          activeThumbColor: Theme.of(context).primaryColor,
          onChanged: (bool value) {
            setState(() {
              _notificationsEnabled = value;
            });
          },
        ),
      ],
    );
  }

  /// بناء حقل نص
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.getMinSize(1)),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: context.getHeight(1.5),
          horizontal: context.getWidth(2),
        ),
      ),
    );
  }
}
