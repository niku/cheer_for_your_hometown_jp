import 'package:cheer_your_hometown_jp/stadiums.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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

  static final defaultCenter = LatLng(35.588, 134.380);
  static const double defaultZoom = 6;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: FlutterMap(
          options: MapOptions(
            center: defaultCenter,
            zoom: defaultZoom,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            MarkerLayer(
                markers: stadiums.values
                    .map((e) => Marker(
                        point: e,
                        builder: (context) => Icon(
                              Icons.location_pin,
                              color: Theme.of(context).colorScheme.secondary,
                            )))
                    .toList())
          ],
        ),
      ),
    );
  }
}
