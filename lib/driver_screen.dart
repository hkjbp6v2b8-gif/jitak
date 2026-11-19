import 'dart:async';
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
import 'request_config.dart';
import 'sound_service.dart';

typedef _Docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>;
typedef _Snap = AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>;

// طلب مفتوح ضمن نطاق السائق، مع بُعده عنه
class _NearbyRequest {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final double km;

  const _NearbyRequest(this.doc, this.km);
}

class DriverScreen extends StatefulWidget {
  const DriverScreen({Key? key}) : super(key: key);

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  bool _isOnline = true;
  LatLng? _me; // موقع السائق الحالي
  Timer? _ticker;
  bool _hasOpen = false;

  // الطلبات التي نبّهنا السائق إليها (لتنبيه الجديد فقط)
  final Set<String> _knownRequests = {};

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

    // نحدّث الشاشة كل ثانيتين لإخفاء الطلبات التي انتهت مهلتها
    _ticker = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted && _hasOpen) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    SoundService.disable();
    super.dispose();
  }

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  LatLng? _point(dynamic v) =>
      v is GeoPoint ? LatLng(v.latitude, v.longitude) : null;

  // موقع السائق من الخريطة (نحدّث عند التحرك أكثر من 30 متراً)
  void _onLocation(LatLng p) {
    final last = _me;
    if (last == null || const Distance().as(LengthUnit.Meter, last, p) > 30) {
      setState(() => _me = p);
    }
  }

  // الطلبات المفتوحة: ضمن نصف القطر، ولم تنتهِ مهلتها، مرتبة بالأقرب
  List<_NearbyRequest> _nearby(_Docs docs) {
    final me = _me;
    if (me == null) return [];

    final now = DateTime.now();
    final result = <_NearbyRequest>[];

    for (final doc in docs) {
      final data = doc.data();
      final pickup = _point(data['pickup']);
      if (pickup == null) continue;

      final created = data['createdAt'];
      if (created is Timestamp) {
        final age = now.difference(created.toDate()).inSeconds;
        if (age > RequestConfig.timeoutSeconds + 2) continue;
      }

      final km = const Distance().as(LengthUnit.Kilometer, me, pickup);
      if (km > RequestConfig.radiusKm) continue;

      result.add(_NearbyRequest(doc, km));
    }

    result.sort((a, b) => a.km.compareTo(b.km));
    return result;
  }

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

  // تفعيل/تجربة صوت تنبيه الطلبات
  Widget _soundBanner() {
    if (!SoundService.enabled) {
      return Card(
        color: Colors.orange.shade50,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.orange.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const Icon(Icons.volume_off, color: Colors.orange),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('صوت التنبيه غير مفعّل. فعّله لتسمع الطلبات الجديدة.',
                    style: TextStyle(fontSize: 12)),
              ),
              ElevatedButton(
                onPressed: () async {
                  await SoundService.enable();
                  if (mounted) setState(() {});
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('تفعيل',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        const Icon(Icons.volume_up, color: Colors.teal, size: 20),
        const SizedBox(width: 6),
        const Expanded(
          child: Text('صوت التنبيه مفعّل',
              style: TextStyle(color: Colors.teal, fontSize: 13)),
        ),
        TextButton(onPressed: SoundService.test, child: const Text('تجربة')),
        TextButton(
          onPressed: () {
            SoundService.disable();
            setState(() {});
          },
          child: const Text('إيقاف', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  // بطاقة المحفظة: الرصيد أو المستحق للشركة
  Widget _walletCard(WalletData w, bool blocked) {
    final hasCredit = w.ready && w.credit > 0;
    final color = blocked ? Colors.red : (hasCredit ? Colors.green : Colors.teal);
    final limit = WalletConfig.debtLimit;
    final rate = (WalletConfig.commissionRate * 100).round();

    final String info;
    if (w.loading) {
      info = 'جارٍ تحميل المحفظة...';
    } else if (w.error) {
      info = 'تعذر تحميل المحفظة. تحقق من الاتصال.';
    } else if (w.credit > 0) {
      info =
          'رصيدك: +${w.credit.toStringAsFixed(1)} د.ل (تُخصم منه عمولة رحلاتك تلقائياً)';
    } else if (w.debt > 0) {
      info =
          'المستحق للشركة (عمولة $rate%): ${w.debt.toStringAsFixed(1)} د.ل من ${limit.toStringAsFixed(0)} د.ل';
    } else {
      info = 'لا مستحقات عليك حالياً.';
    }

    return Card(
      elevation: 2,
      color: blocked
          ? Colors.red.shade50
          : (hasCredit ? Colors.green.shade50 : Colors.teal.shade50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.5), width: 1.2),
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

  Widget _requestTile(_NearbyRequest r) {
    final ride = r.doc.data();
    final fare = (ride['fare'] as num?)?.toDouble() ?? 0.0;
    final km = (ride['distanceKm'] as num?)?.toDouble();
    final tripKm = km == null ? '' : 'رحلة ${km.toStringAsFixed(1)} كم • ';

    return Card(
      elevation: 2,
      child: ListTile(
        onTap: () => _openDetails(r.doc.id, ride),
        leading: const CircleAvatar(
          backgroundColor: Colors.tealAccent,
          child: Icon(Icons.person, color: Colors.teal),
        ),
        title: Text('رحلة إلى: ${(ride['destination'] ?? '').toString()}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            'العميل يبعد عنك ${r.km.toStringAsFixed(1)} كم\n$tripKm${Pricing.format(fare)} د.ل • ${(ride['paymentMethod'] ?? '').toString()}'),
        isThreeLine: true,
        trailing: ElevatedButton(
          onPressed: () => _openDetails(r.doc.id, ride),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          child: const Text('عرض', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _note(Widget child) {
    return Padding(padding: const EdgeInsets.all(24), child: Center(child: child));
  }

  // محتوى اللوحة السفلية: الرحلة الجارية، أو الطلبات القريبة
  List<Widget> _ridesSection(
    _Docs activeDocs,
    List<_NearbyRequest> nearby,
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
        _note(const Text('تعذر تحميل الطلبات. تحقق من الاتصال.',
            style: TextStyle(color: Colors.grey))),
      ];
    }
    if (!open.hasData) {
      return [
        _note(const CircularProgressIndicator(color: Colors.teal)),
      ];
    }
    if (_me == null) {
      return [
        _note(const Text('جارٍ تحديد موقعك لعرض الطلبات القريبة منك...',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey))),
      ];
    }
    if (nearby.isEmpty) {
      return [
        _note(Text(
          'لا توجد طلبات ضمن ${RequestConfig.radiusKm.toStringAsFixed(0)} كم منك حالياً. سيظهر أي طلب جديد قريب هنا وعلى الخريطة فوراً.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        )),
      ];
    }

    return [
      Text(
          'الطلبات ضمن ${RequestConfig.radiusKm.toStringAsFixed(0)} كم منك:',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...nearby.map(_requestTile),
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

    final _Docs openDocs = open.data?.docs ?? [];
    _hasOpen = openDocs.isNotEmpty;

    final bool showRequests = !hasActive && _isOnline && !blocked;
    final nearby = showRequests ? _nearby(openDocs) : <_NearbyRequest>[];

    // صوت تنبيه عند ظهور طلب قريب جديد
    final currentIds = nearby.map((r) => r.doc.id).toSet();
    final fresh = currentIds.difference(_knownRequests);
    _knownRequests
      ..clear()
      ..addAll(currentIds);
    if (fresh.isNotEmpty && SoundService.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => SoundService.notify());
    }

    // دبابيس الطلبات القريبة على الخريطة
    final markers = <MapRequest>[];
    for (final r in nearby) {
      final point = _point(r.doc.data()['pickup']);
      if (point == null) continue;
      final fare = (r.doc.data()['fare'] as num?)?.toDouble() ?? 0.0;
      markers.add(MapRequest(r.doc.id, point, '${Pricing.format(fare)} د.ل'));
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
              onLocation: _onLocation,
              onRequestTap: (id) {
                for (final r in nearby) {
                  if (r.doc.id == id) {
                    _openDetails(r.doc.id, r.doc.data());
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
                              ? 'تظهر لك الطلبات القريبة على الخريطة'
                              : 'لن تصلك طلبات')),
                      value: blocked ? false : _isOnline,
                      activeColor: Colors.teal,
                      onChanged:
                          blocked ? null : (v) => setState(() => _isOnline = v),
                    ),
                    _soundBanner(),
                    const SizedBox(height: 8),
                    _walletCard(wallet, blocked),
                    const SizedBox(height: 12),
                    ..._ridesSection(activeDocs, nearby, open, blocked),
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
