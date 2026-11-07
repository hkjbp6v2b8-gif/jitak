import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverPendingScreen extends StatelessWidget {
  final String status;

  const DriverPendingScreen({Key? key, this.status = 'pending'})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool rejected = status == 'rejected';

    return Scaffold(
      appBar: AppBar(
        title: const Text('حساب الكابتن'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                rejected ? Icons.cancel_outlined : Icons.hourglass_top,
                size: 90,
                color: rejected ? Colors.red : Colors.orange,
              ),
              const SizedBox(height: 20),
              Text(
                rejected ? 'تم رفض طلبك' : 'طلبك قيد المراجعة',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                rejected
                    ? 'نعتذر، لم يتم قبول طلب انضمامك ككابتن. يمكنك التواصل مع الإدارة لمعرفة السبب.'
                    : 'استلمنا بياناتك وهي الآن قيد التدقيق من فريق الإدارة. ستتمكن من استقبال الرحلات فور تفعيل حسابك، وستنتقل هذه الشاشة تلقائياً.',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
