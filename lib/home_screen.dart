import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tracking_screen.dart';
import 'ride_history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();

  String _selectedPaymentMethod = 'نقداً (كاش)';
  double _baseFare = 15.0;
  double _discountAmount = 0.0;
  String _appliedPromoCode = '';

  @override
  void dispose() {
    _destinationController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  // دالة لتطبيق كود الخصم
  void _applyPromoCode() {
    FocusScope.of(context).unfocus();
    String code = _promoController.text.trim().toUpperCase();

    if (code == 'JITAK10' || code == 'WELCOME') {
      setState(() {
        _discountAmount = 3.0; // خصم 3 دينار
        _appliedPromoCode = code;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تطبيق الكوبون ($code) بنجاح! تم خصم 3.0 د.ل'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال كود الخصم أولاً.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('كود الخصم غير صحيح أو منتهي الصلاحية!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double get _finalFare {
    double fare = _baseFare - _discountAmount;
    return fare > 0 ? fare : 0.0;
  }

  // دالة لعرض إشعار الطلب الوارد للسائق (محاكاة)
  void _simulateDriverIncomingRequest(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.teal),
              SizedBox(width: 8),
              Text('طلب رحلة جديد!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الوجهة: ${_destinationController.text}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('التكلفة النهائية: ${_finalFare.toStringAsFixed(1)} د.ل'),
              if (_discountAmount > 0)
                Text(
                  'تم خصم ${_discountAmount.toStringAsFixed(1)} د.ل بكوبون ($_appliedPromoCode)',
                  style: const TextStyle(color: Colors.green, fontSize: 12),
                ),
              const SizedBox(height: 8),
              Text('طريقة الدفع: $_selectedPaymentMethod'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم رفض الطلب.')),
                );
              },
              child: const Text('رفض', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrackingScreen(tripFare: _finalFare),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('قبول الرحلة',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اطلب مشوارك'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const RideHistoryScreen()),
              );
            },
            tooltip: 'تاريخ الرحلات',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'الإعدادات',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // تسجيل الخروج الفعلي، وAuthGate يعيدك لشاشة الدخول
              await FirebaseAuth.instance.signOut();
            },
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: 60, color: Colors.teal),
                      SizedBox(height: 8),
                      Text('أنت هنا (موقعك الحالي)',
                          style: TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إلى أين تريد الذهاب؟',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _destinationController,
                        decoration: InputDecoration(
                          hintText: 'اكتب وجهتك هنا',
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.teal),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _baseFare = 12.0 + (value.length * 1.5);
                            if (_baseFare > 45.0) _baseFare = 45.0;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // حقل كود الخصم (الكوبون)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _promoController,
                              decoration: InputDecoration(
                                hintText: 'كود الخصم',
                                prefixIcon: const Icon(Icons.card_giftcard,
                                    color: Colors.teal),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _applyPromoCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('تطبيق',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // عرض التكلفة بعد الخصم
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('التكلفة التقديرية:',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (_discountAmount > 0)
                                Text(
                                  '${_baseFare.toStringAsFixed(1)} د.ل',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey),
                                ),
                              Text(
                                '${_finalFare.toStringAsFixed(1)} د.ل',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('طريقة الدفع:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          DropdownButton<String>(
                            value: _selectedPaymentMethod,
                            items: <String>['نقداً (كاش)', 'محفظة إلكترونية']
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue == null) return;
                              setState(() {
                                _selectedPaymentMethod = newValue;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (_destinationController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('الرجاء إدخال وجهتك أولاً!')),
                            );
                            return;
                          }
                          _simulateDriverIncomingRequest(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('بحث عن كابتن الآن',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
