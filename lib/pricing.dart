// أرقام التسعير (غيّرها هنا فقط)
class Pricing {
  static const double perKm = 1.90; // سعر الكيلومتر (د.ل)
  static const int minimumFare = 1; // أقل سعر للرحلة (د.ل)

  // السعر عدد صحيح: تقريب لأقرب دينار، وبحد أدنى
  static double fareForKm(double km) {
    final fare = (perKm * km).round();
    return (fare < minimumFare ? minimumFare : fare).toDouble();
  }

  // عرض المبلغ بدون كسور
  static String format(num value) => value.round().toString();
}
// نهاية الملف
