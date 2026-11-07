import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'ride_history_screen.dart';
import 'settings_screen.dart';
import 'ride_status_screen.dart';
import 'location_map.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();

  String _selectedPaymentMethod = 'نقداً (كاش)';
  double _baseFare = 15.0; // سعر تجريبي حالياً
  double _discountAmount = 0.0;
  String _appliedPromoCode = '';
  bool _loading = false;
  LatLng? _pickup; // موقع العميل الحالي

  @override
  void dispose() {
    _destinationController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _msg(String text, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  void _applyPromoCode() {
    FocusScope.of(context).unfocus();
    final code = _promoController.text.trim().toUpperCase();

    if (code.isEmpty) {
      _msg('يرجى إدخال كود الخصم أولاً.');
    } else if (code == 'JITAK10' || code == 'WELCOME') {
      setState(() {
        _discountAmount = 3.0;
        _appliedPromoCode = code;
      });
      _msg('تم تطبيق الكوبون ($code)! تم خصم 3.0 د.ل', color: Colors.green);
    } else {
      _msg('كود الخصم غير صحيح أو منتهي الصلاحية!', color: Colors.red);
    }
  }

  double get _finalFare {
    final fare = _baseFare - _discountAmount;
    return fare > 0 ? fare : 0.0;
  }

  // إنشاء طلب رحلة حقيقي في قاعدة البيانات
  Future<void> _requestRide() async {
    final user = FirebaseAuth.instance.currentUser;
    final destination = _destinationController.text.trim();
    final pickup = _pickup;

    if (user == null) return;
    if (destination.isEmpty) {
      _msg('الرجاء إدخال وجهتك أولاً!');
      return;
    }

    setState(() => _loading = true);
    try {
      final ref = await FirebaseFirestore.instance.collection('rides').add({
        'customerId': user.uid,
        'customerName': user.displayName ?? '',
        'destination': destination,
        'fare': _finalFare,
        'paymentMethod': _selectedPaymentMethod,
        'status': 'requested',
        if (pickup != null)
          'pickup': GeoPoint(pickup.latitude, pickup.longitude),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => RideStatusScreen(rideId: ref.id)),
      );
    } catch (_) {
      _msg('تعذر إرسال الطلب، حاول مجدداً.', color: Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              LocationMap(
                onLocated: (position) => _pickup = position,
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
                      if (_appliedPromoCode.isNotEmpty)
                        Text(
                          'كوبون مطبّق: $_appliedPromoCode',
                          style: const TextStyle(
                              color: Colors.green, fontSize: 12),
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
                        onPressed: _loading ? null : _requestRide,
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
                            : const Text('بحث عن كابتن الآن',
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
// نهاية الملف
