import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pricing.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({Key? key}) : super(key: key);

  String _date(dynamic ts) {
    if (ts is! Timestamp) return '';
    final d = ts.toDate();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}/${two(d.month)}/${two(d.day)}  ${two(d.hour)}:${two(d.minute)}';
  }

  String _label(String status) {
    switch (status) {
      case 'completed':
        return 'مكتملة';
      case 'cancelled':
        return 'ملغاة';
      case 'accepted':
        return 'جارية';
      default:
        return 'قيد الانتظار';
    }
  }

  Color _color(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'accepted':
        return Colors.teal;
      default:
        return Colors.orange;
    }
  }

  int _millis(Map<String, dynamic> ride) {
    final t = ride['createdAt'];
    return t is Timestamp
        ? t.millisecondsSinceEpoch
        : DateTime.now().millisecondsSinceEpoch;
  }

  Widget _card(Map<String, dynamic> ride) {
    final status = (ride['status'] ?? '').toString();
    final color = _color(status);
    final fare = (ride['fare'] as num?)?.toDouble() ?? 0.0;
    final km = (ride['distanceKm'] as num?)?.toDouble();
    final driver = (ride['driverName'] ?? '').toString();
    final rating = ride['rating'];

    final lines = <String>[
      _date(ride['createdAt']),
      if (km != null) '${km.toStringAsFixed(1)} كم',
      if (driver.isNotEmpty) 'الكابتن: $driver',
    ].where((s) => s.isNotEmpty).join(' • ');

    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.directions_car, color: color),
        ),
        title: Text((ride['destination'] ?? '').toString(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lines, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(_label(status),
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                if (rating is int) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  Text('$rating', style: const TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ],
        ),
        trailing: Text('${Pricing.format(fare)} د.ل',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.teal)),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('تاريخ الرحلات'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .where('customerId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Text('تعذر تحميل رحلاتك. تحقق من الاتصال.',
                  style: TextStyle(color: Colors.grey)),
            );
          }
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.teal));
          }

          final rides = snap.data!.docs.map((d) => d.data()).toList();
          rides.sort((a, b) => _millis(b).compareTo(_millis(a)));

          if (rides.isEmpty) {
            return const Center(
              child: Text('لا توجد رحلات سابقة بعد.',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: rides.map(_card).toList(),
          );
        },
      ),
    );
  }
}
// نهاية الملف
