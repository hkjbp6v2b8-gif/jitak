import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'support_chat_screen.dart';

// بلاغ جديد: وصف المشكلة ثم الإرسال إلى الدعم
class NewTicketScreen extends StatefulWidget {
  final String role; // 'driver' أو 'customer'
  final String category;
  final String? rideId;
  final String? rideSummary;

  const NewTicketScreen({
    Key? key,
    required this.role,
    required this.category,
    this.rideId,
    this.rideSummary,
  }) : super(key: key);

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final TextEditingController _text = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    final message = _text.text.trim();
    if (user == null) return;
    if (message.isEmpty) {
      _snack('اكتب تفاصيل المشكلة أولاً.');
      return;
    }

    final summary = widget.rideSummary;

    setState(() => _sending = true);
    try {
      final ref =
          await FirebaseFirestore.instance.collection('supportTickets').add({
        'userId': user.uid,
        'userName': user.displayName ?? '',
        'role': widget.role,
        'category': widget.category,
        'message': message,
        if (widget.rideId != null) 'rideId': widget.rideId,
        if (summary != null)
          'rideSummary':
              summary.length > 300 ? summary.substring(0, 300) : summary,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              TicketChatScreen(ticketId: ref.id, isAdmin: false),
        ),
      );
    } catch (_) {
      _snack('تعذر إرسال البلاغ، حاول مجدداً.');
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.rideSummary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('بلاغ جديد'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.teal.shade50,
            child: ListTile(
              leading: const Icon(Icons.support_agent, color: Colors.teal),
              title: Text(widget.category,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('نوع المشكلة'),
            ),
          ),
          if (summary != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.directions_car, color: Colors.teal),
                title: Text(summary, style: const TextStyle(fontSize: 13)),
                subtitle: const Text('الرحلة المرتبطة بالبلاغ'),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            minLines: 5,
            maxLines: 8,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: 'اشرح المشكلة بالتفصيل...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _sending ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _sending
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('إرسال البلاغ',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
          const SizedBox(height: 8),
          const Text(
            'سيصل بلاغك إلى فريق الدعم، وتتابع ردّه من صفحة المساعدة ← بلاغاتي.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
// نهاية الملف
