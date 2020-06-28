import 'dart:io';

import 'package:yaml/yaml.dart';

import 'extract_yaml_map.dart';

/// *************************
/// loads pubspec.yaml
Future<YamlMap> extractPubspec(Directory pubspecDirectory) async =>
    extractYamlMap(pubspecDirectory, 'pubspec');

/// *************************
/// loads vy_translation.yaml
Future<YamlMap> extractVyTranslation(Directory vyTranslationDirectory) async =>
    extractYamlMap(vyTranslationDirectory, 'vy_translation');
