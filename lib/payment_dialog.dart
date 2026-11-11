import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String providerLabel(String provider) =>
    provider == 'libyana' ? 'ليبيانا' : 'المدار';

// يخفي رقم الكرت ويُبقي آخر 4 أرقام
String maskCard(String number) {
  if (number.length <= 4) return number;
  return '••••${number.substring(number.length - 4)}';
}

Widget _providerTile(BuildContext context, String provider, Color color) {
  return Card(
    elevation: 1,
    child: ListTile(
      leading: Icon(Icons.sim_card, color: color),
      title: Text('كرت ${providerLabel(provider)}',
          style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      trailing: const Icon(Icons.chevron_left),
      onTap: () => Navigator.pop(context, provider),
    ),
  );
}

// نافذة السداد: اختيار نوع الكرت ثم كتابة رقمه
Future<void> showPayDialog(BuildContext context, {required double debt}) async {
  final messenger = ScaffoldMessenger.of(context);

  final provider = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('سداد المستحقات'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('المستحق الحالي: ${debt.toStringAsFixed(1)} د.ل',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('اختر نوع الكرت:'),
          const SizedBox(height: 8),
          _providerTile(dialogContext, 'libyana', Colors.deepPurple),
          _providerTile(dialogContext, 'almadar', Colors.orange.shade800),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('إغلاق'),
        ),
      ],
    ),
  );

  if (provider == null || !context.mounted) return;

  final sent = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CardEntryDialog(provider: provider),
  );

  if (sent == true) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
            'تم إرسال الكرت للإدارة. سيُخصم المبلغ من مستحقاتك بعد المراجعة.'),
      ),
    );
  }
}

class _CardEntryDialog extends StatefulWidget {
  final String provider;

  const _CardEntryDialog({Key? key, required this.provider}) : super(key: key);

  @override
  State<_CardEntryDialog> createState() => _CardEntryDialogState();
}

class _CardEntryDialogState extends State<_CardEntryDialog> {
  final TextEditingController _number = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _number.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final a = _number.text.trim();
    final b = _confirm.text.trim();

    if (a.length < 8 || a.length > 20) {
      setState(() => _error = 'رقم الكرت يجب أن يكون بين 8 و20 رقماً.');
      return;
    }
    if (a != b) {
      setState(() => _error = 'الرقمان غير متطابقين.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await FirebaseFirestore.instance.collection('paymentRequests').add({
        'driverId': user.uid,
        'driverName': user.displayName ?? '',
        'provider': widget.provider,
        'cardNumber': a,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = 'تعذر إرسال الطلب، تحقق من الاتصال وحاول مجدداً.';
        });
      }
    }
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textDirection: TextDirection.ltr,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 20,
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('كرت ${providerLabel(widget.provider)}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اكتب الرقم السري للكرت. كل كرت يُستخدم مرة واحدة، والخطأ في الرقم يضيّع الكرت، فتأكد منه قبل الإرسال.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            _field(_number, 'رقم الكرت'),
            _field(_confirm, 'أعد كتابة الرقم للتأكيد'),
            if (_error != null)
              Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _sending ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          child: _sending
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('إرسال للإدارة',
                  style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
// نهاية الملف
