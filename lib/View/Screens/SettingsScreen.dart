import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'الإعدادات',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.grey[700],
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsSection('الإعدادات العامة', [
            _buildSettingsTile('اللغة', 'العربية', Icons.language, () {}),
            _buildSettingsTile(
              'العملة',
              'ريال سعودي',
              Icons.attach_money,
              () {},
            ),
            _buildSettingsTile(
              'المنطقة الزمنية',
              'الرياض',
              Icons.access_time,
              () {},
            ),
          ]),
          const SizedBox(height: 20),
          _buildSettingsSection('إعدادات المتجر', [
            _buildSettingsTile('اسم المتجر', 'متجري', Icons.store, () {}),
            _buildSettingsTile(
              'عنوان المتجر',
              'الرياض، السعودية',
              Icons.location_on,
              () {},
            ),
            _buildSettingsTile(
              'رقم الهاتف',
              '+966 50 123 4567',
              Icons.phone,
              () {},
            ),
          ]),
          const SizedBox(height: 20),
          _buildSettingsSection('إعدادات النظام', [
            _buildSettingsTile(
              'النسخ الاحتياطي',
              'آخر نسخة: اليوم',
              Icons.backup,
              () {},
            ),
            _buildSettingsTile(
              'استيراد البيانات',
              'من ملف Excel',
              Icons.file_upload,
              () {},
            ),
            _buildSettingsTile(
              'تصدير البيانات',
              'إلى ملف Excel',
              Icons.file_download,
              () {},
            ),
          ]),
          const SizedBox(height: 20),
          _buildSettingsSection('حول التطبيق', [
            _buildSettingsTile('الإصدار', '1.0.0', Icons.info, () {}),
            _buildSettingsTile('المطور', 'فريق التطوير', Icons.code, () {}),
            _buildSettingsTile(
              'الدعم الفني',
              'تواصل معنا',
              Icons.support_agent,
              () {},
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
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

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }
}
