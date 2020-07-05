import 'package:args/args.dart';

import '../translate.dart';
import 'configuration_parameters.dart';

const String parmHelp = 'help';
const String parmVerbose = 'verbose';
const String parmDebug = 'debug';
const String parmOriginLanguageTag = 'originLanguageTag';
const String parmLanguageTag = 'languageTag';
const String parmShowAll = 'showAll';

ArgResults parseTranslateArguments(List<String> args, Parameters parms) {
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
  parser.addOption(parmLanguageTag,
      abbr: 'l',
      help: 'Language to translate. It can be the origin language itself, '
          'in case we want to modify some terms',
      allowed: [
        parms.defaultLanguage.posixCode,
        for (var tag in parms.targetLanguages) tag.posixCode
      ]);
  parser.addOption(parmOriginLanguageTag,
      defaultsTo: parms.defaultLanguage.posixCode,
      abbr: 'o',
      help: 'Language from which to translate');
  parser.addFlag(parmShowAll,
      negatable: false,
      abbr: 'a',
      defaultsTo: false,
      help: 'Show all messages, otherwise only those with no translation');
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
