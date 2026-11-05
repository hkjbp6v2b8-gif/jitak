import 'package:flutter/material.dart';
import 'tracking_screen.dart';
import 'ride_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _destinationController = TextEditingController();
  String _selectedPaymentMethod = 'نقداً (كاش)';
  double _estimatedFare = 15.0; // التكلفة الافتراضية للرحلة

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جِيتك - اطلب مشوارك'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RideHistoryScreen()),
              );
            },
            tooltip: 'تاريخ الرحلات',
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // محاكاة الخريطة في الواجهة الرئيسية
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
                      Icon(Icons.location_on, size: 70, color: Colors.teal),
                      SizedBox(height: 10),
                      Text('أنت هنا (موقعك الحالي)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // بطاقة طلب الرحلة وإدخال الوجهة
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إلى أين تريد الذهاب؟',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _destinationController,
                      decoration: InputDecoration(
                        hintText: 'اكتب وجهتك (مثلاً: ميدان الشهداء، قرقارش...)',
                        prefixIcon: const Icon(Icons.search, color: Colors.teal),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (value) {
                        // محاكاة تغيير التكلفة بناءً على الوجهة
                        setState(() {
                          _estimatedFare = 12.0 + (value.length * 1.5);
                          if (_estimatedFare > 45.0) _estimatedFare = 45.0;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.between,
                      children: [
                        const Text('التكلفة التقديرية:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        Text('${_estimatedFare.toStringAsFixed(1)} د.ل', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.between,
                      children: [
                        const Text('طريقة الدفع:', style: TextStyle(fontWeight: FontWeight.bold)),
                        DropdownButton<String>(
                          value: _selectedPaymentMethod,
                          items: <String>['نقداً (كاش)', 'محفظة إلكترونية'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedPaymentMethod = newValue!;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_destinationController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('الرجاء إدخال وجهتك أولاً!')),
                          );
                          return;
                        }
                        // الانتقال لشاشة تتبع الرحلة والبحث عن كابتن
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TrackingScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('بحث عن كابتن الآن', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
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
