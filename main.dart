import 'package:flutter/material.dart';
import 'home_screen.dart';

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
      home: const HomeScreen(),
    );
  }
}
