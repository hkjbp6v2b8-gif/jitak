import 'package:flutter/material.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع الرحلة'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // محاكاة لخريطة التتبع
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 80, color: Colors.teal),
                      SizedBox(height: 10),
                      Text('خريطة التتبع المباشر (قريباً)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // بطاقة معلومات السائق والرحلة
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('جارٍ الاتصال بالسائق...')),
                              );
                            },
                            icon: const Icon(Icons.phone, color: Colors.white),
                            label: const Text('اتصال', style: TextStyle(color: Colors.white)),
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
