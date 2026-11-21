import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

// صوت تنبيه الطلبات الجديدة: ملفك إن وُجد، وإلا رنين مولَّد برمجياً
class SoundService {
  // مسار ملفك داخل مجلد assets (غيّر الاسم هنا إن كان امتداده مختلفاً)
  static const String assetPath = 'sounds/request.mp3';

  static final AudioPlayer _player = AudioPlayer();
  static String? _fallbackUri;
  static String? _silentUri;

  // false: نستخدم الرنين المولَّد (عند تعذر ملفك)
  static bool _useFile = true;

  // يصبح true بعد أول لمسة للشاشة (شرط المتصفح لتشغيل الصوت)
  static final ValueNotifier<bool> unlockedNotifier =
      ValueNotifier<bool>(false);
  static bool get unlocked => unlockedNotifier.value;

  // يبني ملف WAV من نغمات: [التردد، المدة بالثواني] (التردد 0 = صمت)
  static Uint8List _buildWav(List<List<double>> tones) {
    const rate = 22050;
    final samples = <int>[];

    for (final t in tones) {
      final freq = t[0];
      final n = (rate * t[1]).round();
      for (var i = 0; i < n; i++) {
        final fadeIn = math.min(1.0, i / (rate * 0.01));
        final fadeOut = math.min(1.0, (n - i) / (rate * 0.04));
        final amp = freq == 0 ? 0.0 : 0.6 * fadeIn * fadeOut;
        final v = amp * math.sin(2 * math.pi * freq * i / rate);
        samples.add((v * 32767).round());
      }
    }

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

  // الرنين الاحتياطي: نغمتان مكررتان
  static String get _fallbackSource => _fallbackUri ??=
      'data:audio/wav;base64,${base64Encode(_buildWav(<List<double>>[
        [880, 0.20],
        [1175, 0.30],
        [0, 0.12],
        [880, 0.20],
        [1175, 0.40],
      ]))}';

  // مقطع صامت قصير لفتح الصوت عند أول لمسة بلا أي صوت مسموع
  static String get _silentSource => _silentUri ??=
      'data:audio/wav;base64,${base64Encode(_buildWav(<List<double>>[
        [0, 0.10],
      ]))}';

  // يُستدعى عند أول لمسة في أي مكان بالتطبيق: يفتح الصوت للمتصفح
  static Future<void> unlock() async {
    if (unlocked) return;
    unlockedNotifier.value = true;
    try {
      await _player.play(UrlSource(_silentSource));
    } catch (_) {}
  }

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

  // تجربة الصوت (من القائمة الجانبية)
  static Future<void> test() => _play();

  // عند وصول طلب جديد
  static Future<void> notify() => _play();
}
// نهاية الملف
