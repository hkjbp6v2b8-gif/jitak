import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات والدعم'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'عام',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('التنبيهات والإشعارات'),
            subtitle: const Text('استلام تحديثات الرحلات والحالات'),
            value: _notificationsEnabled,
            activeColor: Colors.teal,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.language, color: Colors.teal),
            title: Text('اللغة'),
            subtitle: Text('العربية'),
          ),
          const Divider(),
          const SizedBox(height: 10),
          const Text(
            'المساعدة والدعم',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.headset_mic, color: Colors.teal),
            title: const Text('التواصل مع الدعم الفني'),
            subtitle: const Text('مساعدة على مدار 24 ساعة'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('جارٍ فتح خدمة العملاء...')),
              );
            },
          ),
          const ListTile(
            leading: Icon(Icons.info_outline, color: Colors.teal),
            title: Text('عن التطبيق'),
            subtitle: Text('تطبيق جِيتك الإصدار 1.0.0'),
          ),
        ],
      ),
    );
  }
}
