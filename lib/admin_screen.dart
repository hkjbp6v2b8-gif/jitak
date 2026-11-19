import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_screen.dart';
import 'admin_payment_requests.dart';
import 'admin_notifications.dart';
import 'admin_support.dart';

// واجهة الإدارة: السائقون + السداد + الإشعارات + الدعم (مع عدّادات)
class AdminHome extends StatefulWidget {
  const AdminHome({Key? key}) : super(key: key);

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _index = 0;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _pendingDrivers =
      FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'driver')
          .where('status', isEqualTo: 'pending')
          .snapshots();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _pendingPayments =
      FirebaseFirestore.instance
          .collection('paymentRequests')
          .where('status', isEqualTo: 'pending')
          .snapshots();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _openTickets =
      FirebaseFirestore.instance
          .collection('supportTickets')
          .where('status', isEqualTo: 'open')
          .snapshots();

  Widget _badge(IconData icon, Stream<QuerySnapshot<Map<String, dynamic>>> s) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: s,
      builder: (context, snap) {
        final n = snap.data?.docs.length ?? 0;
        return Badge(
          isLabelVisible: n > 0,
          label: Text('$n'),
          child: Icon(icon),
        );
      },
    );
  }

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
        items: [
          BottomNavigationBarItem(
              icon: _badge(Icons.groups, _pendingDrivers), label: 'السائقون'),
          BottomNavigationBarItem(
              icon: _badge(Icons.sim_card, _pendingPayments), label: 'السداد'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'الإشعارات'),
          BottomNavigationBarItem(
              icon: _badge(Icons.support_agent, _openTickets), label: 'الدعم'),
        ],
      ),
    );
  }
}
// نهاية الملف
