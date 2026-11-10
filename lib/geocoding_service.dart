import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// مكان وجده البحث
class PlaceResult {
  final String name;
  final String address;
  final LatLng point;

  const PlaceResult(this.name, this.address, this.point);
}

class GeocodingService {
  // البحث عن مكان بالاسم (خدمة Nominatim العامة: للتجربة فقط)
  // يرجع null عند فشل الاتصال، وقائمة فارغة عند عدم وجود نتائج
  static Future<List<PlaceResult>?> search(String query, {LatLng? near}) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final params = <String, String>{
      'q': q,
      'format': 'jsonv2',
      'limit': '6',
      'accept-language': 'ar',
      'countrycodes': 'ly',
    };

    // تفضيل النتائج القريبة من موقع العميل (دون حصرها)
    if (near != null) {
      params['viewbox'] =
          '${near.longitude - 0.5},${near.latitude + 0.5},${near.longitude + 0.5},${near.latitude - 0.5}';
      params['bounded'] = '0';
    }

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);

    try {
      final response =
          await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is! List) return null;

      final results = <PlaceResult>[];
      for (final item in data) {
        if (item is! Map) continue;
        final lat = double.tryParse('${item['lat']}');
        final lon = double.tryParse('${item['lon']}');
        if (lat == null || lon == null) continue;

        final display = '${item['display_name'] ?? ''}';
        final rawName = '${item['name'] ?? ''}'.trim();
        final name =
            rawName.isNotEmpty ? rawName : display.split(',').first.trim();

        results.add(PlaceResult(name, display, LatLng(lat, lon)));
      }
      return results;
    } catch (_) {
      return null;
    }
  }
}
// نهاية الملف
