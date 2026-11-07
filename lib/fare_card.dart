import 'package:flutter/material.dart';

// بطاقة المسافة والسعر وزر الطلب
class FareCard extends StatelessWidget {
  final TextEditingController note;
  final TextEditingController promo;
  final String payment;
  final ValueChanged<String> onPayment;
  final VoidCallback onApplyPromo;
  final VoidCallback onRequest;
  final double? km;
  final double? routeFare;
  final double? finalFare;
  final double discount;
  final String promoCode;
  final bool estimated;
  final bool routing;
  final bool loading;

  const FareCard({
    Key? key,
    required this.note,
    required this.promo,
    required this.payment,
    required this.onPayment,
    required this.onApplyPromo,
    required this.onRequest,
    required this.km,
    required this.routeFare,
    required this.finalFare,
    required this.discount,
    required this.promoCode,
    required this.estimated,
    required this.routing,
    required this.loading,
  }) : super(key: key);

  OutlineInputBorder get _border =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(12));

  Widget _row(String label, Widget value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.grey, fontWeight: FontWeight.bold)),
        value,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = km;
    final before = routeFare;
    final fare = finalFare;
    final canRequest = !loading && !routing && fare != null;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: note,
              decoration: InputDecoration(
                hintText: 'وصف الوجهة (اختياري)',
                prefixIcon:
                    const Icon(Icons.edit_location_alt, color: Colors.teal),
                border: _border,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: promo,
                    decoration: InputDecoration(
                      hintText: 'كود الخصم',
                      prefixIcon:
                          const Icon(Icons.card_giftcard, color: Colors.teal),
                      border: _border,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onApplyPromo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                  ),
                  child: const Text('تطبيق',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _row(
              'المسافة:',
              routing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.teal),
                    )
                  : Text(
                      k == null
                          ? '—'
                          : '${k.toStringAsFixed(1)} كم${estimated ? ' (تقديري)' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 8),
            _row(
              'التكلفة:',
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (discount > 0 && before != null)
                    Text(
                      '${before.toStringAsFixed(1)} د.ل',
                      style: const TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey),
                    ),
                  Text(
                    fare == null ? '—' : '${fare.toStringAsFixed(1)} د.ل',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                  ),
                ],
              ),
            ),
            if (promoCode.isNotEmpty)
              Text('كوبون مطبّق: $promoCode',
                  style: const TextStyle(color: Colors.green, fontSize: 12)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('طريقة الدفع:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: payment,
                  items: const ['نقداً (كاش)', 'محفظة إلكترونية']
                      .map((v) => DropdownMenuItem<String>(
                          value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onPayment(v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: canRequest ? onRequest : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('بحث عن كابتن الآن',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
// نهاية الملف
