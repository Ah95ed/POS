import 'package:flutter/material.dart';
import 'package:pos/Controller/SettingsProvider.dart';
import 'package:pos/Helper/Locale/LanguageController.dart';
import 'package:pos/Helper/Log/LogApp.dart';
import 'package:pos/View/style/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:smart_sizer/smart_sizer.dart';

/// شاشة الإعدادات المحسنة - Enhanced Settings Screen
/// تعرض واجهة مستخدم جميلة وحديثة لتعديل إعدادات التطبيق
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  // متحكمات النص
  late TextEditingController _storeNameController;
  late TextEditingController _phoneController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

    // إعداد الرسوم المتحركة
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // تأخير تهيئة القيم حتى يتم بناء الشجرة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeValues();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
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

  /// حفظ الإعدادات مع رسوم متحركة
  Future<void> _saveSettings() async {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

    // إظهار مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildLoadingDialog(),
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

    // إغلاق مؤشر التحميل
    if (mounted) Navigator.of(context).pop();

    if (success && mounted) {
      _showSuccessSnackBar(settingsProvider.translate('settingsSaved'));
    }
  }

  /// إظهار رسالة نجاح مخصصة
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: context.getWidth(2)),
            Text(message, style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(context.getWidth(4)),
      ),
    );
  }

  /// بناء مربع حوار التحميل
  Widget _buildLoadingDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(context.getWidth(6)),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: context.getHeight(2)),
            Text(
              'جاري الحفظ...',
              style: TextStyle(
                color: AppColors.textMain,
                fontSize: context.getFontSize(14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Directionality(
          textDirection: settingsProvider.textDirection,
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: CustomScrollView(
              slivers: [
                _buildSliverAppBar(settingsProvider),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: settingsProvider.isLoading
                        ? _buildLoadingState()
                        : _buildSettingsContent(settingsProvider),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// بناء شريط التطبيق المخصص
  Widget _buildSliverAppBar(SettingsProvider settingsProvider) {
    return SliverAppBar(
      expandedHeight: context.getHeight(80),
      floating: false,
      pinned: true,
      backgroundColor: AppColors.accent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          settingsProvider.translate('settings'),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: context.getFontSize(18),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accent, AppColors.accent.withOpacity(0.8)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Center(
                child: Icon(
                  Icons.settings,
                  size: context.getWidth(20),
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء حالة التحميل
  Widget _buildLoadingState() {
    return SizedBox(
      height: context.getHeight(200),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: context.getHeight(2)),
            Text(
              'جاري تحميل الإعدادات...',
              style: TextStyle(
                color: AppColors.textMain.withOpacity(0.7),
                fontSize: context.getFontSize(14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء محتوى الإعدادات
  Widget _buildSettingsContent(SettingsProvider settingsProvider) {
    return Padding(
      padding: EdgeInsets.all(context.getWidth(4)),
      child: Column(
        children: [
          // عرض رسالة الخطأ إذا وجدت
          if (settingsProvider.errorMessage.isNotEmpty)
            _buildErrorMessage(settingsProvider),

          SizedBox(height: context.getHeight(2)),

          // قسم الإعدادات العامة
          _buildModernSettingsSection(
            title: 'الإعدادات العامة',
            icon: Icons.tune,
            children: [
              _buildLanguageSetting(settingsProvider),
              _buildThemeSetting(settingsProvider),
              _buildCurrencySetting(settingsProvider),
              _buildNotificationsSetting(settingsProvider),
            ],
          ),

          SizedBox(height: context.getHeight(3)),

          // قسم معلومات المتجر
          _buildModernSettingsSection(
            title: 'معلومات المتجر',
            icon: Icons.store,
            children: [
              _buildStoreNameSetting(settingsProvider),
              _buildPhoneSetting(settingsProvider),
            ],
          ),

          SizedBox(height: context.getHeight(4)),

          // زر الحفظ المحسن
          _buildSaveButton(settingsProvider),

          SizedBox(height: context.getHeight(4)),
        ],
      ),
    );
  }

  /// بناء رسالة الخطأ المحسنة
  Widget _buildErrorMessage(SettingsProvider settingsProvider) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: double.infinity,
      padding: EdgeInsets.all(context.getWidth(4)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.red.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.getWidth(2)),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              color: Colors.white,
              size: context.getWidth(5),
            ),
          ),
          SizedBox(width: context.getWidth(3)),
          Expanded(
            child: Text(
              settingsProvider.errorMessage,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: context.getFontSize(13),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade600),
            onPressed: settingsProvider.clearError,
          ),
        ],
      ),
    );
  }

  /// بناء قسم إعدادات حديث
  Widget _buildModernSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // رأس القسم
          Container(
            padding: EdgeInsets.all(context.getWidth(4)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withOpacity(0.1),
                  AppColors.accent.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(context.getWidth(2)),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: context.getWidth(5),
                  ),
                ),
                SizedBox(width: context.getWidth(3)),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.getFontSize(16),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
          ),
          // محتوى القسم
          Padding(
            padding: EdgeInsets.all(context.getWidth(4)),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  /// بناء إعداد اللغة
  Widget _buildLanguageSetting(SettingsProvider settingsProvider) {
    return _buildModernSettingItem(
      icon: Icons.language,
      title: settingsProvider.translate('language'),
      subtitle: _selectedLanguage == 'ar' ? 'العربية' : 'English',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.getWidth(3)),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        child: DropdownButton<String>(
          value: _selectedLanguage,
          isExpanded: true,
          underline: SizedBox(),
          dropdownColor: AppColors.card,
          icon: Icon(Icons.keyboard_arrow_down, color: AppColors.accent),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedLanguage = newValue;
              });
              Provider.of<LanguageController>(
                context,
                listen: false,
              ).changeLanguage(newValue);
            }
          },
          items: [
            DropdownMenuItem(
              value: 'ar',
              child: Row(
                children: [
                  Text(
                    '🇸🇦',
                    style: TextStyle(fontSize: context.getFontSize(16)),
                  ),
                  SizedBox(width: context.getWidth(2)),
                  Text(
                    'العربية',
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontSize: context.getFontSize(14),
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'en',
              child: Row(
                children: [
                  Text(
                    '🇺🇸',
                    style: TextStyle(fontSize: context.getFontSize(16)),
                  ),
                  SizedBox(width: context.getWidth(2)),
                  Text(
                    'English',
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontSize: context.getFontSize(14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء إعداد المظهر
  Widget _buildThemeSetting(SettingsProvider settingsProvider) {
    return _buildModernSettingItem(
      icon: _isDarkMode ? Icons.dark_mode : Icons.light_mode,
      title: settingsProvider.translate('theme'),
      subtitle: _isDarkMode ? 'المظهر الداكن' : 'المظهر الفاتح',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Switch(
          value: _isDarkMode,
          activeThumbColor: AppColors.accent,
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey.withOpacity(0.3),
          onChanged: (bool value) async {
            setState(() {
              _isDarkMode = value;
            });
            await settingsProvider.toggleTheme();
          },
        ),
      ),
    );
  }

  /// بناء إعداد العملة
  Widget _buildCurrencySetting(SettingsProvider settingsProvider) {
    return _buildModernSettingItem(
      icon: Icons.attach_money,
      title: settingsProvider.translate('currency'),
      subtitle: _selectedCurrency,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.getWidth(3)),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        child: DropdownButton<String>(
          value: _selectedCurrency,
          isExpanded: true,
          underline: SizedBox(),
          dropdownColor: AppColors.card,
          icon: Icon(Icons.keyboard_arrow_down, color: AppColors.accent),
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
              child: Row(
                children: [
                  Text(
                    '💰',
                    style: TextStyle(fontSize: context.getFontSize(16)),
                  ),
                  SizedBox(width: context.getWidth(2)),
                  Text(
                    'دينار',
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontSize: context.getFontSize(14),
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'دولار',
              child: Row(
                children: [
                  Text(
                    '💵',
                    style: TextStyle(fontSize: context.getFontSize(16)),
                  ),
                  SizedBox(width: context.getWidth(2)),
                  Text(
                    'دولار',
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontSize: context.getFontSize(14),
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'يورو',
              child: Row(
                children: [
                  Text(
                    '💶',
                    style: TextStyle(fontSize: context.getFontSize(16)),
                  ),
                  SizedBox(width: context.getWidth(2)),
                  Text(
                    'يورو',
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontSize: context.getFontSize(14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء إعداد الإشعارات
  Widget _buildNotificationsSetting(SettingsProvider settingsProvider) {
    return _buildModernSettingItem(
      icon: _notificationsEnabled
          ? Icons.notifications
          : Icons.notifications_off,
      title: settingsProvider.translate('notifications'),
      subtitle: _notificationsEnabled ? 'مفعلة' : 'معطلة',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Switch(
          value: _notificationsEnabled,
          activeThumbColor: AppColors.accent,
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey.withOpacity(0.3),
          onChanged: (bool value) {
            setState(() {
              _notificationsEnabled = value;
            });
          },
        ),
      ),
    );
  }

  /// بناء إعداد اسم المتجر
  Widget _buildStoreNameSetting(SettingsProvider settingsProvider) {
    return _buildModernSettingItem(
      icon: Icons.store,
      title: settingsProvider.translate('storeName'),
      subtitle: _storeNameController.text.isEmpty
          ? 'غير محدد'
          : _storeNameController.text,
      child: _buildModernTextField(
        controller: _storeNameController,
        hintText: settingsProvider.translate('enterStoreName'),
        icon: Icons.store,
      ),
    );
  }

  /// بناء إعداد رقم الهاتف
  Widget _buildPhoneSetting(SettingsProvider settingsProvider) {
    return _buildModernSettingItem(
      icon: Icons.phone,
      title: settingsProvider.translate('phoneNumber'),
      subtitle: _phoneController.text.isEmpty
          ? 'غير محدد'
          : _phoneController.text,
      child: _buildModernTextField(
        controller: _phoneController,
        hintText: settingsProvider.translate('enterPhoneNumber'),
        icon: Icons.phone,
        keyboardType: TextInputType.phone,
      ),
    );
  }

  /// بناء عنصر إعدادات حديث
  Widget _buildModernSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: context.getHeight(2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.getWidth(2)),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppColors.accent,
                  size: context.getWidth(5),
                ),
              ),
              SizedBox(width: context.getWidth(3)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: context.getFontSize(14),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: context.getFontSize(12),
                        color: AppColors.textMain.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.getHeight(1.5)),
          child,
        ],
      ),
    );
  }

  /// بناء حقل نص حديث
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          color: AppColors.textMain,
          fontSize: context.getFontSize(14),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppColors.textMain.withOpacity(0.5),
            fontSize: context.getFontSize(13),
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.accent,
            size: context.getWidth(5),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: context.getHeight(2),
            horizontal: context.getWidth(3),
          ),
        ),
      ),
    );
  }

  /// بناء زر الحفظ المحسن
  Widget _buildSaveButton(SettingsProvider settingsProvider) {
    return Container(
      width: double.infinity,
      height: context.getHeight(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, color: Colors.white, size: context.getMinSize(10)),
            SizedBox(width: context.getWidth(2)),
            Text(
              settingsProvider.translate('save'),
              style: TextStyle(
                fontSize: context.getFontSize(10),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
