import 'dart:io';
import 'package:dart_style/dart_style.dart';
import 'package:vy_dart_meme/src/parts/meme_header.dart';
import 'package:vy_dart_meme/src/parts/meme_project.dart';
import 'package:vy_dart_meme/src/parts/meme_term.dart';

import 'package:vy_dart_meme/vy_dart_meme.dart';

import '../utils/configuration_parameters.dart';
import '../utils/message_store.dart';

// Here the store should contain also other projects.
Future<Meme> generateMemeFile(Parameters parms, Iterable<MessageStore> store,
    {bool isClean, bool isReset}) async {
  isClean ??= false;
  isReset ??= false;

  final _dartFmt = DartFormatter();

  var directory = parms.memoryDirectory;

  var targetFile = File('${directory.path}/${parms.packagePrefix}.dart_meme');

  Meme meme, previousMeme;
  var exists = await targetFile.exists();
  if (!exists) {
    await targetFile.create(recursive: true);
    var newProject = await prepareMemeProject(parms, store);
    meme = Meme()..addProject(newProject);
  } else if (isReset) {
    var newProject = await prepareMemeProject(parms, store);
    meme = Meme()..addProject(newProject);
  } else {
    var memeString = await targetFile.readAsString();
    previousMeme = Meme.decode(memeString);
    var newProject = await prepareMemeProject(parms, store);
    var oldProject = previousMeme.getProject(newProject.name);
    if (oldProject != null) {
      var mergedProject =
          newProject.mergeWith(oldProject, onlyIdsInThisProject: isClean);
      meme = Meme()..addProject(mergedProject);
    } else {
      meme = Meme()..addProject(newProject);
    }
  }

  // Todo here meme has only the current project.
  //    super projects must be added
  // 1) in meme add super projects scanned
  // 2) merge each project present in meme with the corresponding
  //    in previous meme (if any)
  // 3) If a project is present only in previous meme and isClean and isReset
  //    are false, add the old project to the new meme

  // point 3) of above
  if (exists && !isClean && !isReset) {
    if (previousMeme == null) {
      var previousMemeContent = await targetFile.readAsString();
      previousMeme = Meme.decode(previousMemeContent);
    }
    for (var projectName in previousMeme.projectNames) {
      if (!meme.containsProject(projectName)) {
        meme.addProject(previousMeme.getProject(projectName));
      }
    }
  }
  var content = meme.encode();
  await targetFile.writeAsString(_dartFmt.format(content));

  return meme;
}

// The file must have been created already
Future<MemeProject> prepareMemeProject(
    Parameters parms, Iterable<MessageStore> store) async {
  var header =
      MemeHeader(parms.defaultLanguage, parms.targetLanguages.toList());
  var project = MemeProject(parms.packagePrefix);
  project.header = header;
  MemeTerm term;
  for (var message in store) {
    term = MemeTerm(header.sourceLanguageTag, message.definition.id,
        message.definition.text)
      ..description = message.definition.description
      ..exampleValues = message.definition.exampleValues
      ..relativeSourcePath = message.sourcePath;
    project.insertTerm(term);
  }
  return project;
}

Future<Meme> prepareMeme(Parameters parms, Iterable<MessageStore> store) async {
  var project = await prepareMemeProject(parms, store);
  return Meme()..addProject(project);
}

// The file must have been created already
Future<String> prepareMemeContent(
    Parameters parms, Iterable<MessageStore> store) async {
  var meme = await prepareMeme(parms, store);
  return meme.encode();
}
