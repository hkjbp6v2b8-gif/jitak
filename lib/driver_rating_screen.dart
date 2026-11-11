import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pricing.dart';

// تظهر للسائق بعد إنهاء الرحلة: تقييم العميل وملاحظة اختيارية
class DriverRatingScreen extends StatefulWidget {
  final String rideId;
  final String customerName;
  final double fare;
  final String paymentMethod;

  const DriverRatingScreen({
    Key? key,
    required this.rideId,
    required this.customerName,
    required this.fare,
    required this.paymentMethod,
  }) : super(key: key);

  @override
  State<DriverRatingScreen> createState() => _DriverRatingScreenState();
}

class _DriverRatingScreenState extends State<DriverRatingScreen> {
  static const _labels = ['سيئة', 'مقبولة', 'جيدة', 'جيدة جداً', 'ممتازة'];

  int _rating = 5;
  final TextEditingController _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final note = _note.text.trim();
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .update({
        'driverRating': _rating,
        if (note.isNotEmpty) 'driverRatingNote': note,
        'driverRatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شكراً لتقييمك!')),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ التقييم، حاول مجدداً.')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cash = widget.paymentMethod.contains('نقد');
    final name = widget.customerName.isEmpty ? 'العميل' : widget.customerName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقييم الرحلة'),
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            const Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.tealAccent,
                child: Icon(Icons.check, size: 50, color: Colors.teal),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'تمت الرحلة بنجاح!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              color: cash ? Colors.amber.shade50 : Colors.teal.shade50,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Text(
                      '${Pricing.format(widget.fare)} د.ل',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cash
                          ? 'استلم المبلغ من $name نقداً.'
                          : 'طريقة الدفع: ${widget.paymentMethod}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'كيف كانت تجربتك مع $name؟',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 38,
                  ),
                  onPressed: () => setState(() => _rating = i + 1),
                );
              }),
            ),
            Text(
              _labels[_rating - 1],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.teal, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'اكتب ملاحظتك (اختياري)...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('إرسال التقييم',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: const Text('تخطي'),
            ),
          ],
        ),
      ),
    );
  }
}
// نهاية الملف
