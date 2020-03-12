import 'package:args/args.dart';

import '../extract_messages.dart';

const String parmHelp = 'help';
const String parmVerbose = 'verbose';
const String parmDebug = 'debug';
const String parmClean = 'clean';

ArgResults parseArguments(List<String> args) {
  var parser = ArgParser();
  parser.addFlag(parmHelp,
      negatable: false, abbr: 'h', defaultsTo: false, help: 'This help.');
  parser.addFlag(parmVerbose,
      negatable: false,
      abbr: 'v',
      defaultsTo: false,
      help: 'Shows also info messages (default only warnings and errors).');
  parser.addFlag(parmDebug,
      negatable: false,
      abbr: 'd',
      defaultsTo: false,
      help:
          'Shows all messages (cannot be used in conjunction with --verbose)');
  parser.addFlag(parmClean,
      negatable: false,
      abbr: 'c',
      defaultsTo: false,
      help: 'Removes all files containing the translation_3 maps. '
          'Consider making a backup if you are not sure of what you are doing');
  ArgResults results;
  try {
    results = parser.parse(args);
    if (results[parmVerbose] && results[parmDebug]) {
      log.severe(
          'You cannot specify the --verbose and the --debug options togheter');
      return null;
    } else if (results[parmHelp]) {
      print(parser.usage);
    }
  } on FormatException catch (e) {
    log.severe('$e');
  }

  return results;
}
