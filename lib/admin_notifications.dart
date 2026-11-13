import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// تبويب الإدارة: إرسال إشعار للسائقين واستعراض ما أُرسل
class AdminNotificationsView extends StatefulWidget {
  const AdminNotificationsView({Key? key}) : super(key: key);

  @override
  State<AdminNotificationsView> createState() => _AdminNotificationsViewState();
}

class _AdminNotificationsViewState extends State<AdminNotificationsView> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();
  bool _sending = false;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream =
      FirebaseFirestore.instance.collection('announcements').snapshots();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _confirm(String title, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('نعم', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _send() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty || body.isEmpty) {
      _snack('اكتب العنوان والنص.');
      return;
    }
    if (!await _confirm('إرسال الإشعار', 'سيصل إلى جميع السائقين. متابعة؟')) {
      return;
    }

    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': title,
        'body': body,
        'audience': 'drivers',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _title.clear();
      _body.clear();
      _snack('تم إرسال الإشعار للسائقين.');
    } catch (_) {
      _snack('تعذر إرسال الإشعار، حاول مجدداً.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(DocumentReference<Map<String, dynamic>> ref) async {
    if (!await _confirm('حذف الإشعار', 'سيختفي من عند السائقين. متابعة؟')) {
      return;
    }
    try {
      await ref.delete();
    } catch (_) {
      _snack('تعذر الحذف، حاول مجدداً.');
    }
  }

  String _date(dynamic ts) {
    if (ts is! Timestamp) return '';
    final d = ts.toDate();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}/${two(d.month)}/${two(d.day)}  ${two(d.hour)}:${two(d.minute)}';
  }

  int _millis(Map<String, dynamic> d) {
    final t = d['createdAt'];
    return t is Timestamp
        ? t.millisecondsSinceEpoch
        : DateTime.now().millisecondsSinceEpoch;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إشعارات السائقين'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('إرسال إشعار جديد',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _title,
                    maxLength: 100,
                    decoration: const InputDecoration(labelText: 'العنوان'),
                  ),
                  TextField(
                    controller: _body,
                    maxLength: 1000,
                    maxLines: 4,
                    minLines: 2,
                    decoration: const InputDecoration(labelText: 'النص'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    label: const Text('إرسال لجميع السائقين',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('ما تم إرساله',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) {
                return const Text('تعذر تحميل الإشعارات.',
                    style: TextStyle(color: Colors.grey));
              }
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.teal));
              }

              final docs = snap.data!.docs.toList();
              docs.sort((a, b) => _millis(b.data()).compareTo(_millis(a.data())));

              if (docs.isEmpty) {
                return const Text('لم تُرسل إشعارات بعد.',
                    style: TextStyle(color: Colors.grey));
              }

              return Column(
                children: docs.map((doc) {
                  final n = doc.data();
                  final audience =
                      n['audience'] == 'customers' ? 'العملاء' : 'السائقون';
                  return Card(
                    elevation: 1,
                    child: ListTile(
                      title: Text((n['title'] ?? '').toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${(n['body'] ?? '').toString()}\n$audience • ${_date(n['createdAt'])}'),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () => _delete(doc.reference),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
// نهاية الملف
