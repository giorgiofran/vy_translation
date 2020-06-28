import 'package:quiver/core.dart';
import 'package:vy_translation/src/annotation/message_definition.dart';

/// Identifies an unique Message Definition
///
/// The key contains also the package prefix (Ex. 'vy_translation.msg0001')
/// The source path is needed because if two different messages have
///   the same key we can correctly identify their provenience.
class MessageStore {
  /// contains also the package prefix
  final String key;
  final String sourcePath;
  final MessageDefinition definition;

  const MessageStore(this.key, this.sourcePath, this.definition);

  @override
  bool operator ==(other) =>
      other is MessageStore &&
      key == other.key &&
      sourcePath == other.sourcePath &&
      definition == other.definition;

  @override
  int get hashCode => hashObjects(['$key#$sourcePath', definition]);
}
