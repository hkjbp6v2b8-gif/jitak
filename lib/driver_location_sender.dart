import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

// يرسل موقع السائق للعميل أثناء الرحلة الجارية
class DriverLocationSender extends StatefulWidget {
  final String rideId;

  const DriverLocationSender({Key? key, required this.rideId})
      : super(key: key);

  @override
  State<DriverLocationSender> createState() => _DriverLocationSenderState();
}

class _DriverLocationSenderState extends State<DriverLocationSender> {
  static const int updateSeconds = 5; // كل كم ثانية يُرسل الموقع

  Timer? _timer;
  bool _sending = false;
  String? _error;
  DateTime? _lastSent;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(
      const Duration(seconds: updateSeconds),
      (_) => _tick(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setError(String text) {
    if (mounted) setState(() => _error = text);
  }

  Future<void> _tick() async {
    if (_sending) return;
    _sending = true;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setError('لم يتم السماح بالوصول إلى موقعك.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 15));

      await FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .update({
        'driverLocation': GeoPoint(pos.latitude, pos.longitude),
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _error = null;
          _lastSent = DateTime.now();
        });
      }
    } catch (_) {
      _setError('تعذر إرسال موقعك. تأكد من الاتصال والموقع.');
    } finally {
      _sending = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color color;
    final IconData icon;

    if (_error != null) {
      text = _error!;
      color = Colors.orange.shade800;
      icon = Icons.warning_amber_rounded;
    } else if (_lastSent != null) {
      text = 'موقعك يُشارك مع العميل مباشرة. أبقِ هذه الشاشة مفتوحة.';
      color = Colors.green.shade700;
      icon = Icons.my_location;
    } else {
      text = 'جارٍ تحديد موقعك...';
      color = Colors.grey;
      icon = Icons.location_searching;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
// نهاية الملف
