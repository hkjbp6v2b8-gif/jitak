import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// خريطة مباشرة: نقطتك والوجهة وسيارة الكابتن وهي تتحرك
class LiveRideMap extends StatefulWidget {
  final LatLng pickup;
  final LatLng destination;
  final LatLng? driver;
  final double height;

  const LiveRideMap({
    Key? key,
    required this.pickup,
    required this.destination,
    this.driver,
    this.height = 320,
  }) : super(key: key);

  @override
  State<LiveRideMap> createState() => _LiveRideMapState();
}

class _LiveRideMapState extends State<LiveRideMap> {
  final MapController _controller = MapController();

  CameraFit _fit() {
    final points = <LatLng>[
      widget.pickup,
      widget.destination,
      if (widget.driver != null) widget.driver!,
    ];
    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(points),
      padding: const EdgeInsets.all(50),
      maxZoom: 16,
    );
  }

  @override
  void didUpdateWidget(LiveRideMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driver != widget.driver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _controller.fitCamera(_fit());
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.driver;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
        child: FlutterMap(
          mapController: _controller,
          options: MapOptions(initialCameraFit: _fit()),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'ly.jitak.app',
            ),
            MarkerLayer(
              markers: [
                // نقطة الانطلاق (موقعك)
                Marker(
                  point: widget.pickup,
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
                // الوجهة
                Marker(
                  point: widget.destination,
                  width: 40,
                  height: 40,
                  alignment: Alignment.topCenter,
                  child: const Icon(Icons.location_on,
                      color: Colors.red, size: 40),
                ),
                // سيارة الكابتن
                if (driver != null)
                  Marker(
                    point: driver,
                    width: 42,
                    height: 42,
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
              ],
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// نهاية الملف
