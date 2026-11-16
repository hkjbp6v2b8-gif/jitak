// إعدادات الطلبات (غيّرها هنا فقط)
class RequestConfig {
  // مهلة قبول الطلب قبل أن يُلغى تلقائياً (ثوانٍ)
  static const int timeoutSeconds = 15;

  // نافذة القبول في قواعد Firestore = المهلة + 5 ثوانٍ أمان.
  // إن غيّرت المهلة فعدّل الرقم 20 في القواعد ليطابق هذا.
  static const int serverWindowSeconds = 20;

  // نصف قطر استقبال الطلب حول العميل (كم). يُستخدم في الخطوة التالية.
  static const double radiusKm = 4;
}
// نهاية الملف
