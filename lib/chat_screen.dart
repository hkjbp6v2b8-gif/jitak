import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// دردشة بين العميل والكابتن أثناء الرحلة
class ChatScreen extends StatefulWidget {
  final String rideId;
  final String title;

  const ChatScreen({Key? key, required this.rideId, required this.title})
      : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  CollectionReference<Map<String, dynamic>> get _messages => FirebaseFirestore
      .instance
      .collection('rides')
      .doc(widget.rideId)
      .collection('messages');

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await _messages.add({
        'senderId': _uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _controller.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تعذر إرسال الرسالة (ربما انتهت الرحلة).')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _time(dynamic ts) {
    if (ts is! Timestamp) return '';
    final d = ts.toDate();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}';
  }

  Widget _bubble(Map<String, dynamic> msg) {
    final mine = msg['senderId'] == _uid;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: mine ? Colors.teal : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (msg['text'] ?? '').toString(),
              style: TextStyle(
                  color: mine ? Colors.white : Colors.black87, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              _time(msg['createdAt']),
              style: TextStyle(
                  color: mine ? Colors.white70 : Colors.black45, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messages.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(
                    child: Text('تعذر تحميل الرسائل.',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.teal));
                }

                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('ابدأ المحادثة بإرسال رسالة.',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                // الأحدث في الأسفل
                return ListView(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  children: docs.map((d) => _bubble(d.data())).toList(),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLength: 500,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
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
          ),
        ],
      ),
    );
  }
}
// نهاية الملف
