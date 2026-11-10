import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LocationMap extends StatefulWidget {
  final LatLng? destination;
  final List<LatLng> route;
  final void Function(LatLng point)? onTap;
  final void Function(LatLng position)? onLocated;
  final double height;

  const LocationMap({
    Key? key,
    this.destination,
    this.route = const [],
    this.onTap,
    this.onLocated,
    this.height = 260,
  }) : super(key: key);

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  // نقطة افتراضية قبل تحديد الموقع (طرابلس)
  static const LatLng _fallback = LatLng(32.8872, 13.1913);

  final MapController _controller = MapController();
  LatLng? _me;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  @override
  void didUpdateWidget(LocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final dest = widget.destination;
    if (dest != null && dest != oldWidget.destination) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitTo(dest));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // يضبط الكاميرا لتشمل موقعي والوجهة
  void _fitTo(LatLng dest) {
    if (!mounted) return;
    final me = _me;
    try {
      if (me == null) {
        _controller.move(dest, 15);
      } else {
        _controller.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints([me, dest]),
            padding: const EdgeInsets.all(50),
            maxZoom: 16,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _locate() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) setState(() => _error = 'خدمة الموقع مغلقة في جهازك.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _error = 'لم يتم السماح بالوصول إلى موقعك.');
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 20));
      final me = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;

      setState(() {
        _me = me;
        _error = null;
      });
      widget.onLocated?.call(me);
      _controller.move(me, 15);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر تحديد موقعك. حاول مجدداً.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _locate();
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];

    final me = _me;
    if (me != null) {
      markers.add(
        Marker(
          point: me,
          width: 26,
          height: 26,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(blurRadius: 6, color: Colors.black38)
              ],
            ),
          ),
        ),
      );
    }

    final dest = widget.destination;
    if (dest != null) {
      markers.add(
        Marker(
          point: dest,
          width: 40,
          height: 40,
          alignment: Alignment.topCenter,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: _fallback,
                initialZoom: 13,
                onTap: widget.onTap == null
                    ? null
                    : (tapPosition, point) => widget.onTap!(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'ly.jitak.app',
                ),
                if (widget.route.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: widget.route,
                        strokeWidth: 5,
                        color: Colors.teal,
                      ),
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
            if (_loading)
              const Positioned(
                top: 10,
                right: 10,
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.teal),
                ),
              ),
            if (_error != null)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(fontSize: 12)),
                      ),
                      TextButton(
                        onPressed: _retry,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 24,
              left: 10,
              child: FloatingActionButton.small(
                heroTag: null,
                backgroundColor: Colors.white,
                onPressed: () {
                  final current = _me;
                  if (current != null) {
                    _controller.move(current, 15);
                  } else {
                    _retry();
                  }
                },
                child: const Icon(Icons.my_location, color: Colors.teal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// نهاية الملف
