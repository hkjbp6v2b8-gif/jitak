import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'routing_service.dart';

// دبوس طلب مفتوح على الخريطة
class MapRequest {
  final String id;
  final LatLng point;
  final String label;

  const MapRequest(this.id, this.point, this.label);
}

// خريطة السائق: موقعه المباشر + الطلبات المفتوحة + مسار الرحلة الجارية
class DriverMap extends StatefulWidget {
  final String statusText;
  final Color statusColor;
  final List<MapRequest> requests;
  final ValueChanged<String>? onRequestTap;
  final LatLng? pickup;
  final LatLng? destination;

  const DriverMap({
    Key? key,
    required this.statusText,
    required this.statusColor,
    this.requests = const [],
    this.onRequestTap,
    this.pickup,
    this.destination,
  }) : super(key: key);

  @override
  State<DriverMap> createState() => _DriverMapState();
}

class _DriverMapState extends State<DriverMap> {
  // نقطة افتراضية قبل تحديد الموقع (طرابلس)
  static const LatLng _fallback = LatLng(32.8872, 13.1913);

  final MapController _controller = MapController();
  StreamSubscription<Position>? _sub;
  LatLng? _me;
  String? _error;
  bool _centered = false;

  List<LatLng> _route = [];
  String _routeKey = '';
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _startLocation();
    _syncRoute();
  }

  @override
  void didUpdateWidget(DriverMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRoute();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _setError(String text) {
    if (mounted) setState(() => _error = text);
  }

  Future<void> _startLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _setError('خدمة الموقع مغلقة في جهازك.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setError('لم يتم السماح بالوصول إلى موقعك.');
        return;
      }

      await _sub?.cancel();
      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        (pos) => _onPosition(LatLng(pos.latitude, pos.longitude)),
        onError: (_) => _setError('تعذر متابعة موقعك.'),
      );
    } catch (_) {
      _setError('تعذر تحديد موقعك. حاول مجدداً.');
    }
  }

  void _onPosition(LatLng position) {
    if (!mounted) return;
    setState(() {
      _me = position;
      _error = null;
    });
    if (!_centered) {
      _centered = true;
      try {
        _controller.move(position, 15);
      } catch (_) {}
    }
  }

  // تحميل مسار الرحلة الجارية (انطلاق ← وجهة)
  void _syncRoute() {
    final p = widget.pickup;
    final d = widget.destination;
    final key = (p == null || d == null)
        ? ''
        : '${p.latitude},${p.longitude}>${d.latitude},${d.longitude}';
    if (key == _routeKey) return;

    _routeKey = key;
    final token = ++_token;
    if (p == null || d == null) {
      _route = [];
      return;
    }
    _loadRoute(p, d, token);
  }

  Future<void> _loadRoute(LatLng p, LatLng d, int token) async {
    final result = await RoutingService.getRoute(p, d);
    if (!mounted || token != _token) return;
    setState(() => _route = result?.points ?? [p, d]);
    _fit();
  }

  void _fit() {
    final me = _me;
    final p = widget.pickup;
    final d = widget.destination;
    final points = <LatLng>[
      if (me != null) me,
      if (p != null) p,
      if (d != null) d,
    ];
    if (points.length < 2) return;
    try {
      _controller.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.fromLTRB(40, 90, 40, 280),
          maxZoom: 16,
        ),
      );
    } catch (_) {}
  }

  void _recenter() {
    final me = _me;
    if (me == null) {
      setState(() => _error = null);
      _startLocation();
      return;
    }
    try {
      _controller.move(me, 15);
    } catch (_) {}
  }

  Widget _dot(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black38)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];

    // دبابيس الطلبات المفتوحة
    for (final r in widget.requests) {
      markers.add(
        Marker(
          point: r.point,
          width: 70,
          height: 58,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => widget.onRequestTap?.call(r.id),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(r.label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                const Icon(Icons.location_on, color: Colors.orange, size: 34),
              ],
            ),
          ),
        ),
      );
    }

    // الرحلة الجارية: الانطلاق (أخضر) والوجهة (أحمر)
    final p = widget.pickup;
    if (p != null) {
      markers.add(Marker(
          point: p, width: 24, height: 24, child: _dot(Colors.green)));
    }
    final d = widget.destination;
    if (d != null) {
      markers.add(Marker(
        point: d,
        width: 40,
        height: 40,
        alignment: Alignment.topCenter,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ));
    }

    // موقعي (سيارة خضراء مزرقة)
    final me = _me;
    if (me != null) {
      markers.add(
        Marker(
          point: me,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.teal,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(blurRadius: 6, color: Colors.black38)
              ],
            ),
            child: const Icon(Icons.directions_car,
                color: Colors.white, size: 22),
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: const MapOptions(
            initialCenter: _fallback,
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'ly.jitak.app',
            ),
            if (_route.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                      points: _route, strokeWidth: 5, color: Colors.teal),
                ],
              ),
            MarkerLayer(markers: markers),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        // شارة الحالة
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.statusColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(blurRadius: 6, color: Colors.black26)
                  ],
                ),
                child: Text(widget.statusText,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
        // زر العودة لموقعي
        Positioned(
          top: 10,
          left: 10,
          child: FloatingActionButton.small(
            heroTag: null,
            backgroundColor: Colors.white,
            onPressed: _recenter,
            child: const Icon(Icons.my_location, color: Colors.teal),
          ),
        ),
      ],
    );
  }
}
// نهاية الملف
