// أرقام التسعير (غيّرها هنا فقط)
class Pricing {
  static const double perKm = 1.90; // سعر الكيلومتر (د.ل)

  static double fareForKm(double km) {
    return (perKm * km * 10).round() / 10;
  }
}
// نهاية الملف
