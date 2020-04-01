import 'dart:io' show Directory;
import 'package:vy_language_tag/vy_language_tag.dart' show LanguageTag;
import 'package:path/path.dart' as path;

import '../extract_messages.dart' show log;
import 'configuration_parameters.dart' show Parameters;

const String keyPackagePrefix = 'package_prefix';
const String keyMemoryDirectory = 'memory_directory';
const String keyTranslationDirectory = 'translations_directory';
const String keyDefaultLanguage = 'default_language';
const String keyTargetLanguages = 'target_languages';

Parameters extractYamlValues(Map yamlMap, Directory current, String projectName) {
  var parms = Parameters();

  parms.packagePrefix = getStringParm(
      keyPackagePrefix, yamlMap, current, projectName);

  parms.memoryDirectory = getDirectoryParm(
      keyMemoryDirectory, yamlMap, current, 'vy_translation/memory');

  parms.translationDirectory = getDirectoryParm(
      keyTranslationDirectory, yamlMap, current, 'lib/src/translation');

  parms.defaultLanguage = getLanguageTagParm(
      keyDefaultLanguage, yamlMap, current, LanguageTag('en', region: 'US'));

  parms.targetLanguages =
      getLanguageTagParmList(keyTargetLanguages, yamlMap, current);
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

  var dirExists = dir.existsSync();
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
  var defaultsTo = <LanguageTag>{};
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
