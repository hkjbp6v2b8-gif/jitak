import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({Key? key}) : super(key: key);

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _car = TextEditingController();
  final _plate = TextEditingController();
  bool _loading = false;

  // إرفاق الصور (محاكاة حالياً)
  final Map<String, bool> _docs = {
    'الصورة الشخصية': false,
    'جواز السفر': false,
    'رخصة القيادة': false,
    'صورة السيارة (من الخارج)': false,
    'صورة السيارة (من الداخل)': false,
  };

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _password, _car, _plate]) {
      c.dispose();
    }
    super.dispose();
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _error(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'هذا البريد مسجل مسبقاً.';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة (6 أحرف على الأقل).';
      case 'network-request-failed':
        return 'تحقق من اتصالك بالإنترنت.';
      default:
        return 'تعذر إرسال الطلب ($code).';
    }
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final car = _car.text.trim();
    final plate = _plate.text.trim();

    final allFilled =
        [name, phone, email, password, car, plate].every((s) => s.isNotEmpty);
    if (!allFilled || !_docs.values.every((v) => v)) {
      _msg('الرجاء تعبئة كافة البيانات وإرفاق جميع المستندات!');
      return;
    }
    if (password.length < 6) {
      _msg('كلمة المرور 6 أحرف على الأقل.');
      return;
    }

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = cred.user;
      await user?.updateDisplayName(name);

      if (user != null) {
        try {
          // الحالة دائماً "قيد المراجعة"، والإدارة وحدها تفعّل الحساب
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'name': name,
            'phone': phone,
            'email': email,
            'role': 'driver',
            'status': 'pending',
            'carModel': car,
            'plateNumber': plate,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {
          if (mounted) _msg('تم إنشاء الحساب لكن تعذر حفظ البيانات.');
        }
      }

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (mounted) _msg(_error(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _title(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType? type, bool obscure = false}) {
    return TextField(
      controller: c,
      keyboardType: type,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _docTile(String title) {
    final done = _docs[title] ?? false;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: done ? Colors.green.shade100 : Colors.teal.shade50,
          child: Icon(
            done ? Icons.check_circle : Icons.cloud_upload,
            color: done ? Colors.green : Colors.teal,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: ElevatedButton(
          onPressed: () => setState(() => _docs[title] = !done),
          style: ElevatedButton.styleFrom(
            backgroundColor: done ? Colors.grey.shade400 : Colors.teal,
          ),
          child: Text(
            done ? 'تم الرفع' : 'إرفاق',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل كابتن جديد'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title('بيانات الحساب'),
            const SizedBox(height: 12),
            _field(_email, 'البريد الإلكتروني', Icons.email_outlined,
                type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(_password, 'كلمة المرور (6 أحرف على الأقل)',
                Icons.lock_outline,
                obscure: true),
            const Divider(height: 32),
            _title('البيانات الشخصية والسيارة'),
            const SizedBox(height: 12),
            _field(_name, 'الاسم الثلاثي', Icons.person),
            const SizedBox(height: 12),
            _field(_phone, 'رقم الهاتف', Icons.phone,
                type: TextInputType.phone),
            const SizedBox(height: 12),
            _field(_car, 'نوع وموديل السيارة', Icons.directions_car),
            const SizedBox(height: 12),
            _field(_plate, 'رقم اللوحة', Icons.pin),
            const Divider(height: 32),
            _title('إرفاق الوثائق والمستندات'),
            const SizedBox(height: 6),
            const Text(
              'ملاحظة: رفع الصور تجريبي حالياً، وسيُفعَّل الرفع الفعلي قريباً.',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ..._docs.keys.map(_docTile),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'إرسال الطلب للمراجعة',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
// نهاية الملف
