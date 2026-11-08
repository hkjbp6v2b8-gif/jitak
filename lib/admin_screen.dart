import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// لوحة الإدارة: مراجعة السائقين وتفعيلهم
class AdminScreen extends StatelessWidget {
  const AdminScreen({Key? key}) : super(key: key);

  Future<void> _setStatus(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> ref,
    String status,
    String okText,
  ) async {
    try {
      await ref.update({'status': status});
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(okText)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تنفيذ العملية، حاول مجدداً.')),
        );
      }
    }
  }

  String _date(dynamic ts) {
    if (ts is! Timestamp) return '';
    final d = ts.toDate();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}/${two(d.month)}/${two(d.day)}';
  }

  Widget _line(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _card(
      BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final status = (d['status'] ?? 'pending').toString();
    final ref = doc.reference;

    final buttons = <Widget>[];
    if (status == 'pending') {
      buttons.add(Expanded(
        child: ElevatedButton(
          onPressed: () =>
              _setStatus(context, ref, 'approved', 'تم تفعيل السائق.'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('قبول وتفعيل',
              style: TextStyle(color: Colors.white)),
        ),
      ));
      buttons.add(const SizedBox(width: 10));
      buttons.add(Expanded(
        child: OutlinedButton(
          onPressed: () =>
              _setStatus(context, ref, 'rejected', 'تم رفض الطلب.'),
          child: const Text('رفض', style: TextStyle(color: Colors.red)),
        ),
      ));
    } else if (status == 'approved') {
      buttons.add(Expanded(
        child: OutlinedButton(
          onPressed: () =>
              _setStatus(context, ref, 'rejected', 'تم إيقاف السائق.'),
          child: const Text('إيقاف السائق',
              style: TextStyle(color: Colors.red)),
        ),
      ));
    } else {
      buttons.add(Expanded(
        child: ElevatedButton(
          onPressed: () =>
              _setStatus(context, ref, 'approved', 'تمت إعادة التفعيل.'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          child: const Text('إعادة التفعيل',
              style: TextStyle(color: Colors.white)),
        ),
      ));
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text((d['name'] ?? '').toString(),
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            _line(Icons.phone, (d['phone'] ?? '').toString()),
            _line(Icons.email_outlined, (d['email'] ?? '').toString()),
            _line(Icons.directions_car,
                '${(d['carModel'] ?? '').toString()}  •  لوحة ${(d['plateNumber'] ?? '').toString()}'),
            if (_date(d['createdAt']).isNotEmpty)
              _line(Icons.event, 'تاريخ التسجيل: ${_date(d['createdAt'])}'),
            const SizedBox(height: 10),
            Row(children: buttons),
          ],
        ),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String empty,
  ) {
    if (docs.isEmpty) {
      return Center(
        child: Text(empty, style: const TextStyle(color: Colors.grey)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: docs.map((doc) => _card(context, doc)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة الإدارة'),
          backgroundColor: Colors.teal,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'تسجيل الخروج',
              onPressed: () => FirebaseAuth.instance.signOut(),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'قيد المراجعة'),
              Tab(text: 'مفعّلون'),
              Tab(text: 'مرفوضون'),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'driver')
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(
                child: Text('تعذر تحميل السائقين. تحقق من الصلاحيات والاتصال.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey)),
              );
            }
            if (!snap.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.teal));
            }

            final docs = snap.data!.docs.toList();
            docs.sort((a, b) {
              final ta = a.data()['createdAt'];
              final tb = b.data()['createdAt'];
              if (ta is! Timestamp || tb is! Timestamp) return 0;
              return tb.compareTo(ta);
            });

            List<QueryDocumentSnapshot<Map<String, dynamic>>> byStatus(
                String s) {
              return docs
                  .where((d) => (d.data()['status'] ?? 'pending') == s)
                  .toList();
            }

            return TabBarView(
              children: [
                _list(context, byStatus('pending'), 'لا توجد طلبات جديدة.'),
                _list(context, byStatus('approved'), 'لا يوجد سائقون مفعّلون.'),
                _list(context, byStatus('rejected'), 'لا يوجد سائقون مرفوضون.'),
              ],
            );
          },
        ),
      ),
    );
  }
}
// نهاية الملف
