import 'dart:async';
import 'package:flutter/material.dart';

// إعدادات الانتظار (غيّرها هنا فقط)
// تنبيه: القواعد في Firestore تتحقق من 5 دقائق (2 + 3). إن غيّرت الأرقام فعدّلها هناك أيضاً.
class WaitConfig {
  static const int freeMinutes = 2; // الانتظار المجاني بعد وصول الكابتن
  static const int extraMinutes = 3; // مهلة إضافية قبل احتساب رسم التأخير
  static const int fee = 1; // رسم التأخير (د.ل)

  static Duration get free => Duration(minutes: freeMinutes);
  static Duration get feeAfter =>
      Duration(minutes: freeMinutes + extraMinutes);

  // هل استحق رسم التأخير؟ (هامش 3 ثوانٍ لفروق ساعة الجهاز عن الخادم)
  static bool feeDue(DateTime arrivedAt, DateTime now) =>
      now.difference(arrivedAt) > feeAfter + const Duration(seconds: 3);
}

// شريط عدّاد الانتظار (يُستخدم عند السائق والعميل)
class WaitCountdown extends StatefulWidget {
  final DateTime arrivedAt;
  final bool forDriver;

  const WaitCountdown({
    Key? key,
    required this.arrivedAt,
    required this.forDriver,
  }) : super(key: key);

  @override
  State<WaitCountdown> createState() => _WaitCountdownState();
}

class _WaitCountdownState extends State<WaitCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final total = d.inSeconds < 0 ? 0 : d.inSeconds;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(total ~/ 60)}:${two(total % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.arrivedAt);

    final Color color;
    final IconData icon;
    final String title;
    final String line;

    if (elapsed <= WaitConfig.free) {
      color = Colors.green.shade700;
      icon = Icons.timer;
      title = widget.forDriver ? 'بانتظار العميل' : 'وصل الكابتن! تفضّل بالخروج';
      line =
          'الانتظار المجاني المتبقي: ${_fmt(WaitConfig.free - elapsed)}';
    } else if (elapsed <= WaitConfig.feeAfter) {
      color = Colors.orange.shade800;
      icon = Icons.hourglass_bottom;
      title = 'انتهى الانتظار المجاني';
      line =
          'يُضاف ${WaitConfig.fee} د.ل للأجرة بعد: ${_fmt(WaitConfig.feeAfter - elapsed)}';
    } else {
      color = Colors.red;
      icon = Icons.warning_amber_rounded;
      title = 'تأخر العميل';
      line = widget.forDriver
          ? 'سيُضاف ${WaitConfig.fee} د.ل إلى الأجرة عند بدء الرحلة (الانتظار ${_fmt(elapsed)}).'
          : 'سيُضاف رسم تأخير ${WaitConfig.fee} د.ل إلى أجرة رحلتك (الانتظار ${_fmt(elapsed)}).';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text(line, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// نهاية الملف
