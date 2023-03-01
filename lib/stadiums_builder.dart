import 'dart:async';

import 'package:build/build.dart';
import 'package:csv/csv.dart';
import 'package:dart_style/dart_style.dart';

Builder myStadiumsBuilderFactory(BuilderOptions options) {
  return StadiumsBuilder();
}

class StadiumsBuilder implements Builder {
  @override
  final buildExtensions = const {
    '.csv': ['.g.dart'],
  };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    assert(inputId.pathSegments.last == 'stadiums.csv');
    final sink = inputId.changeExtension('.g.dart');
    final csvString = await buildStep.readAsString(inputId);
    final converted = csvToDartCode(inputId.toString(), csvString);
    await buildStep.writeAsString(sink, DartFormatter().format(converted));
  }

  String csvToDartCode(String source, String csvString) {
    final stadiums =
        const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
            .convert<String>(csvString)
            .sublist(1)
            .map((row) => row.map((column) => column.trim()).toList())
            .map((row) => '"${row[0]}": LatLng(${row[1]}, ${row[2]})')
            .join(',');

    return '''// This code is generated from $source. Do not edit.
import 'package:latlong2/latlong.dart';

final Map<String, LatLng> stadiums=Map.unmodifiable({$stadiums});
''';
  }
}
