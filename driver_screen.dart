import 'package:flutter/material.dart';

class DriverScreen extends StatelessWidget {
  const DriverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جِيتك - لوحة السائق'),
        backgroundColor: Colors.deepOrange,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Card(
              color: Colors.orangeAccent,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الحالة: متصل وجاهز للطلبات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Icon(Icons.check_circle, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'الطلبات القريبة منك:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.local_shipping, color: Colors.deepOrange),
                      title: const Text('طلب توصيل طرد - وسط المدينة'),
                      subtitle: const Text(' المسافة: 2.5 كم | السعر: 15 د.ل'),
                      trailing: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                        child: const Text('قبول', style: TextStyle(color: Colors.white)),
                      ),
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
