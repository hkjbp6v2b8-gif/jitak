import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({Key? key}) : super(key: key);

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _carModelController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();

  bool _isLoading = false;

  // حالات إرفاق الصور (محاكاة الرفع حالياً)
  bool _hasProfilePhoto = false;
  bool _hasPassportPhoto = false;
  bool _hasLicensePhoto = false;
  bool _hasCarExteriorPhoto = false;
  bool _hasCarInteriorPhoto = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _carModelController.dispose();
    _plateNumberController.dispose();
    super.dispose();
  }

  String _errorMessage(String code) {
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
    final name = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final carModel = _carModelController.text.trim();
    final plate = _plateNumberController.text.trim();

    if (name.isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        carModel.isEmpty ||
        plate.isEmpty ||
        !_hasProfilePhoto ||
        !_hasPassportPhoto ||
        !_hasLicensePhoto ||
        !_hasCarExteriorPhoto ||
        !_hasCarInteriorPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('الرجاء تعبئة كافة البيانات وإرفاق جميع المستندات المطلوبة!')),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمة المرور 6 أحرف على الأقل.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
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
            'carModel': carModel,
            'plateNumber': plate,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('تم إنشاء الحساب لكن تعذر حفظ البيانات.')),
            );
          }
        }
      }

      if (!mounted) return;
      // العودة للجذر، وتوجيهك لشاشة "قيد المراجعة" يتم تلقائياً
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(e.code))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildUploadTile({
    required String title,
    required String subtitle,
    required bool isUploaded,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isUploaded ? Colors.green.shade100 : Colors.teal.shade50,
          child: Icon(
            isUploaded ? Icons.check_circle : Icons.cloud_upload,
            color: isUploaded ? Colors.green : Colors.teal,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: isUploaded ? Colors.grey.shade400 : Colors.teal,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            isUploaded ? 'تم الرفع' : 'إرفاق',
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'بيانات الحساب',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: const Icon(Icons.email_outlined, color: Colors.teal),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'كلمة المرور (6 أحرف على الأقل)',
                prefixIcon: const Icon(Icons.lock_outline, color: Colors.teal),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Divider(height: 32),
            const Text(
              'البيانات الشخصية والسيارة',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'الاسم الثلاثي',
                prefixIcon: const Icon(Icons.person, color: Colors.teal),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: const Icon(Icons.phone, color: Colors.teal),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _carModelController,
                    decoration: InputDecoration(
                      labelText: 'نوع وموديل السيارة',
                      prefixIcon:
                          const Icon(Icons.directions_car, color: Colors.teal),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _plateNumberController,
                    decoration: InputDecoration(
                      labelText: 'رقم اللوحة',
                      prefixIcon: const Icon(Icons.pin, color: Colors.teal),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            const Text(
              'إرفاق الوثائق الرسمية والمستندات',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal),
            ),
            const SizedBox(height: 6),
            const Text(
              'ملاحظة: رفع الصور تجريبي حالياً، وسيُفعَّل الرفع الفعلي قريباً.',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _buildUploadTile(
              title: 'الصورة الشخصية',
              subtitle: 'صورة خلفية بيضاء واضحة للوجه',
              isUploaded: _hasProfilePhoto,
              onTap: () => setState(() => _hasProfilePhoto = !_hasProfilePhoto),
            ),
            _buildUploadTile(
              title: 'جواز السفر',
              subtitle: 'صورة ملونة لصفحة البيانات الحالية',
              isUploaded: _hasPassportPhoto,
              onTap: () =>
                  setState(() => _hasPassportPhoto = !_hasPassportPhoto),
            ),
            _buildUploadTile(
              title: 'رخصة القيادة',
              subtitle: 'صورة الرخصة سارية المفعول (الوجهين)',
              isUploaded: _hasLicensePhoto,
              onTap: () => setState(() => _hasLicensePhoto = !_hasLicensePhoto),
            ),
            _buildUploadTile(
              title: 'صورة السيارة (من الخارج)',
              subtitle: 'صورة واضحة تظهر السيارة ورقم اللوحة',
              isUploaded: _hasCarExteriorPhoto,
              onTap: () =>
                  setState(() => _hasCarExteriorPhoto = !_hasCarExteriorPhoto),
            ),
            _buildUploadTile(
              title: 'صورة السيارة (من الداخل)',
              subtitle: 'صورة تظهر نظافة المقاعد والمقصورة',
              isUploaded: _hasCarInteriorPhoto,
              onTap: () =>
                  setState(() => _hasCarInteriorPhoto = !_hasCarInteriorPhoto),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
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
