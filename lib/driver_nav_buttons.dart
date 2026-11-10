import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// أزرار فتح المسار في خرائط جوجل: إلى العميل، وإلى الوجهة
class DriverNavButtons extends StatefulWidget {
  final String rideId;

  const DriverNavButtons({Key? key, required this.rideId}) : super(key: key);

  @override
  State<DriverNavButtons> createState() => _DriverNavButtonsState();
}

class _DriverNavButtonsState extends State<DriverNavButtons> {
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .snapshots();
  }

  Future<void> _open(GeoPoint point) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${point.latitude},${point.longitude}',
      'travelmode': 'driving',
    });
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) _snack();
    } catch (_) {
      if (mounted) _snack();
    }
  }

  void _snack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذر فتح خرائط جوجل.')),
    );
  }

  Widget _button(String label, IconData icon, GeoPoint? point) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: point == null ? null : () => _open(point),
        icon: Icon(icon, color: Colors.blue.shade700, size: 18),
        label: Text(label, style: TextStyle(color: Colors.blue.shade700)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.blue.shade700),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        final d = snap.data?.data();
        final pickup = d?['pickup'];
        final dest = d?['destinationPoint'];
        final GeoPoint? pickupPoint = pickup is GeoPoint ? pickup : null;
        final GeoPoint? destPoint = dest is GeoPoint ? dest : null;

        if (pickupPoint == null && destPoint == null) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('فتح الملاحة في خرائط جوجل:',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [
                _button('إلى العميل', Icons.person_pin_circle, pickupPoint),
                const SizedBox(width: 10),
                _button('إلى الوجهة', Icons.flag, destPoint),
              ],
            ),
          ],
        );
      },
    );
  }
}
// نهاية الملف
