// إعدادات الطلبات (غيّرها هنا فقط)
class RequestConfig {
  // نافذة وصول عروض السائقين بعد إنشاء الطلب (ثوانٍ)
  static const int timeoutSeconds = 30;

  // مهلة إضافية لاختيار العميل بعد وصول عرض واحد على الأقل (ثوانٍ)
  static const int chooseSeconds = 60;

  // نوافذ القواعد في Firestore (تُضبط في القواعد، لا هنا):
  //   إرسال عرض: المهلة + 5 = 35
  //   اختيار العميل: المهلة + الاختيار + 5 = 95
  // إن غيّرت الأرقام أعلاه فعدّل 35 و95 في القواعد.
  static const int serverWindowSeconds = 35;
  static const int serverChooseWindowSeconds = 95;

  // نصف قطر استقبال الطلب حول العميل (كم)
  static const double radiusKm = 4;
}
// نهاية الملف
