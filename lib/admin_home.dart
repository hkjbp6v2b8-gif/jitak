import 'package:flutter/material.dart';
import 'admin_screen.dart';
import 'admin_payment_requests.dart';

// واجهة الإدارة: السائقون + طلبات السداد
class AdminHome extends StatefulWidget {
  const AdminHome({Key? key}) : super(key: key);

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          AdminScreen(),
          PaymentRequestsView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: Colors.teal,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'السائقون'),
          BottomNavigationBarItem(
              icon: Icon(Icons.sim_card), label: 'طلبات السداد'),
        ],
      ),
    );
  }
}
// نهاية الملف
