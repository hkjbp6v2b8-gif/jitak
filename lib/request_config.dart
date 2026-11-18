// إعدادات الطلبات (غيّرها هنا فقط)
class RequestConfig {
  // مهلة قبول الطلب قبل أن يُلغى تلقائياً (ثوانٍ)
  static const int timeoutSeconds = 30;

  // نافذة القبول في قواعد Firestore = المهلة + 5 ثوانٍ أمان.
  // إن غيّرت المهلة فعدّل الرقم 35 في القواعد ليطابق هذا.
  static const int serverWindowSeconds = 35;

  // نصف قطر استقبال الطلب حول العميل (كم)
  static const double radiusKm = 4;
}
// نهاية الملف
