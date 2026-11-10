import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'ride_history_screen.dart';
import 'settings_screen.dart';
import 'ride_status_screen.dart';
import 'location_map.dart';
import 'pricing.dart';
import 'routing_service.dart';
import 'fare_card.dart';
import 'geocoding_service.dart';
import 'place_search_box.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _note = TextEditingController();
  final _promo = TextEditingController();

  String _payment = 'نقداً (كاش)';
  double _discount = 0.0;
  String _promoCode = '';
  bool _loading = false;

  LatLng? _pickup; // موقع العميل الحالي
  LatLng? _destination; // الوجهة المختارة
  List<LatLng> _route = [];
  double? _km;
  bool _estimated = false; // المسافة تقديرية (تعذر جلب المسار)
  bool _routing = false;
  int _token = 0;

  // اسم المكان الذي وضعه البحث تلقائياً في خانة وصف الوجهة
  String _autoNoteText = '';

  @override
  void dispose() {
    _note.dispose();
    _promo.dispose();
    super.dispose();
  }

  void _msg(String text, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  void _applyPromo() {
    FocusScope.of(context).unfocus();
    final code = _promo.text.trim().toUpperCase();
    if (code.isEmpty) {
      _msg('يرجى إدخال كود الخصم أولاً.');
    } else if (code == 'JITAK10' || code == 'WELCOME') {
      setState(() {
        _discount = 3.0;
        _promoCode = code;
      });
      _msg('تم تطبيق الكوبون ($code)! تم خصم 3.0 د.ل', color: Colors.green);
    } else {
      _msg('كود الخصم غير صحيح أو منتهي الصلاحية!', color: Colors.red);
    }
  }

  // السعر من المسافة قبل الخصم
  double? get _routeFare => _km == null ? null : Pricing.fareForKm(_km!);

  // السعر النهائي بعد الخصم
  double? get _finalFare {
    final fare = _routeFare;
    if (fare == null) return null;
    final value = fare - _discount;
    return value > 0 ? value : 0.0;
  }

  // ضبط الوجهة وحساب المسار والمسافة
  Future<void> _setDestination(LatLng point) async {
    final pickup = _pickup;
    if (pickup == null) {
      _msg('انتظر حتى يتم تحديد موقعك الحالي أولاً.');
      return;
    }

    final token = ++_token;
    setState(() {
      _destination = point;
      _route = [];
      _km = null;
      _estimated = false;
      _routing = true;
    });

    final result = await RoutingService.getRoute(pickup, point);
    if (!mounted || token != _token) return;

    if (result != null) {
      setState(() {
        _route = result.points;
        _km = result.distanceKm;
        _estimated = false;
        _routing = false;
      });
    } else {
      // بديل: مسافة الخط المستقيم × 1.3 كتقدير
      final straight =
          const Distance().as(LengthUnit.Kilometer, pickup, point);
      setState(() {
        _route = [pickup, point];
        _km = straight * 1.3;
        _estimated = true;
        _routing = false;
      });
      _msg('تعذر جلب المسار، السعر تقديري.');
    }
  }

  // الضغط على الخريطة
  Future<void> _onMapTap(LatLng point) async {
    // إن كان الوصف من البحث السابق فنمسحه لأن الوجهة تغيّرت
    if (_autoNoteText.isNotEmpty && _note.text == _autoNoteText) {
      _note.clear();
    }
    _autoNoteText = '';
    await _setDestination(point);
  }

  // اختيار نتيجة من البحث
  Future<void> _onPlaceSelected(PlaceResult place) async {
    _autoNoteText = place.name;
    _note.text = place.name;
    await _setDestination(place.point);
  }

  // إنشاء طلب رحلة حقيقي في قاعدة البيانات
  Future<void> _requestRide() async {
    final user = FirebaseAuth.instance.currentUser;
    final pickup = _pickup;
    final destination = _destination;
    final km = _km;
    final fare = _finalFare;

    if (user == null) return;
    if (pickup == null) {
      _msg('انتظر حتى يتم تحديد موقعك الحالي.');
      return;
    }
    if (destination == null || km == null || fare == null) {
      _msg('اختر وجهتك بالبحث أو بالضغط على الخريطة أولاً!');
      return;
    }

    final note = _note.text.trim();

    setState(() => _loading = true);
    try {
      final ref = await FirebaseFirestore.instance.collection('rides').add({
        'customerId': user.uid,
        'customerName': user.displayName ?? '',
        'destination': note.isEmpty ? 'وجهة على الخريطة' : note,
        'fare': fare,
        'distanceKm': (km * 10).round() / 10,
        'paymentMethod': _payment,
        'status': 'requested',
        'pickup': GeoPoint(pickup.latitude, pickup.longitude),
        'destinationPoint':
            GeoPoint(destination.latitude, destination.longitude),
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
            tooltip: 'تاريخ الرحلات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const RideHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'الإعدادات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlaceSearchBox(
              near: _pickup,
              onSelected: _onPlaceSelected,
            ),
            const SizedBox(height: 10),
            const Text(
              'أو اضغط على الخريطة لاختيار وجهتك',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
            const SizedBox(height: 8),
            LocationMap(
              height: 300,
              destination: _destination,
              route: _route,
              onTap: _onMapTap,
              onLocated: (position) => _pickup = position,
            ),
            const SizedBox(height: 16),
            FareCard(
              note: _note,
              promo: _promo,
              payment: _payment,
              onPayment: (v) => setState(() => _payment = v),
              onApplyPromo: _applyPromo,
              onRequest: _requestRide,
              km: _km,
              routeFare: _routeFare,
              finalFare: _finalFare,
              discount: _discount,
              promoCode: _promoCode,
              estimated: _estimated,
              routing: _routing,
              loading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}
// نهاية الملف
