#!/usr/bin/env dart
library extract_messages;

import 'dart:collection';
import 'dart:io';
import 'package:vy_analyzer_utils/vy_analyzer_utils.dart'
    show DartSourceAnalysis;
import 'package:vy_translation/src/annotation/message_definition.dart';
import 'package:vy_translation/src/translation/translation_finder.dart';

import 'package:yaml/yaml.dart';
import 'package:logging/logging.dart';
import 'package:args/args.dart' show ArgResults;
import 'package:vy_string_utils/vy_string_utils.dart' show unfilled;

import 'generators/generate_default_language_map.dart';
import 'generators/generate_meme_file.dart';
import 'generators/generate_map_files.dart';
import 'generators/generate_translation_finder.dart';
import 'utils/annotation_retriever.dart';
import 'utils/arguments.dart';
import 'utils/configuration_parameters.dart';
import 'utils/formatting.dart';
import 'utils/message_store.dart';
import 'utils/parameter_management.dart';

final log = Logger('extract_messages');

Map<String, MessageStore> store = SplayTreeMap<String, MessageStore>();
Parameters parms;
bool errorsReported = false;
const keyName = 'name';

// ***************************
// ********* M A I N *********
// ***************************
Future<void> main(List<String> args) async {
  initTranslationFinder();

  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${formatTimeRef(record.time)}: '
        '${record.message}');
  });

  try {
    // Create parameter structure and parses arguments
    ArgResults argResults = parseArguments(args);
    if (argResults == null) {
      exit(1);
    } else if (argResults[parmHelp]) {
      return;
    } else if (argResults[parmVerbose]) {
      Logger.root.level = Level.INFO;
    } else if (argResults[parmDebug]) {
      Logger.root.level = Level.ALL;
    }

    // *************************
    // loads pubspec.yaml
    Directory current = Directory.current;
    File pubspecFile = File('${current.path}/pubspec.yaml');
    bool existsPubspec = await pubspecFile.exists();
    if (!existsPubspec) {
      throw StateError('The directory ${current.path} is not a dart project. '
          '(missing file "pubspec.yaml")');
    }
    YamlMap pubspec = loadYaml(await pubspecFile.readAsString());
    if (pubspec == null || unfilled(pubspec[keyName])) {
      throw StateError('Missing project name in file "pubspec.yaml"');
    }
    String projectName;
    projectName = pubspec[keyName];

    // *************************
    // loads vy_translation.yaml
    var yamlFile = File('${current.path}/vy_translation.yaml');
    bool existsYaml = await yamlFile.exists();
    if (!existsYaml) {
      throw StateError('Missing file "vy_translation.yaml" in '
          'project directory (${current.path})');
    }
    YamlMap doc = loadYaml(await yamlFile.readAsString());
    // if .yaml file is empty, loadYaml() returns null;
    parms = extractYamlValues(doc ?? {}, current, projectName);
    await finder.setDefaultLanguage(parms.defaultLanguage);

    // ***** Generate empty files
    await generateMapFiles(parms, clean: argResults[parmClean]);
    await generateTranslationFinderClass(parms);

    await scanMessages(current);
    if (errorsReported) {
      exit(1);
    }
    await generateDefaultLanguageMap(parms, store.values);
    await generateMemeFile(parms, store.values);
  } catch (e, stack) {
    log.severe('$e\n$stack');
    exit(1);
  }
  exit(0);
}

Future<void> scanMessages(Directory project) async {
  DartSourceAnalysis sourceAnalysis = DartSourceAnalysis(AnnotationRetriever(),
      resolvedAnalysis: true, dir: project);
  await sourceAnalysis.run();
}
