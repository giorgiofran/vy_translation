#!/usr/bin/env dart
library export_translations;

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:vy_string_utils/vy_string_utils.dart' show dateTimeUpToSeconds;
import 'package:args/args.dart';

import 'command/translate_cmd.dart';
import 'utils/extract_configs.dart';
import 'utils/extract_project_name.dart';
import 'utils/parameter_management.dart';
import 'utils/translate_arguments.dart';

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

  var parms = extractVyTranslationParms(
      await extractVyTranslation(Directory.current),
      Directory.current,
      await extractProjectName(Directory.current));

  ArgResults argResults;
  try {
    // Create parameter structure and parses arguments
    argResults = parseTranslateArguments(args, parms);
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

    await translateCmd(parms, argResults);
  } catch (e, stack) {
    log.severe('$e');
    if (argResults[parmDebug]) {
      log.severe('\n$stack');
    }
    exit(1);
  }
  exit(0);
}
