#!/usr/bin/env dart
library extract_messages;

import 'dart:io';
import 'package:vy_language_tag/vy_language_tag.dart';
import 'package:vy_translation/src/annotation/message_definition.dart';
import 'package:vy_string_utils/vy_string_utils.dart';
import 'package:vy_string_utils/src/dart_elements/dart_annotation.dart';

import 'package:yaml/yaml.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';

const String keyPackagePrefix = 'package_prefix';
const String keySourceTmxDirectory = 'source_tmx_directory';
const String keyTargetTmxDirectory = 'target_tmx_directory';
const String keyTranslationsDirectory = 'translations_directory';
const String keyDefaultLanguage = 'default_language';
const String keyTargetLanguages = 'target_languages';

final log = Logger('extract_messages');

String formatTimeRef(DateTime time) {
  String timeString = time.toIso8601String().replaceAll('T', ' ');
  int dotIndex = timeString.indexOf('.');
  return timeString.substring(0, dotIndex);
}

void main(List<String> args) {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print(
        '${record.level.name}: ${formatTimeRef(record.time)}: ${record.message}');
  });

  try {
    Directory current = Directory.current;
    File yamlFile = File('${current.path}/vy_translation.yaml');
    bool existsYaml = yamlFile.existsSync();
    if (!existsYaml) {
      throw StateError(
          'Missing file "vy_translation.yaml" in project directory (${current.path})');
    }
    List<String> data = yamlFile.readAsLinesSync();
    YamlMap doc = loadYaml(data.join('\n'));
    // if .yaml file is empty, loadYaml() returns null;
    Parameters parms = extractYamlValues(doc ?? {}, current);
    scanMessages(current);
  } catch (e, stack) {
    log.severe('$e\n$stack');
    exit(1);
  }
  exit(0);
}

void scanMessages(Directory project) {
  List<FileSystemEntity> entities = project.listSync();
  for (FileSystemEntity entity in entities) {
    if (entity is Directory) {
      if(!path.basename(entity.path).startsWith('.')) {
        scanMessages(entity);
      }
      continue;
    } else if (entity is! File || path.extension(entity.path) != '.dart') {
      continue;
    }
    print('${path.basename(entity.path)} - ${entity.path}');

    extractAnnotations(entity);
  }
}

RegExp messageDefinitionRegExpr = RegExp('');

@MessageDefinition('0005', 'Test', description: 'TestCase')
extractAnnotations(File dartSourceFile) {
  String dartSource = dartSourceFile.readAsStringSync();
  var result = analyzeDartSourceBasic(dartSource, CommentBehavior.preserve,
      CommentBehavior.preserve, CommentBehavior.preserve);
  for (DartAnnotation annotation in result.annotations) {
    print(annotation);
  }
}

Parameters extractYamlValues(Map yamlMap, Directory current) {
  Parameters parms = Parameters();

  parms.packageParameter = getStringParm(
      keyPackagePrefix, yamlMap, current, path.basename(current.path));
/*  if (yamlMap.containsKey(keyPackagePrefix)) {
    parms.packageParameter = yamlMap[keyPackagePrefix];
  } else {
    parms.packageParameter = path.basename(current.path);
    logSubstitute(
        keyPackagePrefix, 'the project directory name', parms.packageParameter);
  }*/

  parms.sourceTmxDirectory = getDirectoryParm(
      keySourceTmxDirectory, yamlMap, current, 'translation/source');

  parms.targetTmxDirectory = getDirectoryParm(
      keyTargetTmxDirectory, yamlMap, current, 'translation/target');

  parms.translationsDirectory = getDirectoryParm(
      keyTranslationsDirectory, yamlMap, current, 'lib/src/translation');

  parms.defaultLanguage = getLanguageTagParm(
      keyDefaultLanguage, yamlMap, current, LanguageTag('en', region: 'US'));
  /* parms.defaultLanguage = yamlMap[keyDefaultLanguage];
  if (parms.defaultLanguage == null) {
    parms.defaultLanguage = LanguageTag('en', region: 'US');
    logSubstitute(keyDefaultLanguage, 'the default value', 'en_US');
  }*/

  parms.targetLanguages =
      getLanguageTagParmList(keyTargetLanguages, yamlMap, current);
  /* dynamic targetLanguages = yamlMap[keyTargetLanguages];
  if (targetLanguages == null) {
    parms.targetLanguages = <LanguageTag>{};
  } else if (targetLanguages is String) {
    parms.targetLanguages = <LanguageTag>{LanguageTag.parse(targetLanguages)};
  } else if (targetLanguages is List) {
    parms.targetLanguages = <LanguageTag>{};
    for (String lang in targetLanguages) {
      parms.targetLanguages.add(LanguageTag.parse(lang));
    }
  }*/
  return parms;
}

String getStringParm(String parmName, Map parmMap, Directory currentDirectory,
    String defaultsTo) {
  dynamic value = parmMap[parmName];
  String string;
  if (value == null) {
    string = defaultsTo;
    logSubstitute(parmName, 'the default value', defaultsTo);
  } else if (value is String) {
    string = value;
  } else if (value is List) {
    throw ArgumentError('The "$parmName" parameter cannot be a list');
  } else {
    throw ArgumentError(
        'The "$parmName" parameter cannot be of type "${value.runtimeType}"');
  }

  return string;
}

Directory getDirectoryParm(String parmName, Map parmMap,
    Directory currentDirectory, String defaultsTo) {
  dynamic value = parmMap[parmName];
  Directory dir;
  if (value == null) {
    dir = Directory('${currentDirectory.path}/$defaultsTo');
    logSubstitute(parmName, 'the default value', defaultsTo);
  } else if (value is String) {
    dir = Directory('${currentDirectory.path}/$value');
  } else if (value is List) {
    throw ArgumentError('The "$parmName" parameter cannot be a list');
  } else {
    throw ArgumentError(
        'The "$parmName" parameter cannot be of type "${value.runtimeType}"');
  }

  bool dirExists = dir.existsSync();
  if (!dirExists) {
    dir.createSync(recursive: true);
    logFolderCreated(dir);
  }
  return dir;
}

LanguageTag getLanguageTagParm(String parmName, Map parmMap,
    Directory currentDirectory, LanguageTag defaultsTo) {
  dynamic value = parmMap[parmName];
  LanguageTag tag;
  if (value == null) {
    tag = defaultsTo;
    logSubstitute(parmName, 'the default value', defaultsTo.code);
  } else if (value is String) {
    tag = LanguageTag.parse(value);
  } else if (value is List) {
    throw ArgumentError('The "$parmName" parameter cannot be a list');
  } else {
    throw ArgumentError(
        'The "$parmName" parameter cannot be of type "${value.runtimeType}"');
  }

  return tag;
}

Set<LanguageTag> getLanguageTagParmList(
    String parmName, Map parmMap, Directory currentDirectory) {
  Set<LanguageTag> defaultsTo = <LanguageTag>{};
  dynamic value = parmMap[parmName];
  Set<LanguageTag> tag;
  if (value == null) {
    tag = defaultsTo;
  } else if (value is String) {
    tag = defaultsTo..add(LanguageTag.parse(value));
  } else if (value is List) {
    for (String tag in value) {
      defaultsTo.add(LanguageTag.parse(tag));
    }
    tag = defaultsTo;
  } else {
    throw ArgumentError(
        'The "$parmName" parameter cannot be of type "${value.runtimeType}"');
  }

  return tag;
}

void logSubstitute(String parmName, String substituteDescription,
        String substituteValue) =>
    log.info('The "$parmName" parameters is missing, $substituteDescription '
        '("$substituteValue") is used.');

void logFolderCreated(Directory folder) =>
    log.info('The folder "${folder.path}" has been created.');

class Parameters {
  String packageParameter;
  Directory sourceTmxDirectory;
  Directory targetTmxDirectory;
  Directory translationsDirectory;
  LanguageTag defaultLanguage;
  Set<LanguageTag> targetLanguages;
}
