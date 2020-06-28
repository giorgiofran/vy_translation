import 'dart:io';

import 'package:vy_string_utils/vy_string_utils.dart' show unfilled;
import 'constants.dart';
import 'extract_configs.dart';

Future<String> extractProjectName(Directory pubspecDirectory) async {
  var pubspecMap = await extractPubspec(pubspecDirectory);

  String projectName = pubspecMap[keyName];
  if (unfilled(projectName)) {
    throw StateError('Missing project name in file "pubspec.yaml"');
  }
  return projectName;
}
