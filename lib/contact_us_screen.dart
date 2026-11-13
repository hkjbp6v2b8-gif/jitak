import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'support_config.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  Future<void> _open(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) _fail(context);
    } catch (_) {
      if (context.mounted) _fail(context);
    }
  }

  void _fail(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذر فتح الرابط.')),
    );
  }

  Widget _tile(
    IconData icon,
    Color color,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle,
            textDirection: TextDirection.ltr, textAlign: TextAlign.right),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAny = SupportConfig.phone.isNotEmpty ||
        SupportConfig.whatsapp.isNotEmpty ||
        SupportConfig.email.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تواصل معنا'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          const Icon(Icons.support_agent, size: 80, color: Colors.teal),
          const SizedBox(height: 12),
          const Text('نسعد بخدمتك',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('تواصل مع فريق جِيتك لأي استفسار أو مشكلة.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          if (SupportConfig.phone.isNotEmpty)
            _tile(
              Icons.call,
              Colors.teal,
              'اتصال هاتفي',
              SupportConfig.phone,
              () => _open(
                  context, Uri(scheme: 'tel', path: SupportConfig.phone)),
            ),
          if (SupportConfig.whatsapp.isNotEmpty)
            _tile(
              Icons.chat,
              Colors.green,
              'واتساب',
              SupportConfig.whatsapp,
              () => _open(
                  context, Uri.https('wa.me', '/${SupportConfig.whatsapp}')),
            ),
          if (SupportConfig.email.isNotEmpty)
            _tile(
              Icons.email,
              Colors.blue,
              'البريد الإلكتروني',
              SupportConfig.email,
              () => _open(
                  context, Uri(scheme: 'mailto', path: SupportConfig.email)),
            ),
          if (!hasAny)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'ستتوفر وسائل التواصل مع الدعم قريباً.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          if (SupportConfig.hours.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('ساعات العمل: ${SupportConfig.hours}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
          ],
        ],
      ),
    );
  }
}
// نهاية الملف
