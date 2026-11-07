import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rating_screen.dart';

class RideStatusScreen extends StatefulWidget {
  final String rideId;

  const RideStatusScreen({Key? key, required this.rideId}) : super(key: key);

  @override
  State<RideStatusScreen> createState() => _RideStatusScreenState();
}

class _RideStatusScreenState extends State<RideStatusScreen> {
  bool _navigated = false;

  DocumentReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('rides').doc(widget.rideId);

  Future<void> _cancel() async {
    try {
      await _ref.update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر إلغاء الرحلة، حاول مجدداً.')),
      );
    }
  }

  Widget _screen({
    required Widget icon,
    required String title,
    required String subtitle,
    List<Widget> actions = const [],
  }) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حالة الرحلة'),
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 28),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _ref.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _screen(
            icon: const Icon(Icons.error_outline, size: 80, color: Colors.red),
            title: 'تعذر تحميل الرحلة',
            subtitle: 'تحقق من الاتصال وحاول مجدداً.',
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('العودة'),
              ),
            ],
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.teal)),
          );
        }

        final data = snap.data!.data();
        if (data == null) {
          return _screen(
            icon: const Icon(Icons.help_outline, size: 80, color: Colors.grey),
            title: 'الرحلة غير موجودة',
            subtitle: '',
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('العودة'),
              ),
            ],
          );
        }

        final status = (data['status'] ?? '').toString();
        final destination = (data['destination'] ?? '').toString();
        final fare = (data['fare'] as num?)?.toDouble() ?? 0.0;
        final driverName = (data['driverName'] ?? 'الكابتن').toString();
        final details =
            'الوجهة: $destination\nالتكلفة: ${fare.toStringAsFixed(1)} د.ل';

        if (status == 'completed') {
          if (!_navigated) {
            _navigated = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => RatingScreen(tripFare: fare)),
              );
            });
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.teal)),
          );
        }

        if (status == 'cancelled') {
          return _screen(
            icon: const Icon(Icons.cancel_outlined, size: 90, color: Colors.red),
            title: 'تم إلغاء الرحلة',
            subtitle: details,
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('العودة للرئيسية',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }

        if (status == 'accepted') {
          return _screen(
            icon: const Icon(Icons.directions_car, size: 90, color: Colors.teal),
            title: 'قَبِلَ $driverName رحلتك',
            subtitle: 'الكابتن في طريقه إليك.\n$details',
            actions: [
              OutlinedButton(
                onPressed: _cancel,
                child: const Text('إلغاء الرحلة',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        }

        // requested
        return _screen(
          icon: const SizedBox(
            height: 70,
            width: 70,
            child: CircularProgressIndicator(strokeWidth: 5, color: Colors.teal),
          ),
          title: 'جارٍ البحث عن كابتن...',
          subtitle: details,
          actions: [
            OutlinedButton(
              onPressed: _cancel,
              child: const Text('إلغاء الطلب',
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
// نهاية الملف
