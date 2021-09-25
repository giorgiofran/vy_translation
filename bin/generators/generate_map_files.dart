import 'dart:io' show File;
import 'package:dart_style/dart_style.dart' show DartFormatter;
import 'package:recase/recase.dart' show ReCase;
import 'package:vy_dart_meme/vy_dart_meme.dart' show Meme;
import 'package:vy_language_tag/vy_language_tag.dart' show LanguageTag;
import 'package:vy_string_utils/vy_string_utils.dart' show splitInLines;

import '../utils/configuration_parameters.dart';

Future<void> generateMapFiles(Parameters parms, Meme meme) async {
  File targetFile;

  if (parms.translationDirectory == null) {
    throw StateError('Translation Directory not specified');
  }
  var directory = parms.translationDirectory!;
  await directory.delete(recursive: true);

  var languages = <LanguageTag>[
    if (parms.defaultLanguage != null) parms.defaultLanguage!,
    if (parms.targetLanguages != null) ...?parms.targetLanguages
  ];
  for (var languageTag in languages) {
    targetFile = File(
        '${directory.path}/translation_${languageTag.lowercasePosix}.dart');
    await targetFile.create(recursive: true);
    var languageMap = prepareLanguageMap(languageTag, meme);
    await generateLanguageMapFile(targetFile, languageTag, languageMap);
  }
}

Map<String, String> prepareLanguageMap(LanguageTag languageTag, Meme meme) {
  var ret = <String, String>{};
  for (var projectName in meme.projectNames) {
    var project = meme.getProject(projectName);
    if (project != null) {
      for (var term in project.terms) {
        if (term.containsLanguageTerm(languageTag)) {
          ret['$projectName.${term.id}'] =
              term.getLanguageTerm(languageTag) ?? '';
        }
        if (term.flavorCollections.isNotEmpty) {
          for (var key in term.languageFlavorKeys(languageTag)) {
            ret['$projectName.${term.id}.$key'] =
                term.getLanguageFlavorTerm(languageTag, key) ?? '';
          }
        }
      }
    }
  }
  return ret;
}

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
    ..write('Map<String, String> translations'
        '${ReCase(languageTag.lowercaseCode).pascalCase} =')
    ..writeln('  SplayTreeMap<String, String>()..addAll(<String, String>{');
  String content;
  content = stringifyMapContent(languageMap);
  buffer.write(content);
  buffer.writeln('});');

  await targetFile.writeAsString(_dartFmt.format('$buffer'));
}

// The file must have been created already
String stringifyMapContent(Map<String, String> languageMap) {
  var buffer = StringBuffer();
  String? text;
  List<String> parts;
  bool containsSingle, containsDouble;
  for (var id in languageMap.keys) {
    text = languageMap[id]?.replaceAll(RegExp(r'[\r]?\n'), r'\n');
    if (text == null) {
      continue;
    }
    var keyString = "  '$id': ";
    buffer.write(keyString);
    parts = splitInLines(text, 74, firstLineDecrease: keyString.length - 4);
    for (var part in parts) {
      if (part != parts.first) {
        buffer.write('    ');
      } else if (part == ' ') {
        buffer.writeln('');
        continue;
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
