import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RoutingService {
  // مفتاح الـ API الخاص بـ Google Maps (قم بوضع مفتاحك هنا أو استخدم مفتاح الويب الخاص بك)
  static const String _apiKey = "AIzaSyCq14cu4ax2Tww5GnSy3SuvA5aj0nsirmc";

  // دالة لجلب المسار (Polyline) بين نقطة الانطلاق ونقطة الوصول
  static Future<List<LatLng>> getRouteCoordinates(LatLng origin, LatLng destination) async {
    final String url = 
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_apiKey&language=ar';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          return _decodePolyline(points);
        }
      }
    } catch (e) {
      print('خطأ في جلب بيانات المسار: $e');
    }
    return [];
  }

  // دالة فك تشفير إحداثيات المسار (Polyline Decoder)
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
