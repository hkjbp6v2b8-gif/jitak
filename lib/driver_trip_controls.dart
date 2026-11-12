import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'trip_phase.dart';

// أزرار مراحل الرحلة عند السائق: وصلت ← بدء الرحلة
class DriverTripControls extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> ride;

  const DriverTripControls({
    Key? key,
    required this.rideId,
    required this.ride,
  }) : super(key: key);

  @override
  State<DriverTripControls> createState() => _DriverTripControlsState();
}

class _DriverTripControlsState extends State<DriverTripControls> {
  bool _busy = false;
  DateTime? _localArrival;

  DocumentReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('rides').doc(widget.rideId);

  bool get _started => widget.ride.containsKey('startedAt');
  bool get _arrived => widget.ride.containsKey('arrivedAt');

  DateTime? get _arrivedAt {
    final v = widget.ride['arrivedAt'];
    if (v is Timestamp) return v.toDate();
    if (_arrived) {
      // الوقت لم يصل من الخادم بعد: نستخدم وقت الضغط محلياً
      _localArrival ??= DateTime.now();
      return _localArrival;
    }
    return null;
  }

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _arrive() async {
    setState(() => _busy = true);
    try {
      _localArrival = DateTime.now();
      await _ref.update({'arrivedAt': FieldValue.serverTimestamp()});
    } catch (_) {
      _msg('تعذر تسجيل الوصول، حاول مجدداً.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() async {
    final arrivedAt = _arrivedAt;
    if (arrivedAt == null) return;

    final fare = (widget.ride['fare'] as num?)?.toDouble() ?? 0.0;
    final waitFee =
        WaitConfig.feeDue(arrivedAt, DateTime.now()) ? WaitConfig.fee : 0;

    setState(() => _busy = true);
    try {
      await _ref.update({
        'startedAt': FieldValue.serverTimestamp(),
        'waitFee': waitFee,
        'fare': fare + waitFee,
      });
      if (waitFee > 0) {
        _msg('أُضيف رسم تأخير ${WaitConfig.fee} د.ل إلى الأجرة.');
      }
    } catch (_) {
      _msg('تعذر بدء الرحلة. إن كان العميل قد تأخر للتو فانتظر لحظات ثم أعد المحاولة.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _button(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: _busy ? null : onTap,
      icon: _busy
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : Icon(icon, color: Colors.white),
      label: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 3) بدأت الرحلة
    if (_started) {
      final wait = (widget.ride['waitFee'] as num?)?.toInt() ?? 0;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.directions_car, color: Colors.green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                wait > 0
                    ? 'بدأت الرحلة. توجّه إلى الوجهة. (شامل رسم انتظار $wait د.ل)'
                    : 'بدأت الرحلة. توجّه إلى الوجهة.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    // 2) وصلت: عدّاد الانتظار + بدء الرحلة
    final arrivedAt = _arrivedAt;
    if (arrivedAt != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WaitCountdown(arrivedAt: arrivedAt, forDriver: true),
          const SizedBox(height: 10),
          _button('بدء الرحلة', Icons.play_arrow, Colors.teal, _start),
        ],
      );
    }

    // 1) في الطريق إلى العميل
    return _button(
      'وصلت إلى العميل',
      Icons.location_on,
      Colors.blue.shade700,
      _arrive,
    );
  }
}
// نهاية الملف
