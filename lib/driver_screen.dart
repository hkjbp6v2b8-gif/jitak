import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'driver_profile_screen.dart';
import 'driver_wallet_screen.dart';
import 'ride_details_screen.dart';
import 'pricing.dart';
import 'driver_location_sender.dart';
import 'wallet_builder.dart';
import 'driver_map.dart';
import 'driver_rating_screen.dart';
import 'driver_trip_controls.dart';
import 'driver_history_screen.dart';
import 'notifications_screen.dart';
import 'contact_us_screen.dart';

typedef _Docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>;
typedef _Snap = AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>;

class DriverScreen extends StatefulWidget {
  const DriverScreen({Key? key}) : super(key: key);

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  bool _isOnline = true;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _activeStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _requestsStream;

  CollectionReference<Map<String, dynamic>> get _rides =>
      FirebaseFirestore.instance.collection('rides');

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _activeStream = _rides
        .where('driverId', isEqualTo: _uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots();
    _requestsStream =
        _rides.where('status', isEqualTo: 'requested').snapshots();
  }

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  LatLng? _point(dynamic v) =>
      v is GeoPoint ? LatLng(v.latitude, v.longitude) : null;

  // إنهاء الرحلة ثم فتح شاشة تقييم العميل
  Future<void> _complete(String rideId, Map<String, dynamic> ride) async {
    try {
      await _rides.doc(rideId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      _msg('تعذر إنهاء الرحلة، حاول مجدداً.');
      return;
    }
    if (!mounted) return;

    final fare = (ride['fare'] as num?)?.toDouble() ?? 0.0;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverRatingScreen(
          rideId: rideId,
          customerName: (ride['customerName'] ?? '').toString(),
          fare: fare,
          paymentMethod: (ride['paymentMethod'] ?? '').toString(),
        ),
      ),
    );
  }

  void _openDetails(String rideId, Map<String, dynamic> ride) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideDetailsScreen(rideId: rideId, ride: ride),
      ),
    );
  }

  // فتح شاشة من القائمة الجانبية (نغلق القائمة أولاً)
  void _go(Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.teal),
      title: Text(label,
          style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      onTap: onTap,
    );
  }

  // القائمة الجانبية: الخيارات
  Widget _drawer() {
    final user = FirebaseAuth.instance.currentUser;
    final name =
        (user?.displayName ?? '').isEmpty ? 'الكابتن' : user!.displayName!;
    final email = user?.email ?? '';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            margin: EdgeInsets.zero,
            decoration: const BoxDecoration(color: Colors.teal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.teal, size: 34),
                ),
                const SizedBox(height: 10),
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(email,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          _drawerItem(Icons.history, 'سجل رحلاتي',
              () => _go(const DriverHistoryScreen())),
          _drawerItem(Icons.notifications, 'الإشعارات',
              () => _go(const NotificationsScreen(audience: 'drivers'))),
          _drawerItem(Icons.account_balance_wallet, 'المحفظة والأرباح',
              () => _go(const DriverWalletScreen())),
          _drawerItem(Icons.person, 'الملف الشخصي',
              () => _go(const DriverProfileScreen())),
          _drawerItem(Icons.support_agent, 'تواصل معنا',
              () => _go(const ContactUsScreen())),
          const Divider(),
          _drawerItem(
            Icons.logout,
            'تسجيل الخروج',
            () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            color: Colors.red,
          ),
        ],
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
          'المستحق للشركة (عمولة $rate%): ${w.debt.toStringAsFixed(1)} د.ل من ${limit.toStringAsFixed(0)} د.ل';
    }

    return Card(
      elevation: 2,
      color: blocked ? Colors.red.shade50 : Colors.teal.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: blocked ? Colors.red : Colors.teal.shade200, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(info,
                style: TextStyle(
                  color: blocked ? Colors.red.shade700 : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                )),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: w.ready ? (w.debt / limit).clamp(0.0, 1.0).toDouble() : 0,
              backgroundColor: Colors.grey.shade300,
              color: color,
            ),
            const SizedBox(height: 6),
            Text(
              blocked
                  ? 'بلغ المستحق الحد الأقصى. سدّد ليُعاد تفعيل الاستقبال.'
                  : 'للسداد افتح المحفظة واختر "سداد بكرت شحن".',
              style: TextStyle(
                color: blocked ? Colors.red : Colors.grey,
                fontSize: 12,
                fontWeight: blocked ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 6),
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
                minimumSize: const Size(double.infinity, 34),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // الرحلة الجارية: مشاركة الموقع + الملاحة والتواصل + مراحل الرحلة
  Widget _activeCard(String rideId, Map<String, dynamic> ride) {
    final fare = (ride['fare'] as num?)?.toDouble() ?? 0.0;
    final started = ride.containsKey('startedAt');

    return Card(
      elevation: 3,
      color: Colors.teal.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.teal.shade300, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
            DriverTripControls(
                key: ValueKey('trip-$rideId'), rideId: rideId, ride: ride),
            const SizedBox(height: 10),
            Text('العميل: ${(ride['customerName'] ?? '').toString()}'),
            Text('الوجهة: ${(ride['destination'] ?? '').toString()}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('التكلفة: ${Pricing.format(fare)} د.ل'),
            Text('الدفع: ${(ride['paymentMethod'] ?? '').toString()}'),
            if (started) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _complete(rideId, ride),
                icon: const Icon(Icons.flag, color: Colors.white),
                label: const Text('إنهاء الرحلة',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _requestTile(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
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
        title: Text('رحلة إلى: ${(ride['destination'] ?? '').toString()}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '$kmText${Pricing.format(fare)} د.ل • ${(ride['paymentMethod'] ?? '').toString()}'),
        trailing: ElevatedButton(
          onPressed: () => _openDetails(doc.id, ride),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          child: const Text('عرض', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  // محتوى اللوحة السفلية: الرحلة الجارية، أو الطلبات المفتوحة
  List<Widget> _ridesSection(
    _Docs activeDocs,
    _Docs openDocs,
    _Snap open,
    bool blocked,
  ) {
    if (activeDocs.isNotEmpty) {
      final doc = activeDocs.first;
      return [_activeCard(doc.id, doc.data())];
    }

    if (blocked || !_isOnline) {
      return [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.block, size: 50, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                blocked
                    ? 'الحساب موقوف مؤقتاً لبلوغ حد المستحقات'
                    : 'أنت غير متصل حالياً',
                style: const TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ];
    }

    if (open.hasError) {
      return [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('تعذر تحميل الطلبات. تحقق من الاتصال.',
                style: TextStyle(color: Colors.grey)),
          ),
        ),
      ];
    }
    if (!open.hasData) {
      return [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(color: Colors.teal)),
        ),
      ];
    }
    if (openDocs.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'لا توجد طلبات حالياً. سيظهر أي طلب جديد هنا وعلى الخريطة فوراً.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ];
    }

    return [
      const Text('الطلبات القريبة المتاحة:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...openDocs.map(_requestTile),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return WalletBuilder(
      driverId: _uid,
      builder: (context, wallet) {
        final blocked = wallet.ready && wallet.debt >= WalletConfig.debtLimit;
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _activeStream,
          builder: (context, active) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _requestsStream,
              builder: (context, open) =>
                  _page(wallet, blocked, active, open),
            );
          },
        );
      },
    );
  }

  Widget _page(WalletData wallet, bool blocked, _Snap active, _Snap open) {
    final _Docs activeDocs = active.data?.docs ?? [];
    final bool hasActive = activeDocs.isNotEmpty;

    final _Docs openDocs = (open.data?.docs ?? []).toList();
    openDocs.sort((a, b) {
      final ta = a.data()['createdAt'] as Timestamp?;
      final tb = b.data()['createdAt'] as Timestamp?;
      if (ta == null || tb == null) return 0;
      return tb.compareTo(ta);
    });

    final bool showRequests = !hasActive && _isOnline && !blocked;

    // دبابيس الطلبات على الخريطة
    final markers = <MapRequest>[];
    if (showRequests) {
      for (final doc in openDocs) {
        final point = _point(doc.data()['pickup']);
        if (point == null) continue;
        final fare = (doc.data()['fare'] as num?)?.toDouble() ?? 0.0;
        markers.add(MapRequest(doc.id, point, '${Pricing.format(fare)} د.ل'));
      }
    }

    final activeRide = hasActive ? activeDocs.first.data() : null;

    final String statusText;
    final Color statusColor;
    if (hasActive) {
      statusText = 'رحلة جارية';
      statusColor = Colors.teal;
    } else if (blocked) {
      statusText = 'موقوف: بلغ حد المستحقات';
      statusColor = Colors.red;
    } else if (_isOnline) {
      statusText = 'متصل • بانتظار الطلبات';
      statusColor = Colors.green.shade700;
    } else {
      statusText = 'غير متصل';
      statusColor = Colors.grey.shade700;
    }

    return Scaffold(
      drawer: _drawer(),
      appBar: AppBar(
        title: const Text('لوحة السائق'),
        backgroundColor: Colors.teal,
        actions: [
          const NotificationBell(audience: 'drivers'),
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
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DriverMap(
              statusText: statusText,
              statusColor: statusColor,
              requests: markers,
              onRequestTap: (id) {
                for (final doc in openDocs) {
                  if (doc.id == id) {
                    _openDetails(doc.id, doc.data());
                    return;
                  }
                }
              },
              pickup: _point(activeRide?['pickup']),
              destination: _point(activeRide?['destinationPoint']),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.14,
            maxChildSize: 0.92,
            builder: (context, controller) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(blurRadius: 12, color: Colors.black26)
                  ],
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('أنا متصل لاستقبال الرحلات',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(blocked
                          ? 'متوقف تلقائياً بسبب المستحقات'
                          : (_isOnline
                              ? 'تظهر لك الطلبات على الخريطة'
                              : 'لن تصلك طلبات')),
                      value: blocked ? false : _isOnline,
                      activeColor: Colors.teal,
                      onChanged:
                          blocked ? null : (v) => setState(() => _isOnline = v),
                    ),
                    _walletCard(wallet, blocked),
                    const SizedBox(height: 12),
                    ..._ridesSection(activeDocs, openDocs, open, blocked),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
// نهاية الملف
