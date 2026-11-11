import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_dialog.dart';

typedef _Doc = QueryDocumentSnapshot<Map<String, dynamic>>;

// تبويب الإدارة: طلبات السداد بكروت الشحن
class PaymentRequestsView extends StatefulWidget {
  const PaymentRequestsView({Key? key}) : super(key: key);

  @override
  State<PaymentRequestsView> createState() => _PaymentRequestsViewState();
}

class _PaymentRequestsViewState extends State<PaymentRequestsView> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream =
      FirebaseFirestore.instance.collection('paymentRequests').snapshots();

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _date(dynamic ts) {
    if (ts is! Timestamp) return '';
    final d = ts.toDate();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}/${two(d.month)}/${two(d.day)}  ${two(d.hour)}:${two(d.minute)}';
  }

  int _millis(Map<String, dynamic> d) {
    final t = d['createdAt'];
    return t is Timestamp ? t.millisecondsSinceEpoch : 0;
  }

  // تأكيد الكرت: تدخل قيمته فتُخصم من مستحقات السائق
  Future<void> _approve(_Doc doc) async {
    final d = doc.data();
    final provider = (d['provider'] ?? '').toString();
    final controller = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('تأكيد كرت ${providerLabel(provider)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('السائق: ${(d['driverName'] ?? '').toString()}'),
            const SizedBox(height: 8),
            const Text(
              'اشحن الكرت أولاً وتأكد أنه صحيح، ثم أدخل قيمته لتُخصم من مستحقات السائق.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'قيمة الكرت (د.ل)'),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('تأكيد وخصم',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final amount =
        double.tryParse(controller.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      _snack('أدخل قيمة صحيحة.');
      return;
    }

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      batch.set(db.collection('driverPayments').doc(), {
        'driverId': d['driverId'],
        'amount': amount,
        'note': 'سداد بكرت ${providerLabel(provider)}',
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(doc.reference, {
        'status': 'approved',
        'amount': amount,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      _snack('تم الخصم من مستحقات السائق.');
    } catch (_) {
      _snack('تعذر تنفيذ العملية، ربما عولج الطلب مسبقاً.');
    }
  }

  Future<void> _reject(_Doc doc) async {
    try {
      await doc.reference.update({
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
      });
      _snack('تم رفض الطلب.');
    } catch (_) {
      _snack('تعذر تنفيذ العملية، حاول مجدداً.');
    }
  }

  Widget _card(_Doc doc, int dupCount) {
    final d = doc.data();
    final status = (d['status'] ?? 'pending').toString();
    final provider = (d['provider'] ?? '').toString();
    final number = (d['cardNumber'] ?? '').toString();
    final amount = (d['amount'] as num?)?.toDouble();
    final pending = status == 'pending';
    final providerColor =
        provider == 'libyana' ? Colors.deepPurple : Colors.orange.shade800;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text((d['driverName'] ?? '').toString(),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: providerColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('كرت ${providerLabel(provider)}',
                      style: TextStyle(
                          color: providerColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: pending
                        ? SelectableText(number,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5))
                        : Text(maskCard(number),
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey)),
                  ),
                ),
                if (pending)
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.teal),
                    tooltip: 'نسخ الرقم',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: number));
                      _snack('تم نسخ الرقم.');
                    },
                  ),
              ],
            ),
            Text(_date(d['createdAt']),
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            if (pending && dupCount > 1)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'تحذير: هذا الرقم أُرسل أكثر من مرة. قد يكون الكرت مستخدماً.',
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 10),
            if (pending)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approve(doc),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: const Text('تأكيد وخصم',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _reject(doc),
                      child: const Text('رفض',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              )
            else
              Text(
                status == 'approved'
                    ? 'تم خصم ${(amount ?? 0).toStringAsFixed(1)} د.ل'
                    : 'مرفوض',
                style: TextStyle(
                  color: status == 'approved' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات السداد بالكروت'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Text('تعذر تحميل الطلبات. تحقق من الصلاحيات والاتصال.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
            );
          }
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.teal));
          }

          final docs = snap.data!.docs.toList();
          if (docs.isEmpty) {
            return const Center(
              child: Text('لا توجد طلبات سداد بعد.',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          // كشف تكرار أرقام الكروت
          final counts = <String, int>{};
          for (final doc in docs) {
            final d = doc.data();
            final key = '${d['provider']}:${d['cardNumber']}';
            counts[key] = (counts[key] ?? 0) + 1;
          }

          final pending = docs
              .where((d) => (d.data()['status'] ?? 'pending') == 'pending')
              .toList()
            ..sort((a, b) => _millis(a.data()).compareTo(_millis(b.data())));
          final done = docs
              .where((d) => (d.data()['status'] ?? 'pending') != 'pending')
              .toList()
            ..sort((a, b) => _millis(b.data()).compareTo(_millis(a.data())));

          Widget cardFor(_Doc doc) {
            final d = doc.data();
            final key = '${d['provider']}:${d['cardNumber']}';
            return _card(doc, counts[key] ?? 1);
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text('قيد المراجعة (${pending.length})',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (pending.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('لا توجد طلبات جديدة.',
                      style: TextStyle(color: Colors.grey)),
                )
              else
                ...pending.map(cardFor),
              if (done.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('تمت معالجتها',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...done.map(cardFor),
              ],
            ],
          );
        },
      ),
    );
  }
}
// نهاية الملف
