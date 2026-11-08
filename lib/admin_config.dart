// بريد المدير (يجب أن يطابق البريد في قواعد Firestore)
class AdminConfig {
  static const String email = 'zogtatabdelrrhman@gmail.com';

  static bool isAdmin(String? userEmail) {
    return userEmail != null && userEmail.toLowerCase() == email;
  }
}
// نهاية الملف
