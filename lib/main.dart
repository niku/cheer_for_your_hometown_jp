import 'package:cheer_for_your_hometown_jp/football_match.dart';
import 'package:cheer_for_your_hometown_jp/stadiums.g.dart';
import 'package:cheer_for_your_hometown_jp/matches_2023.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cheer_for_your_hometown_jp/firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

const enableAnalytics = bool.fromEnvironment('enableAnalytics');
late FirebaseAnalytics analytics;

void main() async {
  usePathUrlStrategy();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  analytics = FirebaseAnalytics.instance;
  if (enableAnalytics) {
    await analytics.logAppOpen();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final title = 'Cheer for your hometown JP';

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
        child: MyMap(),
      ),
    );
  }
}

class StadiumMarker extends Marker {
  StadiumMarker({
    required this.name,
    required super.point,
    required super.builder,
    super.key,
    super.width,
    super.height,
    super.rotate,
    super.rotateOrigin,
    super.rotateAlignment,
    super.anchorPos,
  }) : super();

  final String name;
}

class MyMap extends StatefulWidget {
  const MyMap({Key? key}) : super(key: key);

  @override
  State<MyMap> createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  static final defaultCenter = LatLng(35.676, 139.650);
  static const double defaultZoom = 6;
  static final defaultMaxBounds =
      LatLngBounds(LatLng(20.0, 122.0), LatLng(50.0, 154.0));

  final List<StadiumMarker> _stadiums = stadiums.entries.map((e) {
    final stadiumLatlng = e.value;
    return StadiumMarker(
        name: e.key,
        point: stadiumLatlng,
        builder: (context) => Icon(
              Icons.location_pin,
              color: Theme.of(context).colorScheme.secondary,
            ),
        anchorPos: AnchorPos.align(AnchorAlign.top));
  }).toList();

  final Map<String, List<FootballMatch>> _footballMatchesAtVenue =
      footballMatches.fold(
          {},
          (previousValue, element) =>
              previousValue..putIfAbsent(element.venue, () => []).add(element));

  /// Used to trigger showing/hiding of popups.
  final PopupController _popupLayerController = PopupController();

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: defaultCenter,
        zoom: defaultZoom,
        maxBounds: defaultMaxBounds,
        onTap: (_, __) => _popupLayerController
            .hideAllPopups(), // Hide popup when the map is tapped.
        interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
      ),
      nonRotatedChildren: [
        AttributionWidget.defaultWidget(
          source: 'OpenStreetMap contributors',
          onSourceTapped: () async {
            if (!await launchUrl(
                Uri.parse("https://www.openstreetmap.org/copyright"))) {
              if (kDebugMode) {
                print('Could not launch url');
              }
            }
          },
        ),
      ],
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.jp/{z}/{x}/{y}.png',
        ),
        PopupMarkerLayerWidget(
          options: PopupMarkerLayerOptions(
            popupController: _popupLayerController,
            markers: _stadiums,
            markerRotateAlignment:
                PopupMarkerLayerOptions.rotationAlignmentFor(AnchorAlign.top),
            popupBuilder: (BuildContext context, Marker marker) {
              marker as StadiumMarker;
              final itemId = marker.name;
              if (enableAnalytics) {
                analytics.logSelectContent(
                    contentType: 'marker', itemId: itemId);
              } else {
                debugPrint(
                    'selectContent(contentType: \'marker\', itemId: \'$itemId\')');
              }
              return Popup(marker, _footballMatchesAtVenue[marker.name]!);
            },
          ),
        ),
      ],
    );
  }
}

class Popup extends StatelessWidget {
  final StadiumMarker marker;
  final List<FootballMatch> matches;

  const Popup(this.marker, this.matches, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(marker.name),
          Table(
            border: TableBorder.all(),
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: matches.map((e) {
              return TableRow(children: <Widget>[
                TableCell(
                    child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: Text(e.date),
                )),
                TableCell(
                    child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: Text(e.home),
                )),
                TableCell(
                    child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: Text(e.away),
                )),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }
}
