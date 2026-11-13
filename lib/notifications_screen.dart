import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

DocumentReference<Map<String, dynamic>>? _myDoc() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;
  return FirebaseFirestore.instance.collection('users').doc(uid);
}

// أيقونة الجرس بعدّاد الإشعارات غير المقروءة
class NotificationBell extends StatefulWidget {
  final String audience; // 'drivers' أو 'customers'

  const NotificationBell({Key? key, required this.audience}) : super(key: key);

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _announcements =
      FirebaseFirestore.instance
          .collection('announcements')
          .where('audience', isEqualTo: widget.audience)
          .snapshots();

  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _me =
      _myDoc()?.snapshots() ??
          const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _me,
      builder: (context, meSnap) {
        final seenRaw = meSnap.data?.data()?['notifSeenAt'];
        final Timestamp? seen = seenRaw is Timestamp ? seenRaw : null;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _announcements,
          builder: (context, snap) {
            var count = 0;
            if (snap.hasData) {
              for (final doc in snap.data!.docs) {
                final t = doc.data()['createdAt'];
                if (t is Timestamp && (seen == null || t.compareTo(seen) > 0)) {
                  count++;
                }
              }
            }

            return IconButton(
              tooltip: 'الإشعارات',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NotificationsScreen(audience: widget.audience),
                  ),
                );
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications),
                  if (count > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// شاشة الإشعارات
class NotificationsScreen extends StatefulWidget {
  final String audience;

  const NotificationsScreen({Key? key, required this.audience})
      : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream =
      FirebaseFirestore.instance
          .collection('announcements')
          .where('audience', isEqualTo: widget.audience)
          .snapshots();

  Timestamp? _prevSeen;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _markSeen();
  }

  // نحفظ آخر مرة شاهدنا فيها الإشعارات (بعد أن نتذكر القديمة لتمييز الجديد)
  Future<void> _markSeen() async {
    final ref = _myDoc();
    if (ref != null) {
      try {
        final snap = await ref.get();
        final v = snap.data()?['notifSeenAt'];
        if (v is Timestamp) _prevSeen = v;
        await ref.update({'notifSeenAt': FieldValue.serverTimestamp()});
      } catch (_) {}
    }
    if (mounted) setState(() => _ready = true);
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
        title: const Text('الإشعارات'),
        backgroundColor: Colors.teal,
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(
                    child: Text('تعذر تحميل الإشعارات.',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.teal));
                }

                final items = snap.data!.docs.map((d) => d.data()).toList();
                items.sort((a, b) => _millis(b).compareTo(_millis(a)));

                if (items.isEmpty) {
                  return const Center(
                    child: Text('لا توجد إشعارات بعد.',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: items.map((n) {
                    final t = n['createdAt'];
                    final unread = t is Timestamp &&
                        (_prevSeen == null || t.compareTo(_prevSeen!) > 0);

                    return Card(
                      elevation: unread ? 3 : 1,
                      color: unread ? Colors.teal.shade50 : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (unread)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: CircleAvatar(
                                        radius: 4,
                                        backgroundColor: Colors.red),
                                  ),
                                Expanded(
                                  child: Text((n['title'] ?? '').toString(),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text((n['body'] ?? '').toString()),
                            const SizedBox(height: 8),
                            Text(_date(t),
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }
}
// نهاية الملف
