import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// زر فتح المسار في خرائط جوجل: إلى العميل قبل البدء، وإلى الوجهة بعده
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        final d = snap.data?.data();
        if (d == null) return const SizedBox.shrink();

        final started = d.containsKey('startedAt');
        final raw = started ? d['destinationPoint'] : d['pickup'];
        final GeoPoint? point = raw is GeoPoint ? raw : null;
        if (point == null) return const SizedBox.shrink();

        final label = started ? 'إلى الوجهة' : 'إلى العميل';
        final icon = started ? Icons.flag : Icons.person_pin_circle;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              started
                  ? 'افتح الملاحة إلى الوجهة في خرائط جوجل:'
                  : 'افتح الملاحة إلى العميل في خرائط جوجل:',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () => _open(point),
              icon: Icon(icon, color: Colors.blue.shade700, size: 18),
              label: Text(label, style: TextStyle(color: Colors.blue.shade700)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blue.shade700),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        );
      },
    );
  }
}
// نهاية الملف
