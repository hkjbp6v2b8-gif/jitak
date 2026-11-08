import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'routing_service.dart';

// خريطة تعرض الانطلاق والوجهة والمسار بينهما
class RideMap extends StatefulWidget {
  final LatLng pickup;
  final LatLng destination;
  final double height;

  const RideMap({
    Key? key,
    required this.pickup,
    required this.destination,
    this.height = 240,
  }) : super(key: key);

  @override
  State<RideMap> createState() => _RideMapState();
}

class _RideMapState extends State<RideMap> {
  List<LatLng> _route = [];

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    final result =
        await RoutingService.getRoute(widget.pickup, widget.destination);
    if (!mounted) return;
    setState(() {
      _route = result?.points ?? [widget.pickup, widget.destination];
    });
  }

  @override
  Widget build(BuildContext context) {
    final bounds =
        LatLngBounds.fromPoints([widget.pickup, widget.destination]);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(40),
              maxZoom: 16,
            ),
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
                    points: _route,
                    strokeWidth: 5,
                    color: Colors.teal,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
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
                Marker(
                  point: widget.destination,
                  width: 40,
                  height: 40,
                  alignment: Alignment.topCenter,
                  child: const Icon(Icons.location_on,
                      color: Colors.red, size: 40),
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
