import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'support_chat_screen.dart';

// تبويب الإدارة: بلاغات الدعم (مفتوحة ومغلقة)
class AdminSupportView extends StatefulWidget {
  const AdminSupportView({Key? key}) : super(key: key);

  @override
  State<AdminSupportView> createState() => _AdminSupportViewState();
}

class _AdminSupportViewState extends State<AdminSupportView> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream =
      FirebaseFirestore.instance.collection('supportTickets').snapshots();

  String _date(dynamic ts) {
    if (ts is! Timestamp) return '';
    final d = ts.toDate();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}/${two(d.month)}/${two(d.day)}  ${two(d.hour)}:${two(d.minute)}';
  }

  int _millis(Map<String, dynamic> d) {
    final t = d['updatedAt'];
    return t is Timestamp
        ? t.millisecondsSinceEpoch
        : DateTime.now().millisecondsSinceEpoch;
  }

  Widget _tile(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final t = doc.data();
    final closed = t['status'] == 'closed';
    final role = t['role'] == 'driver' ? 'سائق' : 'عميل';
    final hasRide = (t['rideSummary'] ?? '').toString().isNotEmpty;
    final message = (t['message'] ?? '').toString();

    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              (closed ? Colors.grey : Colors.orange).withOpacity(0.15),
          child: Icon(
            closed ? Icons.check : Icons.mark_chat_unread,
            color: closed ? Colors.grey : Colors.orange.shade800,
          ),
        ),
        title: Text((t['category'] ?? '').toString(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${(t['userName'] ?? '').toString()} ($role)'
          '${hasRide ? ' • مرتبط برحلة' : ''}\n'
          '${message.length > 70 ? '${message.substring(0, 70)}...' : message}\n'
          '${_date(t['updatedAt'])}',
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_left),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TicketChatScreen(ticketId: doc.id, isAdmin: true),
            ),
          );
        },
      ),
    );
  }

  Widget _list(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String empty,
  ) {
    if (docs.isEmpty) {
      return Center(
        child: Text(empty, style: const TextStyle(color: Colors.grey)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: docs.map(_tile).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        final docs = snap.data?.docs.toList() ?? [];
        docs.sort((a, b) => _millis(b.data()).compareTo(_millis(a.data())));

        final open = docs.where((d) => d.data()['status'] != 'closed').toList();
        final closed =
            docs.where((d) => d.data()['status'] == 'closed').toList();

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('الدعم'),
              backgroundColor: Colors.teal,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'تسجيل الخروج',
                  onPressed: () => FirebaseAuth.instance.signOut(),
                ),
              ],
              bottom: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(text: 'مفتوحة (${open.length})'),
                  const Tab(text: 'مغلقة'),
                ],
              ),
            ),
            body: snap.hasError
                ? const Center(
                    child: Text('تعذر تحميل البلاغات. تحقق من الصلاحيات.',
                        style: TextStyle(color: Colors.grey)),
                  )
                : !snap.hasData
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.teal))
                    : TabBarView(
                        children: [
                          _list(open, 'لا توجد بلاغات مفتوحة.'),
                          _list(closed, 'لا توجد بلاغات مغلقة.'),
                        ],
                      ),
          ),
        );
      },
    );
  }
}
// نهاية الملف
