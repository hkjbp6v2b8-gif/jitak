import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _load() async {
    final user = _user;
    if (user != null) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = snap.data() ?? {};
        _name.text = (data['name'] ?? user.displayName ?? '').toString();
        _phone.text = (data['phone'] ?? '').toString();
      } catch (_) {
        _msg('تعذر تحميل بياناتك.');
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final user = _user;
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (user == null) return;
    if (name.isEmpty || phone.isEmpty) {
      _msg('الاسم ورقم الهاتف مطلوبان.');
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'name': name, 'phone': phone});
      await user.updateDisplayName(name);
      _msg('تم حفظ التعديلات.');
    } catch (_) {
      _msg('تعذر حفظ التعديلات، حاول مجدداً.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _user?.email;
    if (email == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _msg('أرسلنا رابط تغيير كلمة المرور إلى $email');
    } catch (_) {
      _msg('تعذر إرسال الرابط، حاول مجدداً.');
    }
  }

  OutlineInputBorder get _border =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(12));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: Colors.teal,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('بياناتي',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal)),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: 'الاسم',
                    prefixIcon:
                        const Icon(Icons.person_outline, color: Colors.teal),
                    border: _border,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف',
                    prefixIcon:
                        const Icon(Icons.phone_android, color: Colors.teal),
                    border: _border,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(text: _user?.email ?? ''),
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني (لا يمكن تغييره)',
                    prefixIcon:
                        const Icon(Icons.email_outlined, color: Colors.teal),
                    border: _border,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('حفظ التعديلات',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                const Divider(height: 36),
                ListTile(
                  leading: const Icon(Icons.lock_reset, color: Colors.teal),
                  title: const Text('تغيير كلمة المرور'),
                  subtitle: const Text('نرسل رابطاً إلى بريدك'),
                  onTap: _resetPassword,
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('تسجيل الخروج',
                      style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    }
                  },
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text('جِيتك • نسخة تجريبية',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
    );
  }
}
// نهاية الملف
