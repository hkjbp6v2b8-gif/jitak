// أرقام التسعير (غيّرها هنا فقط)
class Pricing {
  static const double perKm = 1.90; // سعر الكيلومتر (د.ل)
  static const int minimumFare = 1; // أقل سعر للرحلة (د.ل)

  // السعر عدد صحيح دائماً: تقريب للأعلى
  static double fareForKm(double km) {
    // الطرح الصغير يمنع خطأ الكسور العشرية (مثل 4.0000001 ← 5)
    final fare = (perKm * km - 0.000001).ceil();
    return (fare < minimumFare ? minimumFare : fare).toDouble();
  }

  // عرض المبلغ بدون كسور
  static String format(num value) => value.round().toString();
}
// نهاية الملف
