import 'package:flutter/material.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الرحلات - جِيتك'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'رحلاتك السابقة:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: const [
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.tealAccent,
                        child: Icon(Icons.directions_car, color: Colors.teal),
                      ),
                      title: Text('إلى: ميدان الشهداء', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('الكابتن: أحمد المحمودي • أمس، 03:30 م\nطريقة الدفع: نقداً (كاش)'),
                      isThreeLine: true,
                      trailing: Text('18.0 د.ل', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.tealAccent,
                        child: Icon(Icons.directions_car, color: Colors.teal),
                      ),
                      title: Text('إلى: قرقارش (جزيرة الأندلس)', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('الكابتن: خالد الزروق • 3 أيام مضت\nطريقة الدفع: محفظة إلكترونية'),
                      isThreeLine: true,
                      trailing: Text('24.5 د.ل', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.tealAccent,
                        child: Icon(Icons.directions_car, color: Colors.teal),
                      ),
                      title: Text('إلى: جزيرة الشفاء', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('الكابتن: محمد التومي • قبل أسبوع\nطريقة الدفع: نقداً (كاش)'),
                      isThreeLine: true,
                      trailing: Text('15.0 د.ل', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
