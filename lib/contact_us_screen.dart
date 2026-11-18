import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'support_config.dart';
import 'support_new_ticket.dart';
import 'support_chat_screen.dart';
import 'pricing.dart';

class _RideItem {
  final String id;
  final Map<String, dynamic> data;

  const _RideItem(this.id, this.data);
}

String _date(dynamic ts) {
  if (ts is! Timestamp) return '';
  final d = ts.toDate();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}/${two(d.month)}/${two(d.day)}  ${two(d.hour)}:${two(d.minute)}';
}

String _statusLabel(String s) {
  switch (s) {
    case 'completed':
      return 'مكتملة';
    case 'cancelled':
      return 'ملغاة';
    case 'accepted':
      return 'جارية';
    default:
      return 'قيد الانتظار';
  }
}

Color _statusColor(String s) {
  switch (s) {
    case 'completed':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    case 'accepted':
      return Colors.teal;
    default:
      return Colors.orange;
  }
}

// شاشة المساعدة: آخر رحلة + خيارات المشكلة + البلاغات
class ContactUsScreen extends StatefulWidget {
  final String? role; // 'driver' أو 'customer' (وإلا نكتشفه تلقائياً)

  const ContactUsScreen({Key? key, this.role}) : super(key: key);

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  static const _driverIssues = <List<Object>>[
    ['مشكلة في دفع أجرة الرحلة', Icons.payments],
    ['إرسال ملاحظات عن الراكب', Icons.rate_review],
    ['الراكب ألغى الرحلة', Icons.cancel],
    ['مشكلة في السعر أو المسافة', Icons.route],
  ];

  static const _customerIssues = <List<Object>>[
    ['مشكلة في أجرة الرحلة', Icons.payments],
    ['إرسال ملاحظات عن الكابتن', Icons.rate_review],
    ['الكابتن لم يصل أو ألغى الرحلة', Icons.cancel],
    ['نسيت شيئاً في السيارة', Icons.luggage],
  ];

  static const _driverGeneral = <String>[
    'مشكلة في تسجيل الدخول أو الحساب',
    'مشكلة في المحفظة أو السداد بالكروت',
    'مشكلة في الخريطة أو الموقع',
    'مشكلة في استقبال الطلبات',
    'اقتراح لتحسين التطبيق',
    'أخرى',
  ];

  static const _customerGeneral = <String>[
    'مشكلة في تسجيل الدخول أو الحساب',
    'مشكلة في الخريطة أو الموقع',
    'مشكلة في طلب الرحلة',
    'اقتراح لتحسين التطبيق',
    'أخرى',
  ];

  String? _role;
  List<_RideItem> _rides = [];
  _RideItem? _selected;
  bool _loading = true;
  bool _failed = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  int _millis(Map<String, dynamic> d) {
    final t = d['createdAt'];
    return t is Timestamp
        ? t.millisecondsSinceEpoch
        : DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final db = FirebaseFirestore.instance;
      var role = widget.role;
      if (role == null) {
        final snap = await db.collection('users').doc(_uid).get();
        role = (snap.data()?['role'] ?? 'customer').toString();
      }

      final field = role == 'driver' ? 'driverId' : 'customerId';
      final q =
          await db.collection('rides').where(field, isEqualTo: _uid).get();

      final items = q.docs.map((d) => _RideItem(d.id, d.data())).toList();
      items.sort((a, b) => _millis(b.data).compareTo(_millis(a.data)));

      if (!mounted) return;
      setState(() {
        _role = role;
        _rides = items;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  String _summary(_RideItem r) {
    final fare = (r.data['fare'] as num?)?.toDouble() ?? 0.0;
    return 'رحلة إلى ${(r.data['destination'] ?? '').toString()} • ${Pricing.format(fare)} د.ل • ${_date(r.data['createdAt'])}';
  }

  void _openTicket(String category, {_RideItem? ride}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewTicketScreen(
          role: _role ?? 'customer',
          category: category,
          rideId: ride?.id,
          rideSummary: ride == null ? null : _summary(ride),
        ),
      ),
    );
  }

  Future<void> _pickRide() async {
    final picked = await Navigator.push<_RideItem>(
      context,
      MaterialPageRoute(
        builder: (context) => _RidePickerScreen(rides: _rides),
      ),
    );
    if (picked != null && mounted) setState(() => _selected = picked);
  }

  void _allProblems() {
    final items = _role == 'driver' ? _driverGeneral : _customerGeneral;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('جميع المشاكل',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ),
            ...items.map(
              (label) => ListTile(
                title: Text(label),
                trailing: const Icon(Icons.chevron_left),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openTicket(label);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rideInfo(_RideItem ride) {
    final d = ride.data;
    final status = (d['status'] ?? '').toString();
    final fare = (d['fare'] as num?)?.toDouble() ?? 0.0;
    final km = (d['distanceKm'] as num?)?.toDouble();
    final other = _role == 'driver'
        ? (d['customerName'] ?? '').toString()
        : (d['driverName'] ?? '').toString();
    final otherLabel = _role == 'driver' ? 'العميل' : 'الكابتن';

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_statusLabel(status),
                    style: TextStyle(
                        color: _statusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
              const Spacer(),
              Text('${Pricing.format(fare)} د.ل',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal)),
            ],
          ),
          const SizedBox(height: 8),
          Text((d['destination'] ?? '').toString(),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            [
              _date(d['createdAt']),
              if (km != null) '${km.toStringAsFixed(1)} كم',
            ].where((s) => s.isNotEmpty).join(' • '),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          if (other.isNotEmpty)
            Text('$otherLabel: $other', style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _issueTile(String label, IconData icon, _RideItem? ride) {
    return Column(
      children: [
        const Divider(height: 1),
        ListTile(
          leading: Icon(icon, color: Colors.teal),
          title: Text(label,
              style: const TextStyle(
                  color: Colors.teal, fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.chevron_left, color: Colors.grey),
          onTap: () => _openTicket(label, ride: ride),
        ),
      ],
    );
  }

  Widget _rideCard(_RideItem? ride) {
    final issues = _role == 'driver' ? _driverIssues : _customerIssues;

    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ride != null)
            _rideInfo(ride)
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('لا توجد رحلات سابقة بعد.',
                  style: TextStyle(color: Colors.grey)),
            ),
          ...issues.map(
            (i) => _issueTile(i[0] as String, i[1] as IconData, ride),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.list_alt, color: Colors.teal),
            title: const Text('جميع المشاكل',
                style: TextStyle(
                    color: Colors.teal, fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.chevron_left, color: Colors.grey),
            onTap: _allProblems,
          ),
        ],
      ),
    );
  }

  Future<void> _open(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) _fail();
    } catch (_) {
      if (mounted) _fail();
    }
  }

  void _fail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذر فتح الرابط.')),
    );
  }

  // قنوات إضافية (إن عبّأتها في support_config.dart)
  List<Widget> _otherChannels() {
    final tiles = <Widget>[];

    if (SupportConfig.phone.isNotEmpty) {
      tiles.add(ListTile(
        leading: const Icon(Icons.call, color: Colors.teal),
        title: const Text('اتصال هاتفي'),
        subtitle: Text(SupportConfig.phone, textDirection: TextDirection.ltr),
        onTap: () => _open(Uri(scheme: 'tel', path: SupportConfig.phone)),
      ));
    }
    if (SupportConfig.whatsapp.isNotEmpty) {
      tiles.add(ListTile(
        leading: const Icon(Icons.chat, color: Colors.green),
        title: const Text('واتساب'),
        subtitle:
            Text(SupportConfig.whatsapp, textDirection: TextDirection.ltr),
        onTap: () => _open(Uri.https('wa.me', '/${SupportConfig.whatsapp}')),
      ));
    }
    if (SupportConfig.email.isNotEmpty) {
      tiles.add(ListTile(
        leading: const Icon(Icons.email, color: Colors.blue),
        title: const Text('البريد الإلكتروني'),
        subtitle: Text(SupportConfig.email, textDirection: TextDirection.ltr),
        onTap: () => _open(Uri(scheme: 'mailto', path: SupportConfig.email)),
      ));
    }

    if (tiles.isEmpty) return [];

    return [
      const SizedBox(height: 20),
      const Text('قنوات أخرى للتواصل',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      if (SupportConfig.hours.isNotEmpty)
        Text('ساعات العمل: ${SupportConfig.hours}',
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 4),
      Card(child: Column(children: tiles)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar:
            AppBar(title: const Text('مساعدة'), backgroundColor: Colors.teal),
        body: const Center(
            child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    if (_failed) {
      return Scaffold(
        appBar:
            AppBar(title: const Text('مساعدة'), backgroundColor: Colors.teal),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('تعذر تحميل البيانات. تحقق من الاتصال.',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    }

    final ride = _selected ?? (_rides.isEmpty ? null : _rides.first);

    return Scaffold(
      appBar:
          AppBar(title: const Text('مساعدة'), backgroundColor: Colors.teal),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_selected != null ? 'الرحلة المحددة' : 'آخر رحلة لك',
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _rideCard(ride),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _rides.isEmpty ? null : _pickRide,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('عرض جميع الرحلات',
                style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
          const SizedBox(height: 20),
          _MyTickets(uid: _uid),
          ..._otherChannels(),
        ],
      ),
    );
  }
}

// اختيار رحلة أخرى للإبلاغ عنها
class _RidePickerScreen extends StatelessWidget {
  final List<_RideItem> rides;

  const _RidePickerScreen({Key? key, required this.rides}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shown = rides.take(50).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر الرحلة'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: shown.map((r) {
          final status = (r.data['status'] ?? '').toString();
          final fare = (r.data['fare'] as num?)?.toDouble() ?? 0.0;
          return Card(
            child: ListTile(
              title: Text((r.data['destination'] ?? '').toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${_date(r.data['createdAt'])}  •  ${_statusLabel(status)}',
                  style: TextStyle(color: _statusColor(status), fontSize: 12)),
              trailing: Text('${Pricing.format(fare)} د.ل',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.teal)),
              onTap: () => Navigator.pop(context, r),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// بلاغاتي: بلاغات المستخدم وحالتها
class _MyTickets extends StatefulWidget {
  final String uid;

  const _MyTickets({Key? key, required this.uid}) : super(key: key);

  @override
  State<_MyTickets> createState() => _MyTicketsState();
}

class _MyTicketsState extends State<_MyTickets> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream =
      FirebaseFirestore.instance
          .collection('supportTickets')
          .where('userId', isEqualTo: widget.uid)
          .snapshots();

  int _millis(Map<String, dynamic> d) {
    final t = d['updatedAt'];
    return t is Timestamp
        ? t.millisecondsSinceEpoch
        : DateTime.now().millisecondsSinceEpoch;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snap.data!.docs.toList();
        docs.sort((a, b) => _millis(b.data()).compareTo(_millis(a.data())));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('بلاغاتي',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...docs.map((doc) {
              final t = doc.data();
              final closed = t['status'] == 'closed';
              return Card(
                child: ListTile(
                  leading: Icon(
                    closed ? Icons.check_circle : Icons.chat_bubble_outline,
                    color: closed ? Colors.grey : Colors.orange.shade800,
                  ),
                  title: Text((t['category'] ?? '').toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${_date(t['updatedAt'])}  •  ${closed ? 'مغلق' : 'مفتوح'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TicketChatScreen(
                            ticketId: doc.id, isAdmin: false),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
// نهاية الملف
