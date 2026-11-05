import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'driver_screen.dart';

void main() {
  runApp(const JitakApp());
}

class JitakApp extends StatelessWidget {
  const JitakApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'جِيتك - Jitak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Cairo',
      ),
      // هنا نجعل الصفحة الرئيسية تعرض زر للتنقل بين الشاشتين بسهولة
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تطبيق جِيتك - القائمة الرئيسية'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'أهلاً بك في تطبيق جِيتك للتوصيل',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.styleFrom().let((_) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('دخول واجهة العميل', style: TextStyle(fontSize: 18, color: Colors.white)),
                )),
            const SizedBox(height: 20),
            ElevatedButton.styleFrom().let((_) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DriverScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('دخول لوحة السائق', style: TextStyle(fontSize: 18, color: Colors.white)),
                )),
          ],
        ),
      ),
    );
  }
}
