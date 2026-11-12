import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'rating_screen.dart';
import 'pricing.dart';
import 'live_ride_map.dart';
import 'contact_buttons.dart';
import 'trip_phase.dart';

class RideStatusScreen extends StatefulWidget {
  final String rideId;

  const RideStatusScreen({Key? key, required this.rideId}) : super(key: key);

  @override
  State<RideStatusScreen> createState() => _RideStatusScreenState();
}

class _RideStatusScreenState extends State<RideStatusScreen> {
  bool _navigated = false;
  bool _arrivalShown = false;
  DateTime? _localArrival;

  DocumentReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('rides').doc(widget.rideId);

  LatLng? _point(dynamic v) =>
      v is GeoPoint ? LatLng(v.latitude, v.longitude) : null;

  Future<void> _cancel() async {
    try {
      await _ref.update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر إلغاء الرحلة، حاول مجدداً.')),
      );
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
        return _screen(
          icon: const SizedBox(
            height: 70,
            width: 70,
            child: CircularProgressIndicator(strokeWidth: 5, color: Colors.teal),
          ),
          title: 'جارٍ البحث عن كابتن...',
          subtitle: details,
          actions: [_cancelButton('إلغاء الطلب')],
        );
      },
    );
  }
}
// نهاية الملف
