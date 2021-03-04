#!/usr/bin/env dart

library extract_messages;

//import 'dart:collection';
import 'dart:io';
/* import 'package:vy_analyzer_utils/vy_analyzer_utils.dart'
    show DartSourceAnalysis; */

//import 'package:yaml/yaml.dart';
import 'package:logging/logging.dart';
import 'package:vy_string_utils/vy_string_utils.dart' show dateTimeUpToSeconds;
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
  ArgResults? argResults;
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

    await extractMessagesCmd(argResults);
  } catch (e, stack) {
    log.severe('$e');
    if (argResults?[parmDebug] ?? true) {
      log.severe('\n$stack');
    }
    exit(1);
  }
  exit(0);
}
