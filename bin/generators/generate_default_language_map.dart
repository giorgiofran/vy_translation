/*import 'dart:io';
import 'package:recase/recase.dart';
import 'package:vy_language_tag/vy_language_tag.dart';
import 'package:vy_string_utils/vy_string_utils.dart';

import '../utils/configuration_parameters.dart';
import '../utils/message_store.dart';


Future<void> generateDefaultLanguageMap(
    Parameters parms, Iterable<MessageStore> store) async {
  var directory = parms.translationDirectory;

  var targetFile = File(
      '${directory.path}/translation_${parms.defaultLanguage.lowercasePosix}.dart');

  var exists = await targetFile.exists();
  if (!exists) {
    await targetFile.create(recursive: true);
  }
  String content; content = await prepareDefaultMapFileContent(store);
  await targetFile.writeAsString('\nMap<String, String> translations'
      '${ReCase(parms.defaultLanguage.lowercaseCode).pascalCase} '
      '= <String, String>{\n');
  await targetFile.writeAsString(content, mode: FileMode.append);
  await targetFile.writeAsString('};\n', mode: FileMode.append);
}

// The file must have been created already
Future<String> prepareDefaultMapFileContent(
    Iterable<MessageStore> store) async {
  var buffer = StringBuffer();
  String text;
  List<String> parts;
  bool containsSingle, containsDouble;
  MessageStore message;
  for (message in store) {
    text = message.definition.text.replaceAll(RegExp(r'[\r]?\n'), r'\n');
    var keyString = "  '${message.key}': ";
    buffer.write(keyString);
    parts = splitInLines(text, 74, firstLineDecrease: keyString.length - 4);
    for (var part in parts) {
      if (part != parts.first) {
        buffer.write('    ');
      }
      containsSingle = part.contains("'");
      containsDouble = part.contains('"');
      if (containsDouble) {
        if (containsSingle) {
          buffer.write("'''$part'''");
        } else {
          buffer.write("'$part'");
        }
      } else {
        if (containsSingle) {
          buffer.write('"$part"');
        } else {
          buffer.write("'$part'");
        }
      }
      if (part == parts.last) {
        buffer.writeln(',');
      } else {
        buffer.writeln('');
      }
    }
    */
/* buffer.writeln("  '${message.key}': "
        "'''${message.definition.text.replaceAll(RegExp(r'[\r]?\n'), r'\n')}"
        "''',");*//*

  }
  return '$buffer';
}
*/
