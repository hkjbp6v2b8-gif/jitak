import 'package:flutter/material.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تاريخ الرحلات'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildRideHistoryCard(
              date: 'اليوم، 02:30 م',
              from: 'جزيرة المشرق',
              to: 'وسط المدينة',
              price: '15 د.ل',
              status: 'مكتملة',
              statusColor: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildRideHistoryCard(
              date: 'أمس، 08:15 م',
              from: 'شارع الزاوية',
              to: 'حي الأندلس',
              price: '25 د.ل',
              status: 'مكتملة',
              statusColor: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildRideHistoryCard(
              date: '20 أكتوبر، 11:00 ص',
              from: 'مطار معيتيقة',
              to: 'السياحية',
              price: '40 د.ل',
              status: 'ملغاة',
              statusColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideHistoryCard({
    required String date,
    required String from,
    required String to,
    required String price,
    required String status,
    required Color statusColor,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.my_location, size: 18, color: Colors.teal),
                const SizedBox(width: 8),
                Text('من: $from', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.redAccent),
                const SizedBox(width: 8),
                Text('إلى: $to', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'التكلفة: $price',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
