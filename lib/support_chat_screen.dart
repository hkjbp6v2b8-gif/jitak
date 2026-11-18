import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// محادثة بلاغ الدعم: بين صاحب البلاغ والإدارة
class TicketChatScreen extends StatefulWidget {
  final String ticketId;
  final bool isAdmin;

  const TicketChatScreen({
    Key? key,
    required this.ticketId,
    required this.isAdmin,
  }) : super(key: key);

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  late final DocumentReference<Map<String, dynamic>> _ticketRef =
      FirebaseFirestore.instance
          .collection('supportTickets')
          .doc(widget.ticketId);

  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _ticketStream =
      _ticketRef.snapshots();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream =
      _ticketRef
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.set(_ticketRef.collection('messages').doc(), {
        'senderId': _uid,
        'sender': widget.isAdmin ? 'admin' : 'user',
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(_ticketRef, {'updatedAt': FieldValue.serverTimestamp()});
      await batch.commit();
      _controller.clear();
    } catch (_) {
      _snack('تعذر إرسال الرسالة. قد يكون البلاغ مغلقاً.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _setStatus(String status) async {
    try {
      await _ticketRef.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      _snack('تعذر تنفيذ العملية، حاول مجدداً.');
    }
  }

  String _time(dynamic ts) {
    if (ts is! Timestamp) return '';
    final d = ts.toDate();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.month)}/${two(d.day)}  ${two(d.hour)}:${two(d.minute)}';
  }

  Widget _bubble(String text,
      {required bool mine, required String label, required String time}) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: mine ? Colors.teal : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label.isNotEmpty)
              Text(label,
                  style: TextStyle(
                      color: mine ? Colors.white70 : Colors.teal.shade800,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            Text(text,
                style: TextStyle(
                    color: mine ? Colors.white : Colors.black87,
                    fontSize: 15)),
            const SizedBox(height: 2),
            Text(time,
                style: TextStyle(
                    color: mine ? Colors.white70 : Colors.black45,
                    fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _header(Map<String, dynamic> t) {
    final closed = t['status'] == 'closed';
    final ride = (t['rideSummary'] ?? '').toString();
    final role = t['role'] == 'driver' ? 'سائق' : 'عميل';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text((t['category'] ?? '').toString(),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: (closed ? Colors.grey : Colors.orange)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(closed ? 'مغلق' : 'مفتوح',
                      style: TextStyle(
                          color: closed ? Colors.grey : Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
              ],
            ),
            if (widget.isAdmin)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('من: ${(t['userName'] ?? '').toString()} ($role)',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            if (ride.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car,
                        size: 16, color: Colors.teal),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(ride, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _inputBar(bool closed) {
    if (closed && !widget.isAdmin) {
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          color: Colors.grey.shade200,
          child: const Text(
            'تم إغلاق هذا البلاغ. لفتح بلاغ جديد ارجع إلى صفحة المساعدة.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLength: 1000,
                minLines: 1,
                maxLines: 4,
                buildCounter: (context,
                        {required currentLength,
                        required isFocused,
                        maxLength}) =>
                    null,
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.teal,
              child: IconButton(
                icon: _sending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _sending ? null : _send,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _ticketStream,
      builder: (context, tSnap) {
        if (tSnap.hasError) {
          return Scaffold(
            appBar: AppBar(
                title: const Text('المحادثة'), backgroundColor: Colors.teal),
            body: const Center(
              child: Text('تعذر تحميل البلاغ.',
                  style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        final ticket = tSnap.data?.data();
        if (ticket == null) {
          return Scaffold(
            appBar: AppBar(
                title: const Text('المحادثة'), backgroundColor: Colors.teal),
            body: const Center(
                child: CircularProgressIndicator(color: Colors.teal)),
          );
        }

        final closed = ticket['status'] == 'closed';
        final userName = (ticket['userName'] ?? '').toString();

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.isAdmin ? 'بلاغ' : 'المحادثة مع الدعم'),
            backgroundColor: Colors.teal,
            actions: [
              if (widget.isAdmin)
                IconButton(
                  tooltip: closed ? 'إعادة فتح البلاغ' : 'إغلاق البلاغ',
                  icon: Icon(closed ? Icons.lock_open : Icons.check_circle),
                  onPressed: () => _setStatus(closed ? 'open' : 'closed'),
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _messagesStream,
                  builder: (context, mSnap) {
                    final docs = mSnap.data?.docs ?? [];

                    // القائمة معكوسة: الأحدث في الأسفل، والبلاغ الأصلي في الأعلى
                    final children = <Widget>[
                      for (final d in docs)
                        _bubble(
                          (d.data()['text'] ?? '').toString(),
                          mine: widget.isAdmin
                              ? d.data()['sender'] == 'admin'
                              : d.data()['sender'] == 'user',
                          label: (widget.isAdmin
                                  ? d.data()['sender'] != 'admin'
                                  : d.data()['sender'] == 'admin')
                              ? (widget.isAdmin ? userName : 'الدعم')
                              : '',
                          time: _time(d.data()['createdAt']),
                        ),
                      _bubble(
                        (ticket['message'] ?? '').toString(),
                        mine: !widget.isAdmin,
                        label: widget.isAdmin ? userName : '',
                        time: _time(ticket['createdAt']),
                      ),
                      _header(ticket),
                    ];

                    return ListView(
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      children: children,
                    );
                  },
                ),
              ),
              _inputBar(closed),
            ],
          ),
        );
      },
    );
  }
}
// نهاية الملف
