import 'package:flutter/material.dart';
import 'rating_screen.dart';

class TrackingScreen extends StatelessWidget {
  final double tripFare;

  const TrackingScreen({Key? key, this.tripFare = 15.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double commission = tripFare * 0.10; // نسبة 10%

    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع الرحلة'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.map, size: 80, color: Colors.teal),
                      const SizedBox(height: 10),
                      const Text('خريطة التتبع المباشر', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('قيمة الرحلة الحالية: ${tripFare.toStringAsFixed(1)} د.ل', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('عمولة التطبيق (10%): +${commission.toStringAsFixed(2)} د.ل', style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text('السائق: أحمد المحمودي', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('تويوتا كورولا (أبيض) • 4.9 ★'),
                    ),
                    const Divider(),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.between,
                      children: [
                        Text('حالة الرحلة:', style: TextStyle(color: Colors.grey)),
                        Text('السائق في الطريق إليك', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            label: const Text('إلغاء الرحلة', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('تم إتمام الرحلة بنجاح! تم احتساب عمولة 10% (${commission.toStringAsFixed(2)} د.ل).')),
                              );
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const RatingScreen()),
                              );
                            },
                            icon: const Icon(Icons.check_circle, color: Colors.white),
                            label: const Text('إتمام الرحلة', style: TextStyle(color: Colors.white, fontSize: 13)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
