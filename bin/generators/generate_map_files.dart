import 'dart:io';
import 'package:recase/recase.dart';
import 'package:vy_language_tag/vy_language_tag.dart';

import '../utils/configuration_parameters.dart';

Future<void> generateMapFiles(Parameters parms, {bool clean, bool reset}) async {
  clean ??= false;
  reset ??= false;
  Directory directory = parms.translationDirectory;
  List<LanguageTag> languages = <LanguageTag>[
    parms.defaultLanguage,
    if (parms.targetLanguages != null) ...parms.targetLanguages
  ];
  File targetFile;
  for (LanguageTag language in languages) {
    targetFile =
        File('${directory.path}/translation_${language.lowercasePosix}.dart');
    bool exists = await targetFile.exists();
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
