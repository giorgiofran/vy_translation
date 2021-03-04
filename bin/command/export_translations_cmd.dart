import 'dart:io';

import 'package:vy_dart_meme/vy_dart_meme.dart';

import '../generators/generate_map_files.dart';
import '../generators/generate_translation_finder.dart';
import '../utils/configuration_parameters.dart';
import '../utils/extract_configs.dart';
import '../utils/extract_project_name.dart';
import '../utils/parameter_management.dart';

Future<void> exportTranslationsCmd({Parameters? parms, Meme? meme}) async {
  parms ??= extractVyTranslationParms(
      await extractVyTranslation(Directory.current),
      Directory.current,
      await extractProjectName(Directory.current));

  if (parms.memoryDirectory == null) {
    throw StateError('Memory Directory not specified');
  }
  if (meme == null) {
    var targetFile =
        File('${parms.memoryDirectory!.path}/${parms.packagePrefix}.dart_meme');
    var memeString = await targetFile.readAsString();

    meme = Meme.decode(memeString);
  }

  await generateMapFiles(parms, meme);
  await generateTranslationFinderClass(parms);
}
