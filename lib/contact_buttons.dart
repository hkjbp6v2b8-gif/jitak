import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_screen.dart';

// زرا "رقم الطرف الآخر" و"الدردشة"، ويحفظان رقم صاحب الشاشة للطرف الآخر
class ContactButtons extends StatefulWidget {
  final String rideId;
  final String me; // 'customer' أو 'driver'
  final String other; // 'driver' أو 'customer'
  final String otherLabel; // 'الكابتن' أو 'العميل'

  const ContactButtons({
    Key? key,
    required this.rideId,
    required this.me,
    required this.other,
    required this.otherLabel,
  }) : super(key: key);

  @override
  State<ContactButtons> createState() => _ContactButtonsState();
}

class _ContactButtonsState extends State<ContactButtons> {
  DocumentReference<Map<String, dynamic>> _contact(String who) =>
      FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .collection('contacts')
          .doc(who);

  @override
  void initState() {
    super.initState();
    _saveMine();
  }

  // يحفظ رقمي في الرحلة ليراه الطرف الآخر
  Future<void> _saveMine() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final phone = (snap.data()?['phone'] ?? '').toString();
      if (phone.isEmpty) return;
      await _contact(widget.me).set({
        'phone': phone,
        'name': user.displayName ?? '',
      });
    } catch (_) {
      // غير حرج: يمكن إعادة المحاولة عند فتح الشاشة مجدداً
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _showNumber() async {
    try {
      final snap = await _contact(widget.other).get();
      final phone = (snap.data()?['phone'] ?? '').toString();
      if (!mounted) return;

      if (phone.isEmpty) {
        _snack('رقم ${widget.otherLabel} غير متاح بعد، حاول بعد لحظات.');
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('رقم ${widget.otherLabel}'),
          content: Directionality(
            textDirection: TextDirection.ltr,
            child: SelectableText(
              phone,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق'),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: phone));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                _snack('تم نسخ الرقم.');
              },
              child: const Text('نسخ'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await launchUrl(Uri(scheme: 'tel', path: phone));
              },
              icon: const Icon(Icons.call, color: Colors.white, size: 18),
              label: const Text('اتصال', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
          ],
        ),
      );
    } catch (_) {
      _snack('تعذر جلب الرقم، حاول مجدداً.');
    }
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          rideId: widget.rideId,
          title: 'دردشة مع ${widget.otherLabel}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showNumber,
            icon: const Icon(Icons.phone, color: Colors.teal, size: 18),
            label: Text('رقم ${widget.otherLabel}',
                style: const TextStyle(color: Colors.teal)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.teal),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _openChat,
            icon: const Icon(Icons.chat, color: Colors.white, size: 18),
            label: const Text('دردشة', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
// نهاية الملف
