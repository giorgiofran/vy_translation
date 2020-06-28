import 'dart:io';

import 'package:yaml/yaml.dart';

/// *************************
/// loads pubspec.yaml
Future<YamlMap> extractYamlMap(Directory directory, String fileName) async {
  var yamlFile = File('${directory.path}/$fileName.yaml');
  var existsFile = await yamlFile.exists();
  if (!existsFile) {
    if (fileName == 'pubspec') {
      throw StateError('The directory "${directory.path}" is not a dart project. '
          '(missing file "pubspec.yaml")');
    }
    throw StateError(
        'The directory "$directory" does not contain the file "$fileName.yaml"');
  }
  YamlMap yamlMap = loadYaml(await yamlFile.readAsString());
  if (yamlMap == null) {
    throw StateError(
        'File "$fileName.yaml" in directory "$directory" is empty');
  }
  return yamlMap;
}
