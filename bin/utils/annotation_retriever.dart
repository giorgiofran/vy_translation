import 'package:vy_analyzer_utils/vy_analyzer_utils.dart'
    show AstUnitInfo, dartConstObjectField;
import 'package:vy_translation/src/translation/translation_finder.dart';
import 'package:vy_translation/vy_translation.dart' show MessageDefinition;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:logging/logging.dart';

import '../extract_messages.dart';
import 'message_store.dart';

class AnnotationRetriever extends GeneralizingAstVisitor<void>
    with AstUnitInfo<void> {
  @override
  void visitAnnotation(Annotation visitAnnotation) {
    if (visitAnnotation.name.name == 'MessageDefinition') {
      MessageDefinition md = generateMessageDefinition(visitAnnotation);
      addToStore(md, sourcePath);
    }
    super.visitAnnotation(visitAnnotation);
  }

  MessageDefinition generateMessageDefinition(Annotation visitAnnotation) {
    DartObject dartObject = visitAnnotation.elementAnnotation.constantValue;
    String id = dartConstObjectField(dartObject, 'id');

    String text = dartConstObjectField(dartObject, 'text');
    String description = dartConstObjectField(dartObject, 'description');
    List<dynamic> internal = dartConstObjectField(dartObject, 'exampleValues');
    List<String> exampleValues = internal == null
        ? internal
        : <String>[for (String string in internal) string];
    return MessageDefinition(id, text,
        description: description, exampleValues: exampleValues);
  }

  @MessageDefinition(
      '0001',
      'Two message definition with id "%0" and text "%1" have a different '
          'description.\nThey come from the following sources:\n- %2\n- %3\n'
          'Only the first is maintained')
  @MessageDefinition(
      '0002',
      'Two message definition with id "%0" and text "%1" have a different '
          'list of example values.\n'
          'They come from the following sources:\n- %2\n- %3\n'
          'Only the first is maintained')
  @MessageDefinition(
      '0003',
      'Two message definition with the same id "%0" but different '
          'text have been detected.\n'
          'They come from the following sources:\n- %1\n- %2')
  @MessageDefinition(
      '0004', 'The message with id "%0" and text "%1" has been processed.')
  void addToStore(MessageDefinition definition, String sourcePath) {
    String key = '${parms.packagePrefix}.${definition.id}';
    if (store.containsKey(key)) {
      MessageStore storeMessage = store[key];
      if (definition != storeMessage.definition) {
        if (definition.id == storeMessage.definition.id &&
            definition.text == storeMessage.definition.text) {
          if (definition.description != storeMessage.definition.description) {
            log.warning(finder.get('0001', values: [
              storeMessage.definition.id,
              storeMessage.definition.text,
              storeMessage.sourcePath,
              sourcePath
            ]));
          } else {
            log.warning(finder.get('0002', values: [
              storeMessage.definition.id,
              storeMessage.definition.text,
              storeMessage.sourcePath,
              sourcePath
            ]));
          }
        } else {
          errorsReported = true;
          log.severe(finder.get('0003', values: [
            storeMessage.definition.id,
            storeMessage.sourcePath,
            sourcePath
          ]));
        }
      }
    } else {
      store[key] = MessageStore(key, sourcePath, definition);
      if (log.level <= Level.FINE) {
        log.fine(finder.get('0004', values: [key, definition.text]));
      }
    }
  }
}
