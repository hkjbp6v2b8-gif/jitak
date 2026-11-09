import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'wallet_builder.dart';

// لوحة الإدارة: مراجعة السائقين وتفعيلهم وتسجيل دفعاتهم
class AdminScreen extends StatelessWidget {
  const AdminScreen({Key? key}) : super(key: key);

  void _snack(BuildContext context, String text) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _setStatus(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> ref,
    String status,
    String okText,
  ) async {
    try {
      await ref.update({'status': status});
      _snack(context, okText);
    } catch (_) {
      _snack(context, 'تعذر تنفيذ العملية، حاول مجدداً.');
    }
  }

  // تسجيل دفعة من السائق للشركة (تنقص مستحقاته)
  Future<void> _recordPayment(
    BuildContext context,
    String driverId,
    String name,
    double debt,
  ) async {
    final amountController =
        TextEditingController(text: debt > 0 ? debt.toStringAsFixed(1) : '');
    final noteController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('تسجيل دفعة من $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'المبلغ المدفوع (د.ل)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration:
                  const InputDecoration(labelText: 'ملاحظة (اختياري)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('تسجيل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final amount =
        double.tryParse(amountController.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      _snack(context, 'أدخل مبلغاً صحيحاً.');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('driverPayments').add({
        'driverId': driverId,
        'amount': amount,
        'note': noteController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      _snack(context, 'تم تسجيل الدفعة.');
    } catch (_) {
      _snack(context, 'تعذر تسجيل الدفعة، حاول مجدداً.');
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

  // أزرار السائق المفعّل: المستحق + تسجيل دفعة + إيقاف
  Widget _approvedActions(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    WalletData w,
  ) {
    final name = (doc.data()['name'] ?? '').toString();
    final blocked = w.ready && w.debt >= WalletConfig.debtLimit;

    final String summary;
    if (w.loading) {
      summary = 'جارٍ حساب المستحقات...';
    } else if (w.error) {
      summary = 'تعذر حساب المستحقات.';
    } else {
      summary =
          'المستحق للشركة: ${w.debt.toStringAsFixed(1)} د.ل  •  المدفوع: ${w.paidTotal.toStringAsFixed(1)} د.ل  •  الرحلات: ${w.tripsTotal}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          summary,
          style: TextStyle(
            color: blocked ? Colors.red : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        if (blocked)
          const Text(
            'بلغ الحد الأقصى، فطلباته موقوفة في واجهته حتى يسدّد.',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: w.ready
                    ? () => _recordPayment(context, doc.id, name, w.debt)
                    : null,
                icon: const Icon(Icons.payments, color: Colors.white, size: 18),
                label: const Text('تسجيل دفعة',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _setStatus(
                    context, doc.reference, 'rejected', 'تم إيقاف السائق.'),
                child: const Text('إيقاف السائق',
                    style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _card(
      BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final status = (d['status'] ?? 'pending').toString();
    final ref = doc.reference;

    final Widget actions;
    if (status == 'pending') {
      actions = Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () =>
                  _setStatus(context, ref, 'approved', 'تم تفعيل السائق.'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('قبول وتفعيل',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: () =>
                  _setStatus(context, ref, 'rejected', 'تم رفض الطلب.'),
              child: const Text('رفض', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      );
    } else if (status == 'approved') {
      actions = WalletBuilder(
        driverId: doc.id,
        builder: (context, w) => _approvedActions(context, doc, w),
      );
    } else {
      actions = ElevatedButton(
        onPressed: () =>
            _setStatus(context, ref, 'approved', 'تمت إعادة التفعيل.'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
        child: const Text('إعادة التفعيل',
            style: TextStyle(color: Colors.white)),
      );
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
            actions,
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
