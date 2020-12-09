import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:dart_style/dart_style.dart';
import 'package:vy_dart_meme/src/parts/meme_header.dart';
import 'package:vy_dart_meme/src/parts/meme_project.dart';
import 'package:vy_dart_meme/src/parts/meme_term.dart';

import 'package:vy_dart_meme/vy_dart_meme.dart';
import 'package:vy_dart_meme/src/element/flavor_collection.dart';
import 'package:yaml/yaml.dart';

import '../utils/configuration_parameters.dart';
import '../utils/message_store.dart';
import '../utils/parameter_management.dart';

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
    try {
      previousMeme = Meme.decode(memeString);
    } on StateError catch (error) {
      if (error.message.endsWith('variable.')) {
        throw StateError('Missing "meme" variable in file ${targetFile.path}');
      }
      rethrow;
    }
    var newProject = await prepareMemeProject(parms, store);
    var oldProject = previousMeme.getProject(newProject.name);
    if (oldProject != null) {
      var mergedProject = newProject.mergeWith(oldProject,
          onlyIdsInThisProject: isClean, toBeMergedHasPriority: true);
      meme = Meme()..addProject(mergedProject);
    } else {
      meme = Meme()..addProject(newProject);
    }
  }

  // here meme has only the current project. Super projects must be added
  // 1) in meme add super projects scanned
  var projectMap = await scanSuperProject(parms);
  // 2) merge each project present in meme with the corresponding
  //    in previous meme (if any)
  MemeProject superProject;
  if (exists && previousMeme == null) {
    var previousMemeContent = await targetFile.readAsString();
    try {
      previousMeme = Meme.decode(previousMemeContent);
    } on StateError catch (error) {
      if (error.message.endsWith('variable.')) {
        throw StateError('Missing "meme" variable in file ${targetFile.path}');
      }
      rethrow;
    }
  }
  for (var key in projectMap.keys) {
    if (!isReset && exists && previousMeme.containsProject(key)) {
      superProject = projectMap[key].mergeWith(previousMeme.getProject(key),
          onlyIdsInThisProject: isClean, toBeMergedHasPriority: true);
    } else {
      superProject = projectMap[key];
    }
    meme.addProject(superProject);
  }
  // 3) If a project is present only in previous meme and isClean and isReset
  //    are false, add the old project to the new meme
  if (exists && !isClean && !isReset) {
    /*   if (previousMeme == null) {
      var previousMemeContent = await targetFile.readAsString();
      previousMeme = Meme.decode(previousMemeContent);
    }*/
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
    if (message.definition.id == null) {
      throw StateError('Null id in project "${project.name}", '
          'source "${message.sourcePath}"');
    }
    term = MemeTerm(header.originalLanguageTag, message.definition.text,
        message.definition.id,
        flavorCollections: message.definition.flavorCollections,
        originalFlavorTerms: {
          for (var keyList in message.definition.flavorTextPerKey.keys ?? [])
            keyList.join(FlavorCollection.keySeparator):
                message.definition.flavorTextPerKey[keyList]
        })
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

Future<Map<String, MemeProject>> scanSuperProject(Parameters parms) async {
  var ret = <String, MemeProject>{};
  var packagesMap = await getPackagesMap(parms);
  for (var projectName in packagesMap.keys) {
    var path = packagesMap[projectName];
    String dirPath;
    if (path.startsWith('file://')) {
      dirPath = p.fromUri(p.dirname(path));
    } else {
      if (path == 'lib/') {
        // discards itself
        continue;
      }
      dirPath = p.canonicalize(p.dirname(path));
    }
    var vyTranslationYamlFile = File('$dirPath/vy_translation.yaml');
    if (!(await vyTranslationYamlFile.exists())) {
      continue;
    }

    YamlMap doc = loadYaml(await vyTranslationYamlFile.readAsString());
    // if .yaml file is empty, loadYaml() returns null;
    parms =
        extractVyTranslationParms(doc ?? {}, Directory(dirPath), projectName);

    var memeFile =
        File('${parms.memoryDirectory.path}/${parms.packagePrefix}.dart_meme');
    if (!(await memeFile.exists())) {
      throw StateError('Cannot find "meme" file ${memeFile.path}');
    }
    var content = await memeFile.readAsString();
    var projectMeme = Meme.decode(content);
    ret[parms.packagePrefix] = projectMeme.getProject(parms.packagePrefix);
  }
  return ret;
}

Future<Map<String, String>> getPackagesMap(Parameters parms) async {
  var ret = <String, String>{};
  var packagesFile = File('${Directory.current.path}/.packages');
  var packages = await packagesFile.readAsLines();
  int index;
  for (var line in packages) {
    if (line.startsWith('#')) {
      continue;
    }
    index = line.indexOf(':');
    ret[line.substring(0, index)] = line.substring(index + 1);
  }

  return ret;
}
