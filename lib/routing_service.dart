import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final double distanceKm;
  final List<LatLng> points;

  const RouteResult(this.distanceKm, this.points);
}

class RoutingService {
  // يطلب المسار من خدمة OSRM العامة (مناسبة للتجربة فقط)
  static Future<RouteResult?> getRoute(LatLng from, LatLng to) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response =
          await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') return null;

      final routes = data['routes'] as List;
      if (routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final meters = (route['distance'] as num).toDouble();
      final coords = route['geometry']['coordinates'] as List;

      final points = coords.map<LatLng>((c) {
        final pair = c as List;
        return LatLng(
          (pair[1] as num).toDouble(),
          (pair[0] as num).toDouble(),
        );
      }).toList();

      return RouteResult(meters / 1000, points);
    } catch (_) {
      return null;
    }
  }
}
// نهاية الملف
