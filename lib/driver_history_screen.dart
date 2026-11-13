import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pricing.dart';

// سجل رحلات السائق
class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({Key? key}) : super(key: key);

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream =
      FirebaseFirestore.instance
          .collection('rides')
          .where('driverId',
              isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
          .snapshots();

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
      default:
        return 'جارية';
    }
  }

  Color _color(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.teal;
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
    final customer = (ride['customerName'] ?? '').toString();
    final rating = ride['rating'];
    final note = (ride['ratingNote'] ?? '').toString();

    final lines = <String>[
      _date(ride['createdAt']),
      if (km != null) '${km.toStringAsFixed(1)} كم',
    ].where((s) => s.isNotEmpty).join(' • ');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(Icons.directions_car, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((ride['destination'] ?? '').toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(lines, style: const TextStyle(fontSize: 12)),
                  if (customer.isNotEmpty)
                    Text('العميل: $customer',
                        style: const TextStyle(fontSize: 12)),
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
                  if (note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('"$note"',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic)),
                    ),
                ],
              ),
            ),
            Text('${Pricing.format(fare)} د.ل',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.teal)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل رحلاتي'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
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

          var completed = 0;
          var total = 0.0;
          for (final r in rides) {
            if (r['status'] == 'completed') {
              completed++;
              total += (r['fare'] as num?)?.toDouble() ?? 0.0;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                color: Colors.teal.shade50,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('رحلات مكتملة',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                          Text('$completed',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('إجمالي الأجرة',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                          Text('${Pricing.format(total)} د.ل',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...rides.map(_card),
            ],
          );
        },
      ),
    );
  }
}
// نهاية الملف
