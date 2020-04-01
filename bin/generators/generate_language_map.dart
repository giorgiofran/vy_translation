/*
import 'dart:io';
import 'package:dart_style/dart_style.dart';
import 'package:recase/recase.dart';
import 'package:vy_language_tag/vy_language_tag.dart';
import 'package:vy_string_utils/vy_string_utils.dart';

Future<void> generateLanguageMapFile(
    File file, LanguageTag languageTag, Map<String, String> languageMap) async {
  final _dartFmt = DartFormatter();
  var targetFile = file;

  var exists = await targetFile.exists();
  if (!exists) {
    await targetFile.create(recursive: true);
  }
  var buffer = StringBuffer()
    ..write("import 'dart:collection';\n")
    ..write(
        'Map<String, String> translations${ReCase(languageTag.lowercaseCode).pascalCase} =')
    ..writeln('  SplayTreeMap<String, String>()..addAll(<String, String>{');
  String content;
  content = await stringifyMapContent(languageMap);
  buffer.write(content);
  buffer.writeln('});');

  await targetFile.writeAsString(_dartFmt.format('$buffer'));
}

// The file must have been created already
String stringifyMapContent(Map<String, String> languageMap) {
  var buffer = StringBuffer();
  String text;
  List<String> parts;
  bool containsSingle, containsDouble;
  for (var id in languageMap.keys) {
    text = languageMap[id].replaceAll(RegExp(r'[\r]?\n'), r'\n');
    var keyString = "  '$id': ";
    buffer.write(keyString);
    parts = splitInLines(text, 74, firstLineDecrease: keyString.length - 4);
    for (var part in parts) {
      if (part != parts.first) {
        buffer.write('    ');
      }
      containsSingle = part.contains("'");
      containsDouble = part.contains('"');
      if (containsDouble) {
        if (containsSingle) {
          buffer.write("'''$part'''");
        } else {
          buffer.write("'$part'");
        }
      } else {
        if (containsSingle) {
          buffer.write('"$part"');
        } else {
          buffer.write("'$part'");
        }
      }
      if (part == parts.last) {
        buffer.writeln(',');
      } else {
        buffer.writeln('');
      }
    }
  }
  return '$buffer';
}
*/
