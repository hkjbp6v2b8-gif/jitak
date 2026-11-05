import 'package:flutter/material.dart';

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
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تطبيق جِيتك للتوصيل'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'أهلاً بك في تطبيق جِيتك',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
