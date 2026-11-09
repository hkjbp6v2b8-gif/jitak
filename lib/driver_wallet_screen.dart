import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'wallet_builder.dart';

class DriverWalletScreen extends StatelessWidget {
  const DriverWalletScreen({Key? key}) : super(key: key);

  String _date(dynamic ts) {
    if (ts is! Timestamp) return '';
    final d = ts.toDate();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}/${two(d.month)}/${two(d.day)}';
  }

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
                            ? 'بلغ المستحق الحد الأقصى (${limit.toStringAsFixed(0)} د.ل). سدّد للإدارة ليُعاد تفعيل استقبال الطلبات.'
                            : 'الحد الأقصى للدين ${limit.toStringAsFixed(0)} د.ل. للتسديد تواصل مع الإدارة.',
                        style: TextStyle(
                            color: blocked ? Colors.red : Colors.grey,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('سجل الدفعات',
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
                  return Card(
                    elevation: 1,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.tealAccent,
                        child: Icon(Icons.payments, color: Colors.teal),
                      ),
                      title: const Text('دفعة للشركة',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
// نهاية الملف
