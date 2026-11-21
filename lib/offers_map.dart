import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// عرض سائق على خريطة العميل
class OfferPin {
  final String id;
  final LatLng point;
  final String label;
  final bool nearest;

  const OfferPin(this.id, this.point, this.label, {this.nearest = false});
}

// خريطة العميل أثناء اختيار السائق: موقعه + السائقون الذين عرضوا خدمتهم
class OffersMap extends StatefulWidget {
  final LatLng pickup;
  final List<OfferPin> offers;
  final ValueChanged<String>? onTap;
  final double height;

  const OffersMap({
    Key? key,
    required this.pickup,
    required this.offers,
    this.onTap,
    this.height = 280,
  }) : super(key: key);

  @override
  State<OffersMap> createState() => _OffersMapState();
}

class _OffersMapState extends State<OffersMap> {
  final MapController _controller = MapController();

  String _ids(List<OfferPin> offers) =>
      (offers.map((o) => o.id).toList()..sort()).join(',');

  CameraFit _fit() {
    final points = <LatLng>[
      widget.pickup,
      ...widget.offers.map((o) => o.point),
    ];
    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(points),
      padding: const EdgeInsets.all(55),
      maxZoom: 16,
    );
  }

  @override
  void didUpdateWidget(OffersMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // نعيد ضبط الكاميرا فقط عند تغيّر مجموعة السائقين (لا مع كل تحديث للموقع)
    if (_ids(oldWidget.offers) != _ids(widget.offers)) {
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

  Widget _driverMarker(OfferPin o) {
    final color = o.nearest ? Colors.green.shade700 : Colors.teal;
    return GestureDetector(
      onTap: () => widget.onTap?.call(o.id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(o.label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(blurRadius: 5, color: Colors.black38)
              ],
            ),
            child:
                const Icon(Icons.directions_car, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      // موقع العميل
      Marker(
        point: widget.pickup,
        width: 26,
        height: 26,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black38)],
          ),
        ),
      ),
      for (final o in widget.offers)
        Marker(
          point: o.point,
          width: 76,
          height: 64,
          child: _driverMarker(o),
        ),
    ];

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
            MarkerLayer(markers: markers),
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
