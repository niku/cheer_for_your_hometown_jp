import 'dart:async';

import 'package:build/build.dart';
import 'package:csv/csv.dart';
import 'package:dart_style/dart_style.dart';

Builder myMatchesBuilderFactory(BuilderOptions options) {
  return MatchesBuilder();
}

class MatchesBuilder implements Builder {
  @override
  final buildExtensions = const {
    '.csv': ['.g.dart'],
  };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    assert(inputId.pathSegments.last.startsWith("matches_"));
    final sink = inputId.changeExtension('.g.dart');
    final csvString = await buildStep.readAsString(inputId);
    final converted = csvToDartCode(inputId.toString(), csvString);
    await buildStep.writeAsString(sink, DartFormatter().format(converted));
  }

  String csvToDartCode(String source, String csvString) {
    final matches = const CsvToListConverter(
            eol: '\n', shouldParseNumbers: false)
        .convert<String>(csvString)
        .sublist(1)
        .map((row) => row.map((column) => column.trim()).toList())
        .map((row) =>
            'Match(year: "${row[0]}", tournaments: "${row[1]}", sec: "${row[2]}", date: "${row[3]}", kickoff: "${row[4]}", home: "${row[5]}", score: "${row[6]}", away: "${row[7]}", venue: "${row[8]}", att: "${row[9]}", broadcast: "${row[10]}")')
        .join(',\n');

    return '''// This code is generated from $source. Do not edit.
import 'package:cheer_your_hometown_jp/match.dart';

const List<Match> matches=[$matches];
''';
  }
}
