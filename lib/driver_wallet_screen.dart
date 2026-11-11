import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'wallet_builder.dart';
import 'payment_dialog.dart';

String _date(dynamic ts) {
  if (ts is! Timestamp) return '';
  final d = ts.toDate();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}/${two(d.month)}/${two(d.day)}';
}

class DriverWalletScreen extends StatelessWidget {
  const DriverWalletScreen({Key? key}) : super(key: key);

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final rate = (WalletConfig.commissionRate * 100).round();
    final limit = WalletConfig.debtLimit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المحفظة والأرباح'),
        backgroundColor: Colors.teal,
      ),
      body: WalletBuilder(
        driverId: uid,
        builder: (context, w) {
          if (w.loading) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.teal));
          }
          if (w.error) {
            return const Center(
              child: Text('تعذر تحميل المحفظة. تحقق من الاتصال.',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          final blocked = w.debt >= limit;
          final color = blocked ? Colors.red : Colors.teal;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 4,
                color: Colors.teal.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.teal.shade200, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('صافي أرباح اليوم (بعد العمولة)',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('${w.netToday.toStringAsFixed(1)} د.ل',
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal)),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _stat('رحلات اليوم', '${w.tripsToday}'),
                          _stat('صافي آخر 7 أيام',
                              '${w.netWeek.toStringAsFixed(1)} د.ل'),
                          _stat('كل الرحلات', '${w.tripsTotal}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 3,
                color: blocked ? Colors.red.shade50 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                      color: blocked ? Colors.red : Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('المستحق للشركة (عمولة $rate%)',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('${w.debt.toStringAsFixed(1)} د.ل',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: color)),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (w.debt / limit).clamp(0.0, 1.0).toDouble(),
                        backgroundColor: Colors.grey.shade300,
                        color: color,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'إجمالي العمولة: ${w.commissionTotal.toStringAsFixed(1)} د.ل  •  المدفوع: ${w.paidTotal.toStringAsFixed(1)} د.ل',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        blocked
                            ? 'بلغ المستحق الحد الأقصى (${limit.toStringAsFixed(0)} د.ل). سدّد ليُعاد تفعيل استقبال الطلبات.'
                            : 'الحد الأقصى للدين ${limit.toStringAsFixed(0)} د.ل.',
                        style: TextStyle(
                            color: blocked ? Colors.red : Colors.grey,
                            fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: w.debt > 0
                            ? () => showPayDialog(context, debt: w.debt)
                            : null,
                        icon: const Icon(Icons.sim_card,
                            color: Colors.white, size: 18),
                        label: const Text('سداد المستحقات بكرت شحن',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _RequestsList(uid: uid),
              const SizedBox(height: 20),
              const Text('سجل الدفعات المعتمدة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (w.payments.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('لا توجد دفعات مسجلة بعد.',
                      style: TextStyle(color: Colors.grey)),
                )
              else
                ...w.payments.map((p) {
                  final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
                  final note = (p['note'] ?? '').toString();
                  return Card(
                    elevation: 1,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.tealAccent,
                        child: Icon(Icons.payments, color: Colors.teal),
                      ),
                      title: Text(note.isEmpty ? 'دفعة للشركة' : note,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_date(p['createdAt'])),
                      trailing: Text('- ${amount.toStringAsFixed(1)} د.ل',
                          style: const TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold)),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

// طلبات السداد بالكروت التي أرسلها السائق وحالتها
class _RequestsList extends StatefulWidget {
  final String uid;

  const _RequestsList({Key? key, required this.uid}) : super(key: key);

  @override
  State<_RequestsList> createState() => _RequestsListState();
}

class _RequestsListState extends State<_RequestsList> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream =
      FirebaseFirestore.instance
          .collection('paymentRequests')
          .where('driverId', isEqualTo: widget.uid)
          .snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snap.data!.docs.map((d) => d.data()).toList();
        docs.sort((a, b) {
          final ta = a['createdAt'];
          final tb = b['createdAt'];
          if (ta is! Timestamp || tb is! Timestamp) return 0;
          return tb.compareTo(ta);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('طلبات السداد بالكروت',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...docs.map((r) {
              final status = (r['status'] ?? 'pending').toString();
              final amount = (r['amount'] as num?)?.toDouble();

              final String statusText;
              final Color statusColor;
              if (status == 'approved') {
                statusText = 'تم الخصم';
                statusColor = Colors.green;
              } else if (status == 'rejected') {
                statusText = 'مرفوض';
                statusColor = Colors.red;
              } else {
                statusText = 'قيد المراجعة';
                statusColor = Colors.orange;
              }

              return Card(
                elevation: 1,
                child: ListTile(
                  leading: Icon(Icons.sim_card, color: statusColor),
                  title: Text(
                      'كرت ${providerLabel((r['provider'] ?? '').toString())} ${maskCard((r['cardNumber'] ?? '').toString())}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${_date(r['createdAt'])}  •  $statusText',
                      style: TextStyle(color: statusColor, fontSize: 12)),
                  trailing: status == 'approved' && amount != null
                      ? Text('- ${amount.toStringAsFixed(1)} د.ل',
                          style: const TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.bold))
                      : null,
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
// نهاية الملف
