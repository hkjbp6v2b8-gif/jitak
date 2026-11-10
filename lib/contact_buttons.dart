import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_screen.dart';

// عند العميل: بطاقة الكابتن + زرا الرقم والدردشة
// عند السائق: زرا الرقم والدردشة فقط
// ويحفظ كل طرف بياناته للطرف الآخر داخل الرحلة
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

  // يحفظ بياناتي في الرحلة ليراها الطرف الآخر
  Future<void> _saveMine() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final db = FirebaseFirestore.instance;
      final snap = await db.collection('users').doc(user.uid).get();
      final data = snap.data() ?? {};
      final phone = (data['phone'] ?? '').toString();
      if (phone.isEmpty) return;

      final info = <String, dynamic>{
        'phone': phone,
        'name': user.displayName ?? '',
      };

      if (widget.me == 'driver') {
        info['car'] = (data['carModel'] ?? '').toString();
        info['plate'] = (data['plateNumber'] ?? '').toString();
        info['ratingCount'] = 0;
        try {
          // متوسط تقييمي من رحلاتي المكتملة
          final rides = await db
              .collection('rides')
              .where('driverId', isEqualTo: user.uid)
              .where('status', isEqualTo: 'completed')
              .get();
          var sum = 0.0;
          var count = 0;
          for (final d in rides.docs) {
            final r = d.data()['rating'];
            if (r is num) {
              sum += r;
              count++;
            }
          }
          info['ratingCount'] = count;
          if (count > 0) info['rating'] = sum / count;
        } catch (_) {
          // نكمل بدون التقييم
        }
      }

      await _contact(widget.me).set(info);
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
    final buttons = Row(
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

    if (widget.me != 'customer') return buttons;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DriverInfoCard(rideId: widget.rideId),
        buttons,
      ],
    );
  }
}

// بطاقة تعريف الكابتن للعميل: الاسم والسيارة واللوحة والتقييم
class _DriverInfoCard extends StatefulWidget {
  final String rideId;

  const _DriverInfoCard({Key? key, required this.rideId}) : super(key: key);

  @override
  State<_DriverInfoCard> createState() => _DriverInfoCardState();
}

class _DriverInfoCardState extends State<_DriverInfoCard> {
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .collection('contacts')
        .doc('driver')
        .snapshots();
  }

  Widget _stars(double avg) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final IconData icon;
        if (avg >= i + 1) {
          icon = Icons.star;
        } else if (avg >= i + 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        return Icon(icon, color: Colors.amber, size: 18);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        final d = snap.data?.data();
        if (d == null) return const SizedBox.shrink();

        final name = (d['name'] ?? '').toString();
        final car = (d['car'] ?? '').toString();
        final plate = (d['plate'] ?? '').toString();
        final count = (d['ratingCount'] as num?)?.toInt() ?? 0;
        final rating = (d['rating'] as num?)?.toDouble();

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.teal.shade100,
                  child: const Icon(Icons.person, color: Colors.teal, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.isEmpty ? 'الكابتن' : name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      if (car.isNotEmpty)
                        Text('السيارة: $car',
                            style: const TextStyle(fontSize: 13)),
                      if (plate.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black54),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('لوحة: $plate',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      const SizedBox(height: 6),
                      if (rating == null)
                        const Text('كابتن جديد (لا تقييمات بعد)',
                            style: TextStyle(color: Colors.grey, fontSize: 12))
                      else
                        Row(
                          children: [
                            _stars(rating),
                            const SizedBox(width: 6),
                            Text('${rating.toStringAsFixed(1)} ($count)',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
// نهاية الملف
