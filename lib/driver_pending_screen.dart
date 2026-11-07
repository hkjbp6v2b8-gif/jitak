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
        password.isEmpty 
