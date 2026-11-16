import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'rating_screen.dart';
import 'pricing.dart';
import 'live_ride_map.dart';
import 'contact_buttons.dart';
import 'trip_phase.dart';
import 'request_config.dart';

class RideStatusScreen extends StatefulWidget {
  final String rideId;

  const RideStatusScreen({Key? key, required this.rideId}) : super(key: key);

  @override
  State<RideStatusScreen> createState() => _RideStatusScreenState();
}

class _RideStatusScreenState extends State<RideStatusScreen> {
  bool _navigated = false;
  bool _arrivalShown = false;
  bool _expiring = false;
  DateTime? _localArrival;
  DateTime? _localStart;

  DocumentReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('rides').doc(widget.rideId);

  LatLng? _point(dynamic v) =>
      v is GeoPoint ? LatLng(v.latitude, v.longitude) : null;

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _cancel() async {
    try {
      await _ref.update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelReason': 'customer',
      });
    } catch (_) {
      _snack('تعذر إلغاء الرحلة، حاول مجدداً.');
    }
  }

  // انتهت مهلة الطلب: نلغيه إن كان ما زال "requested" (لا نلغي رحلة قُبلت للتو)
  Future<void> _expire() async {
    if (_expiring) return;
    _expiring = true;
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(_ref);
        if (snap.data()?['status'] != 'requested') return;
        tx.update(_ref, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelReason': 'timeout',
        });
      });
    } catch (_) {
      _expiring = false; // نعيد المحاولة في اللحظة التالية
    }
  }

  Widget _cancelButton(String label) {
    return OutlinedButton(
      onPressed: _cancel,
      child: Text(label, style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _contactButtons() {
    return ContactButtons(
      rideId: widget.rideId,
      me: 'customer',
      other: 'driver',
      otherLabel: 'الكابتن',
    );
  }

  Widget _screen({
    required Widget icon,
    required String title,
    required String subtitle,
    List<Widget> actions = const [],
  }) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حالة الرحلة'),
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 20),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 28),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }

  Widget _back(String label) {
    return ElevatedButton(
      onPressed: () => Navigator.of(context).pop(),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _loadingScreen() {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Colors.teal)),
    );
  }

  // وقت وصول الكابتن (من الخادم، أو وقت محلي مؤقتاً)
  DateTime _arrivedAt(Map<String, dynamic> data) {
    final v = data['arrivedAt'];
    if (v is Timestamp) return v.toDate();
    _localArrival ??= DateTime.now();
    return _localArrival!;
  }

  // إشعار داخل التطبيق: وصل الكابتن
  void _showArrivalDialog(String driverName) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.directions_car, color: Colors.teal, size: 48),
        title: Text('وصل $driverName!', textAlign: TextAlign.center),
        content: Text(
          'مدة الانتظار المجاني: ${WaitConfig.freeMinutes} دقيقة.\n'
          'ثم مهلة إضافية ${WaitConfig.extraMinutes} دقائق، وبعدها يُضاف ${WaitConfig.fee} د.ل إلى أجرة الرحلة.',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('حسناً', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // شريط المرحلة: عدّاد الانتظار، أو "بدأت رحلتك"
  Widget? _phaseBanner(Map<String, dynamic> data) {
    if (data.containsKey('startedAt')) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.directions_car, color: Colors.green),
            SizedBox(width: 10),
            Expanded(
              child: Text('بدأت رحلتك. نتمنى لك رحلة سعيدة.',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
    if (data.containsKey('arrivedAt')) {
      return WaitCountdown(arrivedAt: _arrivedAt(data), forDriver: false);
    }
    return null;
  }

  // بعد قبول الرحلة: مراحلها + خريطة مباشرة + أزرار التواصل
  Widget _acceptedView(
      Map<String, dynamic> data, String driverName, String details) {
    final pickup = _point(data['pickup']);
    final dest = _point(data['destinationPoint']);
    final driver = _point(data['driverLocation']);
    final started = data.containsKey('startedAt');
    final arrived = data.containsKey('arrivedAt');

    // أول مرة نرى فيها وصول الكابتن: نافذة تنبيه
    if (arrived && !started && !_arrivalShown) {
      _arrivalShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showArrivalDialog(driverName);
      });
    }

    final banner = _phaseBanner(data);
    final String title = started
        ? 'رحلتك جارية'
        : (arrived ? 'وصل $driverName' : 'قَبِلَ $driverName رحلتك');

    // طلب قديم بلا إحداثيات
    if (pickup == null || dest == null) {
      return _screen(
        icon: const Icon(Icons.directions_car, size: 90, color: Colors.teal),
        title: title,
        subtitle: started ? details : 'الكابتن في طريقه إليك.\n$details',
        actions: [
          if (banner != null) ...[banner, const SizedBox(height: 12)],
          _contactButtons(),
          if (!started) ...[
            const SizedBox(height: 12),
            _cancelButton('إلغاء الرحلة'),
          ],
        ],
      );
    }

    String? distanceText;
    if (!arrived && !started) {
      if (driver == null) {
        distanceText = 'جارٍ انتظار موقع الكابتن...';
      } else {
        final km = const Distance().as(LengthUnit.Kilometer, driver, pickup);
        distanceText = 'الكابتن يبعد عنك نحو ${km.toStringAsFixed(1)} كم';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('حالة الرحلة'),
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (banner != null) ...[banner, const SizedBox(height: 12)],
          LiveRideMap(
            pickup: pickup,
            destination: dest,
            driver: driver,
            height: 300,
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          if (distanceText != null) ...[
            const SizedBox(height: 8),
            Text(distanceText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.teal,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ],
          const SizedBox(height: 8),
          Text(details,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 16),
          _contactButtons(),
          if (!started) ...[
            const SizedBox(height: 12),
            Center(child: _cancelButton('إلغاء الرحلة')),
          ],
        ],
      ),
    );
  }

  // البحث عن كابتن: عدّاد المهلة
  Widget _requestedView(Map<String, dynamic> data, String details) {
    final created = data['createdAt'];
    final DateTime start = created is Timestamp
        ? created.toDate()
        : (_localStart ??= DateTime.now());

    return _screen(
      icon: _SearchCountdown(start: start, onExpire: _expire),
      title: 'جارٍ البحث عن كابتن...',
      subtitle:
          'نعرض طلبك على الكباتن القريبين، وإن لم يقبله أحد خلال ${RequestConfig.timeoutSeconds} ثانية يُلغى تلقائياً.\n$details',
      actions: [_cancelButton('إلغاء الطلب')],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _ref.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _screen(
            icon: const Icon(Icons.error_outline, size: 80, color: Colors.red),
            title: 'تعذر تحميل الرحلة',
            subtitle: 'تحقق من الاتصال وحاول مجدداً.',
            actions: [_back('العودة')],
          );
        }
        if (!snap.hasData) return _loadingScreen();

        final data = snap.data!.data();
        if (data == null) {
          return _screen(
            icon: const Icon(Icons.help_outline, size: 80, color: Colors.grey),
            title: 'الرحلة غير موجودة',
            subtitle: '',
            actions: [_back('العودة')],
          );
        }

        final status = (data['status'] ?? '').toString();
        final destination = (data['destination'] ?? '').toString();
        final fare = (data['fare'] as num?)?.toDouble() ?? 0.0;
        final waitFee = (data['waitFee'] as num?)?.toInt() ?? 0;
        final driverName = (data['driverName'] ?? 'الكابتن').toString();

        var details =
            'الوجهة: $destination\nالتكلفة: ${Pricing.format(fare)} د.ل';
        if (waitFee > 0) {
          details += '\n(شامل رسم انتظار $waitFee د.ل)';
        }

        if (status == 'completed') {
          if (!_navigated) {
            _navigated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      RatingScreen(tripFare: fare, rideId: widget.rideId),
                ),
              );
            });
          }
          return _loadingScreen();
        }

        if (status == 'cancelled') {
          // انتهت مهلة الطلب بلا كابتن
          if (data['cancelReason'] == 'timeout') {
            return _screen(
              icon: const Icon(Icons.search_off, size: 90, color: Colors.orange),
              title: 'لم يتوفر كابتن حالياً',
              subtitle:
                  'لم يقبل أحد طلبك خلال ${RequestConfig.timeoutSeconds} ثانية. جرّب مرة أخرى، فقد يتوفر كابتن قريب.',
              actions: [_back('إعادة المحاولة')],
            );
          }
          return _screen(
            icon: const Icon(Icons.cancel_outlined, size: 90, color: Colors.red),
            title: 'تم إلغاء الرحلة',
            subtitle: details,
            actions: [_back('العودة للرئيسية')],
          );
        }

        if (status == 'accepted') {
          return _acceptedView(data, driverName, details);
        }

        // requested
        return _requestedView(data, details);
      },
    );
  }
}

// عدّاد دائري لمهلة الطلب: ينتهي فيُلغى الطلب تلقائياً
class _SearchCountdown extends StatefulWidget {
  final DateTime start;
  final VoidCallback onExpire;

  const _SearchCountdown({
    Key? key,
    required this.start,
    required this.onExpire,
  }) : super(key: key);

  @override
  State<_SearchCountdown> createState() => _SearchCountdownState();
}

class _SearchCountdownState extends State<_SearchCountdown> {
  Timer? _timer;

  int get _remaining =>
      RequestConfig.timeoutSeconds -
      DateTime.now().difference(widget.start).inSeconds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _remaining <= 0) widget.onExpire();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (_remaining <= 0) widget.onExpire();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = _remaining.clamp(0, RequestConfig.timeoutSeconds);

    return SizedBox(
      height: 80,
      width: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 80,
            width: 80,
            child: CircularProgressIndicator(
              value: r / RequestConfig.timeoutSeconds,
              strokeWidth: 6,
              color: Colors.teal,
              backgroundColor: Colors.grey.shade300,
            ),
          ),
          Text('$r',
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
// نهاية الملف
