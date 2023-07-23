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

const List<String> clubs = <String>[
  '全て',
  // 並び順は https://www.jleague.jp/club/ より
  // J1
  '札幌',
  '鹿島',
  '浦和',
  '柏',
  'FC東京',
  '川崎Ｆ',
  '横浜FM',
  '横浜FC',
  '湘南',
  '新潟',
  '名古屋',
  '京都',
  'Ｇ大阪',
  'Ｃ大阪',
  '神戸',
  '広島',
  '福岡',
  '鳥栖',
  // J2
  '仙台',
  '秋田',
  '山形',
  'いわき',
  '水戸',
  '栃木',
  '群馬',
  '大宮',
  '千葉',
  '東京Ｖ',
  '金沢',
  '清水',
  '磐田',
  '藤枝',
  '岡山',
  '山口',
  '徳島',
  '長崎',
  '熊本',
  '大分',
  // J3
  '八戸',
  '岩手',
  '福島',
  'YS横浜',
  '相模原',
  '松本',
  '長野',
  '富山',
  '沼津',
  '岐阜',
  'FC大阪',
  '奈良',
  '鳥取',
  '讃岐',
  '愛媛',
  '今治',
  '北九州',
  '宮崎',
  '鹿児島',
  '琉球',
];

final PopupController _popupLayerController = PopupController();

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
              final selectedTeams = state.queryParametersAll['club'] ?? [];
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
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) {
              return clubs.map((club) {
                return PopupMenuItem(
                  child: Text(club),
                  onTap: () {
                    _popupLayerController.hideAllPopups(disableAnimation: true);
                    if (club == '全て') {
                      context.go(Uri(path: '/').toString());
                    } else {
                      context.go(Uri(path: '/', queryParameters: {'club': club})
                          .toString());
                    }
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
  MyMap({Key? key, required this.selectedTeams}) : super(key: key);

  final Set<String> selectedTeams;

  final defaultCenter = const LatLng(35.676, 139.650);
  final double defaultZoom = 6;
  final defaultMaxBounds =
      LatLngBounds(const LatLng(20.0, 122.0), const LatLng(50.0, 154.0));

  Map<String, List<FootballMatch>> get footballMatchesAtVenue =>
      footballMatches.where((footballMatch) {
        if (selectedTeams.isEmpty) {
          return true;
        } else {
          return selectedTeams.contains(footballMatch.home) ||
              selectedTeams.contains(footballMatch.away);
        }
      }).fold(
          {},
          (previousValue, element) =>
              previousValue..putIfAbsent(element.venue, () => []).add(element));

  List<StadiumMarker> get selectedStadiums {
    final venues =
        footballMatchesAtVenue.keys; // where で stadium 数だけ呼び出すのを防ぐため変数へ代入している
    return stadiums.entries.where((e) => venues.contains(e.key)).map((e) {
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
  }

  @override
  State<MyMap> createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  /// Used to trigger showing/hiding of popups.
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
          initialCenter: widget.defaultCenter,
          initialZoom: widget.defaultZoom,
          cameraConstraint:
              CameraConstraint.contain(bounds: widget.defaultMaxBounds),
          onTap: (_, __) => _popupLayerController
              .hideAllPopups(), // Hide popup when the map is tapped.
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          )),
      nonRotatedChildren: [
        SimpleAttributionWidget(
          source: const Text('OpenStreetMap contributors'),
          onTap: () async {
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
          userAgentPackageName: 'https://niku.name/cheer_for_your_hometown_jp/',
        ),
        PopupMarkerLayer(
          options: PopupMarkerLayerOptions(
            popupController: _popupLayerController,
            markers: widget.selectedStadiums,
            popupDisplayOptions: PopupDisplayOptions(
              builder: (BuildContext context, Marker marker) {
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
                    marker, widget.footballMatchesAtVenue[marker.name]!);
              },
            ),
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
