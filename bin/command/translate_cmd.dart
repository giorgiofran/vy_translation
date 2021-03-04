import 'dart:io';

import 'package:vy_dart_meme/vy_dart_meme.dart';
import 'package:args/args.dart';
import 'package:vy_language_tag/vy_language_tag.dart';
import 'package:dart_style/dart_style.dart';
import 'package:vy_string_utils/vy_string_utils.dart' show filled;

import '../editor/editor.dart';
import '../extract_messages.dart';
import '../utils/configuration_parameters.dart';
import '../utils/translate_arguments.dart';

Future<void> translateCmd(Parameters parms, ArgResults args) async {
  if (parms.memoryDirectory == null) {
    throw StateError('Memory Directory not specified');
  }
  final _dartFmt = DartFormatter();
  var targetFile =
      File('${parms.memoryDirectory!.path}/${parms.packagePrefix}.dart_meme');
  var memeString = await targetFile.readAsString();

  var meme = Meme.decode(memeString);
  var originLanguageTag = LanguageTag.parse(args[parmOriginLanguageTag]);
  var languageTag = LanguageTag.parse(args[parmLanguageTag]);
  try {
    console.rawMode = true;
    //if (arguments.isNotEmpty) {
    //  editedFilename = arguments[0];
    //  editorOpen(editedFilename);
    //}
    /*   editorSetStatusMessage(
        'HELP: Ctrl-S = save | Ctrl-Q = quit | Ctrl-F = find');
 */
    for (var projectName in meme.projectNames) {
      var project = meme.getProject(projectName);
      if (project != null) {
        for (var term in project.terms) {
          var origin = term.getLanguageTerm(originLanguageTag);
          var translation = term.getLanguageTerm(languageTag) ?? '';
          if (filled(translation) && !args[parmShowAll]) {
            continue;
          }

          var processing = true;
          messageId = term.id;
          initEditor();
          editorSet('$origin\n***************\n$translation');
          editorSetStatusMessage('HELP: Ctrl-Q = quit | Ctrl-F = find');
          while (processing) {
            editorRefreshScreen();
            processing = editorProcessKeypress();
          }
          if (isSentenceDirty) {
            translation = '${sentenceRows.sublist(editorFirstRow).join('\n')}';

            term.insertLanguageTerm(languageTag, translation);
          }
        }
      }
    }
    console.clearScreen();
  } catch (exception) {
    // Make sure raw mode gets disabled if we hit some unrelated problem
    console.rawMode = false;
    rethrow;
  }
  log.info('Translate session ending ...');
  var content = meme.encode();
  await targetFile.writeAsString(_dartFmt.format(content));
}
