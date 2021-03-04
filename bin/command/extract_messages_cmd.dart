import 'dart:collection';
import 'dart:io';

import 'package:vy_analyzer_utils/vy_analyzer_utils.dart';
//import 'package:yaml/yaml.dart';
import 'package:args/args.dart';

import '../generators/generate_meme_file.dart';
import '../utils/annotation_retriever.dart';
import '../utils/arguments.dart';
import '../utils/configuration_parameters.dart';
import '../utils/extract_configs.dart';
import '../utils/extract_project_name.dart';
import '../utils/message_store.dart';
import '../utils/parameter_management.dart';
import 'export_translations_cmd.dart';

// This parameters are shared with some of the routines.
// could'n find a better way to pass/receive values
bool errorsReported = false;
Map<String, MessageStore> store = SplayTreeMap<String, MessageStore>();
late Parameters parms;

Future<void> extractMessagesCmd(ArgResults argResults) async {
  var current = Directory.current;
  // *************************
  // loads project name
  var projectName = await extractProjectName(current);

  var vyTranslationMap = await extractVyTranslation(current);
  parms = extractVyTranslationParms(vyTranslationMap, current, projectName);

  await _scanMessages(current);
  if (errorsReported) {
    exit(1);
  }
  var meme = await generateMemeFile(parms, store.values,
      isClean: argResults[parmClean], isReset: argResults[parmReset]);

  await exportTranslationsCmd(parms: parms, meme: meme);
}

Future<void> _scanMessages(Directory project) async {
  var sourceAnalysis = DartSourceAnalysis(AnnotationRetriever(),
      resolvedAnalysis: true, dir: project);
  await sourceAnalysis.run();
}
