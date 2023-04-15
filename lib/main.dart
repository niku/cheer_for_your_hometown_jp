import 'package:cheer_your_hometown_jp/stadiums.g.dart';
import 'package:cheer_your_hometown_jp/matches_2023.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final title = 'Cheer your hometown';

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyPage(title: title),
    );
  }
}

class MyPage extends StatelessWidget {
  const MyPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Padding(
        padding: EdgeInsets.all(8),
        child: MapWithPopups(),
      ),
    );
  }
}

class MapWithPopups extends StatefulWidget {
  const MapWithPopups({Key? key}) : super(key: key);

  @override
  State<MapWithPopups> createState() => _MapWithPopupsState();
}

class _MapWithPopupsState extends State<MapWithPopups> {
  static final defaultCenter = LatLng(35.588, 134.380);
  static const double defaultZoom = 6;
  static final defaultMaxBounds =
      LatLngBounds(LatLng(20.0, 122.0), LatLng(46.0, 154.0));

  late final List<Marker> _markers;

  /// Used to trigger showing/hiding of popups.
  final PopupController _popupLayerController = PopupController();

  @override
  void initState() {
    super.initState();
    _markers = stadiums.entries.map((e) {
      final stadiumLatlng = e.value;
      return Marker(
          point: stadiumLatlng,
          builder: (context) => Icon(
                Icons.location_pin,
                color: Theme.of(context).colorScheme.secondary,
              ));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: defaultCenter,
        zoom: defaultZoom,
        maxBounds: defaultMaxBounds,
        onTap: (_, __) => _popupLayerController
            .hideAllPopups(), // Hide popup when the map is tapped.
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.jp/{z}/{x}/{y}.png',
        ),
        PopupMarkerLayerWidget(
          options: PopupMarkerLayerOptions(
            popupController: _popupLayerController,
            markers: _markers,
            markerRotateAlignment:
                PopupMarkerLayerOptions.rotationAlignmentFor(AnchorAlign.top),
            popupBuilder: (BuildContext context, Marker marker) =>
                Popup(marker),
          ),
        ),
      ],
    );
  }
}

class Popup extends StatefulWidget {
  final Marker marker;

  const Popup(this.marker, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PopupState();
}

class _PopupState extends State<Popup> {
  final List<IconData> _icons = [
    Icons.star_border,
    Icons.star_half,
    Icons.star
  ];
  int _currentIcon = 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => setState(() {
          _currentIcon = (_currentIcon + 1) % _icons.length;
        }),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 10),
              child: Icon(_icons[_currentIcon]),
            ),
            _cardDescription(context),
          ],
        ),
      ),
    );
  }

  Widget _cardDescription(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        constraints: const BoxConstraints(minWidth: 100, maxWidth: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Popup for a marker!',
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14.0,
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4.0)),
            Text(
              'Position: ${widget.marker.point.latitude}, ${widget.marker.point.longitude}',
              style: const TextStyle(fontSize: 12.0),
            ),
            Text(
              'Marker size: ${widget.marker.width}, ${widget.marker.height}',
              style: const TextStyle(fontSize: 12.0),
            ),
          ],
        ),
      ),
    );
  }
}
