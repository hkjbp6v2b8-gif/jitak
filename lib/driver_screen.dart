import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'driver_profile_screen.dart';
import 'driver_wallet_screen.dart';
import 'ride_details_screen.dart';
import 'ride_map.dart';
import 'pricing.dart';
import 'driver_location_sender.dart';
import 'wallet_builder.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({Key? key}) : super(key: key);

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  bool _isOnline = true;

  CollectionReference<Map<String, dynamic>> get _rides =>
      FirebaseFirestore.instance.collection('rides');

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  LatLng? _point(dynamic v) =>
      v is GeoPoint ? LatLng(v.latitude, v.longitude) : null;

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

  void _openDetails(String rideId, Map<String, dynamic> ride) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideDetailsScreen(rideId: rideId, ride: ride),
      ),
    );
  }

  // بطاقة المحفظة: المستحق للشركة من رحلاتك الفعلية
  Widget _walletCard(WalletData w, bool blocked) {
    final color = blocked ? Colors.red : Colors.teal;
    final limit = WalletConfig.debtLimit;
    final rate = (WalletConfig.commissionRate * 100).round();

    final String info;
    if (w.loading) {
      info = 'جارٍ تحميل المحفظة...';
    } else if (w.error) {
      info = 'تعذر تحميل المحفظة. تحقق من الاتصال.';
    } else {
      info =
          'المستحق للشركة (عمولة $rate%): ${w.debt.toStringAsFixed(1)} د.ل (الحد الأقصى: ${limit.toStringAsFixed(0)} د.ل)';
    }

    return Card(
      elevation: 4,
      color: blocked ? Colors.red.shade50 : Colors.teal.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: blocked ? Colors.red : Colors.teal.shade200, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('محفظة العمولة',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Icon(
                  blocked
                      ? Icons.warning_amber_rounded
                      : Icons.account_balance_wallet,
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(info,
                style: TextStyle(
                  color: blocked ? Colors.red.shade700 : Colors.black87,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: w.ready ? (w.debt / limit).clamp(0.0, 1.0).toDouble() : 0,
              backgroundColor: Colors.grey.shade300,
              color: color,
            ),
            const SizedBox(height: 10),
            Text(
              blocked
                  ? 'بلغ المستحق الحد الأقصى. سدّد للإدارة ليُعاد تفعيل استقبال الطلبات.'
                  : 'الحساب متاح لاستقبال الطلبات. للتسديد تواصل مع الإدارة.',
              style: TextStyle(
                color: blocked ? Colors.red : Colors.grey,
                fontSize: 12,
                fontWeight: blocked ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DriverWalletScreen()),
                );
              },
              icon: Icon(Icons.account_balance_wallet, color: color, size: 18),
              label: Text('المحفظة والأرباح', style: TextStyle(color: color)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color),
                minimumSize: const Size(double.infinity, 36),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // الرحلة الجارية مع الخريطة ومشاركة الموقع وأزرار التواصل
  Widget _activeCard(String rideId, Map<String, dynamic> ride) {
    final pickup = _point(ride['pickup']);
    final dest = _point(ride['destinationPoint']);
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
            const SizedBox(height: 10),
            DriverLocationSender(key: ValueKey('loc-$rideId'), rideId: rideId),
            const SizedBox(height: 10),
            if (pickup != null && dest != null) ...[
              RideMap(
                key: ValueKey(rideId),
                pickup: pickup,
                destination: dest,
                height: 220,
              ),
              const SizedBox(height: 10),
            ],
            Text('العميل: ${(ride['customerName'] ?? '').toString()}'),
            Text('الوجهة: ${(ride['destination'] ?? '').toString()}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('التكلفة: ${Pricing.format(fare)} د.ل'),
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
            final km = (ride['distanceKm'] as num?)?.toDouble();
            final kmText = km == null ? '' : '${km.toStringAsFixed(1)} كم • ';
            return Card(
              elevation: 2,
              child: ListTile(
                onTap: () => _openDetails(doc.id, ride),
                leading: const CircleAvatar(
                  backgroundColor: Colors.tealAccent,
                  child: Icon(Icons.person, color: Colors.teal),
                ),
                title: Text(
                    'رحلة إلى: ${(ride['destination'] ?? '').toString()}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    '$kmText${Pricing.format(fare)} د.ل • ${(ride['paymentMethod'] ?? '').toString()}'),
                trailing: ElevatedButton(
                  onPressed: () => _openDetails(doc.id, ride),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: const Text('عرض',
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
    return WalletBuilder(
      driverId: _uid,
      builder: (context, wallet) {
        final blocked = wallet.ready && wallet.debt >= WalletConfig.debtLimit;
        return _page(wallet, blocked);
      },
    );
  }

  Widget _page(WalletData wallet, bool blocked) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة السائق'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'المحفظة والأرباح',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DriverWalletScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'الملف الشخصي',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DriverProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _walletCard(wallet, blocked),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('أنت متصل الآن لاستقبال الرحلات',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(blocked
                  ? 'متوقف تلقائياً بسبب المستحقات'
                  : (_isOnline
                      ? 'تستقبل طلبات الزبائن حالياً'
                      : 'أنت في وضع عدم الاتصال')),
              value: blocked ? false : _isOnline,
              activeColor: Colors.teal,
              onChanged:
                  blocked ? null : (v) => setState(() => _isOnline = v),
            ),
            const Divider(height: 24),
            Expanded(
              // الرحلة الجارية لها الأولوية، وإلا تظهر الطلبات المفتوحة
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _rides
                    .where('driverId', isEqualTo: _uid)
                    .where('status', isEqualTo: 'accepted')
                    .snapshots(),
                builder: (context, active) {
                  if (active.hasData && active.data!.docs.isNotEmpty) {
                    final doc = active.data!.docs.first;
                    return SingleChildScrollView(
                      child: _activeCard(doc.id, doc.data()),
                    );
                  }

                  if (blocked || !_isOnline) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.block,
                              size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            blocked
                                ? 'الحساب موقوف مؤقتاً لبلوغ حد المستحقات'
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
                      const Text('الطلبات القريبة المتاحة:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
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
