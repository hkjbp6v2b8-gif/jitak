import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({Key? key}) : super(key: key);

  Widget _info(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title:
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      subtitle: Text(
        value.isEmpty ? '—' : value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _stars(double avg) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final IconData icon;
        if (avg >= i + 1) {
          icon = Icons.star;
        } else if (avg >= i + 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        return Icon(icon, color: Colors.amber, size: 28);
      }),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'حساب مفعّل';
      case 'rejected':
        return 'حساب موقوف';
      default:
        return 'قيد المراجعة';
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnap) {
          if (userSnap.hasError) {
            return const Center(
              child: Text('تعذر تحميل بياناتك.',
                  style: TextStyle(color: Colors.grey)),
            );
          }
          if (!userSnap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.teal));
          }

          final u = userSnap.data!.data() ?? {};
          final name = (u['name'] ?? '').toString();
          final status = (u['status'] ?? 'pending').toString();

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('rides')
                .where('driverId', isEqualTo: uid)
                .where('status', isEqualTo: 'completed')
                .snapshots(),
            builder: (context, rideSnap) {
              int trips = 0;
              int ratingCount = 0;
              double ratingSum = 0;

              if (rideSnap.hasData) {
                for (final doc in rideSnap.data!.docs) {
                  trips++;
                  final r = doc.data()['rating'];
                  if (r is num) {
                    ratingCount++;
                    ratingSum += r;
                  }
                }
              }
              final double? avg =
                  ratingCount == 0 ? null : ratingSum / ratingCount;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.teal.shade100,
                      child: Text(
                        name.isEmpty ? '؟' : name.characters.first,
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Center(
                    child: Chip(
                      label: Text(_statusLabel(status)),
                      backgroundColor: status == 'approved'
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (avg == null)
                            const Text('لا توجد تقييمات بعد',
                                style: TextStyle(color: Colors.grey))
                          else ...[
                            _stars(avg),
                            const SizedBox(height: 6),
                            Text(
                              '${avg.toStringAsFixed(1)} من 5  (${ratingCount} تقييم)',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                          const Divider(height: 24),
                          Text('عدد الرحلات المكتملة: $trips',
                              style: const TextStyle(fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _info(Icons.phone, 'رقم الهاتف', (u['phone'] ?? '').toString()),
                  _info(Icons.email_outlined, 'البريد الإلكتروني',
                      (u['email'] ?? '').toString()),
                  _info(Icons.directions_car, 'السيارة',
                      (u['carModel'] ?? '').toString()),
                  _info(Icons.pin, 'رقم اللوحة',
                      (u['plateNumber'] ?? '').toString()),
                  const SizedBox(height: 8),
                  const Text(
                    'لتعديل بيانات السيارة أو الهاتف تواصل مع الإدارة.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
// نهاية الملف
