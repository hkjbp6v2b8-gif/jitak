import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'driver_profile_screen.dart';
import 'driver_wallet_screen.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({Key? key}) : super(key: key);

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  bool _isOnline = true;
  double _currentDebt = 22.5; // بيانات تجريبية (د.ل)
  final double _maxDebtLimit = 30.0;

  CollectionReference<Map<String, dynamic>> get _rides =>
      FirebaseFirestore.instance.collection('rides');

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _accept(String rideId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final name = (user.displayName ?? '').isEmpty ? 'الكابتن' : user.displayName;
    try {
      await _rides.doc(rideId).update({
        'status': 'accepted',
        'driverId': user.uid,
        'driverName': name,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) _msg('تم قبول الرحلة!');
    } catch (_) {
      if (mounted) _msg('تعذر قبول الرحلة (ربما قبلها سائق آخر).');
    }
  }

  Future<void> _complete(String rideId) async {
    try {
      await _rides.doc(rideId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) _msg('تم إنهاء الرحلة.');
    } catch (_) {
      if (mounted) _msg('تعذر إنهاء الرحلة، حاول مجدداً.');
    }
  }

  // بطاقة الرحلة الجارية
  Widget _activeRideCard(String rideId, Map<String, dynamic> ride) {
    final fare = (ride['fare'] as num?)?.toDouble() ?? 0.0;
    return Card(
      elevation: 4,
      color: Colors.teal.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.teal.shade300, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('رحلة جارية',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal)),
            const SizedBox(height: 8),
            Text('العميل: ${(ride['customerName'] ?? '').toString()}'),
            Text('الوجهة: ${(ride['destination'] ?? '').toString()}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('التكلفة: ${fare.toStringAsFixed(1)} د.ل'),
            Text('الدفع: ${(ride['paymentMethod'] ?? '').toString()}'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _complete(rideId),
              icon: const Icon(Icons.flag, color: Colors.white),
              label: const Text('إنهاء الرحلة',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // قائمة الطلبات المفتوحة
  Widget _requestsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _rides.where('status', isEqualTo: 'requested').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(
            child: Text('تعذر تحميل الطلبات. تحقق من الاتصال.',
                style: TextStyle(color: Colors.grey)),
          );
        }
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.teal));
        }

        final docs = snap.data!.docs.toList();
        docs.sort((a, b) {
          final ta = a.data()['createdAt'] as Timestamp?;
          final tb = b.data()['createdAt'] as Timestamp?;
          if (ta == null || tb == null) return 0;
          return tb.compareTo(ta);
        });

        if (docs.isEmpty) {
          return const Center(
            child: Text('لا توجد طلبات حالياً. سيظهر أي طلب جديد هنا فوراً.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView(
          children: docs.map((doc) {
            final ride = doc.data();
            final fare = (ride['fare'] as num?)?.toDouble() ?? 0.0;
            return Card(
              elevation: 2,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.tealAccent,
                  child: Icon(Icons.person, color: Colors.teal),
                ),
                title: Text('رحلة إلى: ${(ride['destination'] ?? '').toString()}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    'التكلفة: ${fare.toStringAsFixed(1)} د.ل • ${(ride['paymentMethod'] ?? '').toString()}'),
                trailing: ElevatedButton(
                  onPressed: () => _accept(doc.id),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text('قبول',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isBlocked = _currentDebt >= _maxDebtLimit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة السائق'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DriverWalletScreen()),
              );
            },
            tooltip: 'المحفظة والأرباح',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DriverProfileScreen()),
              );
            },
            tooltip: 'الملف الشخصي',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              color: isBlocked ? Colors.red.shade50 : Colors.teal.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isBlocked ? Colors.red : Colors.teal.shade200,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'محفظة العمولة والديون',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Icon(
                          isBlocked
                              ? Icons.warning_amber_rounded
                              : Icons.account_balance_wallet,
                          color: isBlocked ? Colors.red : Colors.teal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'الديون المتراكمة: $_currentDebt د.ل (الحد الأقصى: $_maxDebtLimit د.ل)',
                      style: TextStyle(
                        color: isBlocked ? Colors.red.shade700 : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: (_currentDebt / _maxDebtLimit)
                          .clamp(0.0, 1.0)
                          .toDouble(),
                      backgroundColor: Colors.grey.shade300,
                      color: isBlocked ? Colors.red : Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    if (isBlocked)
                      const Text(
                        'تنبيه: تجاوزت الحد الأقصى للديون (30 د.ل). تم ايقاف استقبال الرحلات حتى تسديد الدين.',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      )
                    else
                      const Text(
                        'الحساب متاح لاستقبال الطلبات بشكل طبيعي. (الأرقام تجريبية حالياً)',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        // محاكاة تسديد الديون (سيُربط بالخادم لاحقاً)
                        setState(() {
                          _currentDebt = 0.0;
                          _isOnline = true;
                        });
                        _msg('تم تسديد الدين (تجريبي).');
                      },
                      icon: const Icon(Icons.payment,
                          color: Colors.white, size: 18),
                      label: const Text('تسديد الدين وتعبئة الرصيد',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBlocked ? Colors.red : Colors.teal,
                        minimumSize: const Size(double.infinity, 36),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('أنت متصل الآن لاستقبال الرحلات',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(isBlocked
                  ? 'متوقف تلقائياً بسبب الديون'
                  : (_isOnline
                      ? 'تستقبل طلبات الزبائن حالياً'
                      : 'أنت في وضع عدم الاتصال')),
              value: isBlocked ? false : _isOnline,
              activeColor: Colors.teal,
              onChanged: isBlocked
                  ? null
                  : (bool value) {
                      setState(() {
                        _isOnline = value;
                      });
                    },
            ),
            const Divider(height: 24),
            Expanded(
              // الرحلة الجارية لها الأولوية، وإلا تظهر الطلبات المفتوحة
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _rides
                    .where('driverId', isEqualTo: _uid)
                    .where('status', isEqualTo: 'accepted')
                    .snapshots(),
                builder: (context, activeSnap) {
                  if (activeSnap.hasData && activeSnap.data!.docs.isNotEmpty) {
                    final doc = activeSnap.data!.docs.first;
                    return SingleChildScrollView(
                      child: _activeRideCard(doc.id, doc.data()),
                    );
                  }

                  if (isBlocked || !_isOnline) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.block,
                              size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            isBlocked
                                ? 'الحساب موقوف مؤقتاً لتجاوز الدين'
                                : 'أنت غير متصل حالياً',
                            style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'الطلبات القريبة المتاحة:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Expanded(child: _requestsList()),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// نهاية الملف
