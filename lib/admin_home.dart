import 'package:flutter/material.dart';
import 'admin_screen.dart';
import 'admin_payment_requests.dart';
import 'admin_notifications.dart';
import 'admin_support.dart';

// واجهة الإدارة: السائقون + طلبات السداد + الإشعارات + الدعم
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
          AdminNotificationsView(),
          AdminSupportView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'السائقون'),
          BottomNavigationBarItem(
              icon: Icon(Icons.sim_card), label: 'السداد'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'الإشعارات'),
          BottomNavigationBarItem(
              icon: Icon(Icons.support_agent), label: 'الدعم'),
        ],
      ),
    );
  }
}
// نهاية الملف
