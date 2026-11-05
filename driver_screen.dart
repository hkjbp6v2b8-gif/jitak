import 'package:flutter/material.dart';
import 'driver_profile_screen.dart';

class DriverScreen extends StatelessWidget {
  const DriverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جِيتك - لوحة السائق'),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DriverProfileScreen()),
              );
            },
            tooltip: 'الملف الشخصي',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              title: const Text('أنت متصل الآن (جاهز للرحلات)', style: TextStyle(fontWeight: FontWeight.bold)),
              value: true,
              activeColor: Colors.deepOrange,
              onChanged: (bool value) {},
            ),
            const Divider(height: 30),
            const Text(
              'الطلبات المتاحة بالقرب منك:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.between,
                      children: [
                        Text('طلب رحلة جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange)),
                        Text('على بُعد 1.2 كم', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Icon(Icons.my_location, size: 18, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('من: جزيرة المشرق'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.location_on, size: 18, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('إلى: وسط المدينة'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم رفض الطلب')),
                              );
                            },
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('رفض'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم قبول الرحلة بنجاح!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                            child: const Text('قبول الطلب', style: TextStyle(color: Colors.white)),
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
