import 'dart:io';
import 'package:dart_style/dart_style.dart';
import 'package:vy_dart_meme/src/parts/meme_header.dart';
import 'package:vy_dart_meme/src/parts/meme_project.dart';
import 'package:vy_dart_meme/src/parts/meme_term.dart';

import 'package:vy_dart_meme/vy_dart_meme.dart';

import '../utils/configuration_parameters.dart';
import '../utils/message_store.dart';

Future<void> generateMemeFile(
    Parameters parms, Iterable<MessageStore> store) async {
  final _dartFmt = DartFormatter();

  Directory directory = parms.memoryDirectory;

  File targetFile = File('${directory.path}/${parms.packagePrefix}_'
      '${parms.defaultLanguage.lowercasePosix}.dart_meme');

  bool exists = await targetFile.exists();
  if (!exists) {
    await targetFile.create(recursive: true);
  }
  String content = await prepareMemeContent(parms, store);

  await targetFile.writeAsString(_dartFmt.format(content));
}

// The file must have been created already
Future<String> prepareMemeContent(
    Parameters parms, Iterable<MessageStore> store) async {
  MemeHeader header =
      MemeHeader(parms.defaultLanguage, parms.targetLanguages.toList());
  MemeProject project = MemeProject(parms.packagePrefix);
  project.header = header;
  MemeTerm term;
  for (MessageStore message in store) {
    term = MemeTerm(header.sourceLanguageTag, message.definition.id,
        message.definition.text)
      ..description = message.definition.description
      ..exampleValues = message.definition.exampleValues
      ..relativeSourcePath = message.sourcePath;
    project.insertTerm(term);
  }
  Meme meme = Meme();
  meme.addProject(project);
  //Todo also add dependencies projects
  return meme.encode();
}
