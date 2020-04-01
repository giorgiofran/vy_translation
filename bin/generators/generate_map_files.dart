import 'dart:io';
import 'package:recase/recase.dart';
import 'package:vy_dart_meme/vy_dart_meme.dart';
import 'package:vy_language_tag/vy_language_tag.dart';

import '../utils/configuration_parameters.dart';
import 'generate_language_map.dart';

Future<void> generateMapFiles(Parameters parms, Meme meme) async {
  File targetFile;
  var directory = parms.translationDirectory;
  await directory.delete(recursive: true);

  var languages = <LanguageTag>[
    parms.defaultLanguage,
    if (parms.targetLanguages != null) ...parms.targetLanguages
  ];
  for (var languageTag in languages) {
    targetFile = File(
        '${directory.path}/translation_${languageTag.lowercasePosix}.dart');
    await targetFile.create(recursive: true);
    var languageMap = prepareLanguageMap(languageTag, meme);
    await generateLanguageMapFile(targetFile, languageTag, languageMap);
  }
}

/*// The file must have been created already
Future<void> writeMapFile(
    File file, LanguageTag languageTag, Map<String, String> languageMap) async {
  var buffer = StringBuffer();
  buffer.write('\nMap<String, String> translations'
      '${ReCase(languageTag.lowercaseCode).pascalCase} '
      '= <String, String>{');

  buffer.write('};\n');
  await file.writeAsString('$buffer');
}*/


Map<String, String> prepareLanguageMap(LanguageTag languageTag, Meme meme) {
  var ret = <String, String>{};
  for (var projectName in meme.projectNames) {
    var project = meme.getProject(projectName);
    for (var term in project.terms) {
      if (term.containsLanguageTerm(languageTag)) {
        ret['$projectName.${term.id}'] = term.getLanguageTerm(languageTag);
      }
    }
  }
  return ret;
}

/*
Future<void> generateEmptyMapFiles(Parameters parms,
    {bool clean, bool reset}) async {
  clean ??= false;
  reset ??= false;
  var directory = parms.translationDirectory;
  var languages = <LanguageTag>[
    parms.defaultLanguage,
    if (parms.targetLanguages != null) ...parms.targetLanguages
  ];
  File targetFile;
  for (var language in languages) {
    targetFile =
        File('${directory.path}/translation_${language.lowercasePosix}.dart');
    var exists = await targetFile.exists();
    if (exists) {
      if (reset) {
        await targetFile.delete();
      } else {
        continue;
      }
    }
    await targetFile.create(recursive: true);
    await fillInEmptyMapFile(targetFile, language);
  }
}

// The file must have been created already
Future<void> fillInEmptyMapFile(File file, LanguageTag languageTag) async {
  await file.writeAsString('\nMap<String, String> translations'
      '${ReCase(languageTag.lowercaseCode).pascalCase} '
      '= <String, String>{};\n');
}
*/
