import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'geocoding_service.dart';

// خانة بحث عن مكان بالاسم، وتعرض النتائج ليختار منها
class PlaceSearchBox extends StatefulWidget {
  final LatLng? near;
  final ValueChanged<PlaceResult> onSelected;

  const PlaceSearchBox({Key? key, this.near, required this.onSelected})
      : super(key: key);

  @override
  State<PlaceSearchBox> createState() => _PlaceSearchBoxState();
}

class _PlaceSearchBoxState extends State<PlaceSearchBox> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  List<PlaceResult>? _results;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();

    final query = _controller.text.trim();
    if (query.length < 2) {
      setState(() {
        _results = null;
        _message = 'اكتب حرفين على الأقل للبحث.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _results = null;
      _message = null;
    });

    final found = await GeocodingService.search(query, near: widget.near);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (found == null) {
        _message = 'تعذر البحث الآن. جرّب لاحقاً أو اضغط على الخريطة.';
      } else if (found.isEmpty) {
        _message = 'لا توجد نتائج. جرّب اسماً آخر أو اضغط على الخريطة.';
      } else {
        _results = found;
      }
    });
  }

  void _select(PlaceResult place) {
    _controller.text = place.name;
    setState(() {
      _results = null;
      _message = null;
    });
    widget.onSelected(place);
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            hintText: 'ابحث عن مكان (مثلاً: ميدان الشهداء)',
            prefixIcon: const Icon(Icons.search, color: Colors.teal),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.teal),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_circle_left_outlined,
                        color: Colors.teal),
                    tooltip: 'بحث',
                    onPressed: _search,
                  ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_message!,
                style: const TextStyle(color: Colors.orange, fontSize: 12)),
          ),
        if (results != null)
          Card(
            elevation: 3,
            margin: const EdgeInsets.only(top: 6),
            child: Column(
              children: results
                  .map(
                    (p) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.place, color: Colors.red),
                      title: Text(p.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(p.address,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () => _select(p),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
// نهاية الملف
