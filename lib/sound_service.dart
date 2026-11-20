import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

// صوت تنبيه الطلبات الجديدة: ملفك إن وُجد، وإلا رنين مولَّد برمجياً
class SoundService {
  // مسار ملفك داخل مجلد assets (غيّر الاسم هنا إن كان امتداده مختلفاً)
  static const String assetPath = 'sounds/request.mp3';

  static final AudioPlayer _player = AudioPlayer();
  static String? _uri;

  // false: نستخدم الرنين المولَّد (عند تعذر ملفك)
  static bool _useFile = true;

  // يتفعل بضغطة من المستخدم (شرط المتصفح)، ويُنسى عند تحديث الصفحة
  static bool enabled = false;

  // رنين احتياطي: نغمتان مكررتان
  static Uint8List _wav() {
    const rate = 22050;
    final samples = <int>[];

    void tone(double freq, double seconds) {
      final n = (rate * seconds).round();
      for (var i = 0; i < n; i++) {
        final fadeIn = math.min(1.0, i / (rate * 0.01));
        final fadeOut = math.min(1.0, (n - i) / (rate * 0.04));
        final amp = freq == 0 ? 0.0 : 0.6 * fadeIn * fadeOut;
        final v = amp * math.sin(2 * math.pi * freq * i / rate);
        samples.add((v * 32767).round());
      }
    }

    tone(880, 0.20);
    tone(1175, 0.30);
    tone(0, 0.12);
    tone(880, 0.20);
    tone(1175, 0.40);

    final bytes = samples.length * 2;
    final data = ByteData(44 + bytes);

    void text(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        data.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    text(0, 'RIFF');
    data.setUint32(4, 36 + bytes, Endian.little);
    text(8, 'WAVE');
    text(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little); // PCM
    data.setUint16(22, 1, Endian.little); // أحادي
    data.setUint32(24, rate, Endian.little);
    data.setUint32(28, rate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    text(36, 'data');
    data.setUint32(40, bytes, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      data.setInt16(44 + i * 2, samples[i], Endian.little);
    }

    return data.buffer.asUint8List();
  }

  static String get _fallbackSource =>
      _uri ??= 'data:audio/wav;base64,${base64Encode(_wav())}';

  static Future<void> _play() async {
    try {
      await _player.stop();
      await _player.setVolume(1.0);

      if (_useFile) {
        try {
          await _player.play(AssetSource(assetPath));
          return;
        } catch (_) {
          // ملفك غير موجود أو تعذر تشغيله: نستخدم الرنين الاحتياطي
          _useFile = false;
        }
      }

      await _player.play(UrlSource(_fallbackSource));
    } catch (_) {
      // قد يمنع المتصفح الصوت: نتجاهل بصمت
    }
  }

  // يُستدعى من زر "تفعيل الصوت" (ضغطة المستخدم تفتح الصوت)
  static Future<void> enable() async {
    enabled = true;
    await _play();
  }

  static void disable() {
    enabled = false;
    _player.stop();
  }

  // تجربة الصوت
  static Future<void> test() => _play();

  // عند وصول طلب جديد
  static Future<void> notify() async {
    if (enabled) await _play();
  }
}
// نهاية الملف
