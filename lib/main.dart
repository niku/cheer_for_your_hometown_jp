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
import 'package:go_router/go_router.dart';

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
    return MaterialApp.router(
      title: title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: GoRouter(
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext context, GoRouterState state) {
              final selectedTeams = state.queryParametersAll['team'] ?? [];
              return MyPage(
                title: title,
                selectedTeams: selectedTeams.toSet(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MyPage extends StatelessWidget {
  const MyPage({Key? key, required this.title, required this.selectedTeams})
      : super(key: key);

  final String title;
  final Set<String> selectedTeams;

  @override
  Widget build(BuildContext context) {
    final Set<String> teams =
        footballMatches.expand((e) => [e.home, e.away]).toSet();

    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) {
              return teams.map((team) {
                return PopupMenuItem(
                  child: Text(team),
                  onTap: () {
                    context.go(Uri(path: '/', queryParameters: {'team': team})
                        .toString());
                  },
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: MyMap(
          selectedTeams: selectedTeams,
        ),
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
  MyMap({Key? key, required this.selectedTeams})
      : _stadiums = stadiums.entries.map((e) {
          final stadiumLatlng = e.value;
          return StadiumMarker(
              name: e.key,
              point: stadiumLatlng,
              builder: (context) => Icon(
                    Icons.location_pin,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
              anchorPos: AnchorPos.align(AnchorAlign.top));
        }).toList(),
        _footballMatchesAtVenue = footballMatches.fold(
            {},
            (previousValue, element) => previousValue
              ..putIfAbsent(element.venue, () => []).add(element)),
        super(key: key);

  final Set<String> selectedTeams;
  final List<StadiumMarker> _stadiums;
  final Map<String, List<FootballMatch>> _footballMatchesAtVenue;

  final defaultCenter = LatLng(35.676, 139.650);
  final double defaultZoom = 6;
  final defaultMaxBounds =
      LatLngBounds(LatLng(20.0, 122.0), LatLng(50.0, 154.0));

  @override
  State<MyMap> createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  /// Used to trigger showing/hiding of popups.
  final PopupController _popupLayerController = PopupController();

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: widget.defaultCenter,
        zoom: widget.defaultZoom,
        maxBounds: widget.defaultMaxBounds,
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
            markers: widget._stadiums,
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
              return Popup(
                  marker, widget._footballMatchesAtVenue[marker.name]!);
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
