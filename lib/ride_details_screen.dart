import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'ride_map.dart';
import 'pricing.dart';

// تفاصيل الطلب للسائق قبل القبول
class RideDetailsScreen extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic> ride;

  const RideDetailsScreen({
    Key? key,
    required this.rideId,
    required this.ride,
  }) : super(key: key);

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  bool _loading = false;

  LatLng? _point(dynamic value) {
    if (value is GeoPoint) return LatLng(value.latitude, value.longitude);
    return null;
  }

  Future<void> _accept() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final name =
        (user.displayName ?? '').isEmpty ? 'الكابتن' : user.displayName;

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .update({
        'status': 'accepted',
        'driverId': user.uid,
        'driverName': name,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تعذر قبول الرحلة (ربما قبلها سائق آخر).')),
      );
      setState(() => _loading = false);
    }
  }

  Widget _info(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final pickup = _point(ride['pickup']);
    final destination = _point(ride['destinationPoint']);
    final fare = (ride['fare'] as num?)?.toDouble() ?? 0.0;
    final km = (ride['distanceKm'] as num?)?.toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pickup != null && destination != null)
            RideMap(
              key: ValueKey(widget.rideId),
              pickup: pickup,
              destination: destination,
              height: 280,
            )
          else
            Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'لا توجد إحداثيات لهذه الرحلة (طلب قديم).',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _info(Icons.person,
                      'العميل: ${(ride['customerName'] ?? '').toString()}'),
                  _info(Icons.flag,
                      'الوجهة: ${(ride['destination'] ?? '').toString()}'),
                  if (km != null)
                    _info(Icons.straighten,
                        'المسافة: ${km.toStringAsFixed(1)} كم'),
                  _info(Icons.payments,
                      'التكلفة: ${Pricing.format(fare)} د.ل'),
                  _info(Icons.account_balance_wallet,
                      'الدفع: ${(ride['paymentMethod'] ?? '').toString()}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _accept,
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
                : const Text('قبول الرحلة',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
// نهاية الملف
