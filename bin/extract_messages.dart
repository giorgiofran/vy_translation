#!/usr/bin/env dart
library extract_messages;

//import 'dart:collection';
import 'dart:io';
/* import 'package:vy_analyzer_utils/vy_analyzer_utils.dart'
    show DartSourceAnalysis; */

//import 'package:yaml/yaml.dart';
import 'package:logging/logging.dart';
import 'package:vy_string_utils/vy_string_utils.dart'
    show dateTimeUpToSeconds;
import 'package:args/args.dart';

import 'command/extract_messages_cmd.dart';
//import 'generators/generate_meme_file.dart';
//import 'generators/generate_map_files.dart';
//import 'generators/generate_translation_finder.dart';
//import 'utils/annotation_retriever.dart';
import 'utils/arguments.dart';
//import 'utils/configuration_parameters.dart';
//import 'utils/extract_project_name.dart';
//import 'utils/message_store.dart';
//import 'utils/parameter_management.dart';

final log = Logger('extract_messages');

//Map<String, MessageStore> store = SplayTreeMap<String, MessageStore>();
//Parameters parms;
//bool errorsReported = false;
//const keyName = 'name';

// ***************************
// ********* M A I N *********
// ***************************
Future<void> main(List<String> args) async {
  //initTranslationFinder();

  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${dateTimeUpToSeconds(record.time)}: '
        '${record.message}');
  });
  ArgResults argResults;
  try {
    // Create parameter structure and parses arguments
    argResults = parseArguments(args);
    if (argResults == null) {
      // Error message already logged in the parseArguments() method
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
  /*  var current = Directory.current;
    var pubspecFile = File('${current.path}/pubspec.yaml');
    var existsPubspec = await pubspecFile.exists();
    if (!existsPubspec) {
      throw StateError('The directory ${current.path} is not a dart project. '
          '(missing file "pubspec.yaml")');
    }
    YamlMap pubspec = loadYaml(await pubspecFile.readAsString());
    if (pubspec == null || unfilled(pubspec[keyName])) {
      throw StateError('Missing project name in file "pubspec.yaml"');
    }
    String projectName;
    projectName = pubspec[keyName]; */
/* 
    var current = Directory.current;
    // *************************
    // loads project name
    var projectName = await extractProjectName(current);

    // *************************
    // loads vy_translation.yaml
    var yamlFile = File('${current.path}/vy_translation.yaml');
    var existsYaml = await yamlFile.exists();
    if (!existsYaml) {
      throw StateError('Missing file "vy_translation.yaml" in '
          'project directory (${current.path})');
    }
    YamlMap doc = loadYaml(await yamlFile.readAsString());
    // if .yaml file is empty, loadYaml() returns null;
    parms = extractVyTranslationParms(doc ?? {}, current, projectName);

    await scanMessages(current);
    if (errorsReported) {
      exit(1);
    }
    var meme = await generateMemeFile(parms, store.values,
        isClean: argResults[parmClean], isReset: argResults[parmReset]);

    await generateMapFiles(parms, meme);
    await generateTranslationFinderClass(parms); */

    await extractMessagesCmd(argResults);

  } catch (e, stack) {
    log.severe('$e');
    if (argResults[parmDebug]) {
      log.severe('\n$stack');
    }
    exit(1);
  }
  exit(0);
}

