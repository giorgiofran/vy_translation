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
      MessageDefinition md;
      md = generateMessageDefinition(visitAnnotation);
      addToStore(md, sourcePath);
    }
    super.visitAnnotation(visitAnnotation);
  }

  MessageDefinition generateMessageDefinition(Annotation visitAnnotation) {
    DartObject dartObject;
    dartObject = visitAnnotation.elementAnnotation.constantValue;
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

  void addToStore(MessageDefinition definition, String sourcePath) {
    var key = '${parms.packagePrefix}.${definition.id}';
    if (store.containsKey(key)) {
      MessageStore storeMessage;
      storeMessage = store[key];
      if (definition != storeMessage.definition) {
        if (definition.id == storeMessage.definition.id &&
            definition.text == storeMessage.definition.text) {
          if (definition.description != storeMessage.definition.description) {
            log.warning('Two message definition with id '
                '"${storeMessage.definition.id}" and text '
                '"${storeMessage.definition.text}" have a different '
                'description.\nThey come from the following sources:\n'
                '- ${storeMessage.sourcePath}\n- ${sourcePath}\n'
                'Only the first is maintained');
          } else {
            log.warning(
                'Two message definition with id "${storeMessage.definition.id}" '
                'and text "${storeMessage.definition.text}" have a different '
                'list of example values.\n'
                'They come from the following sources:\n'
                '- ${storeMessage.sourcePath}\n- $sourcePath\n'
                'Only the first is maintained');
          }
        } else {
          errorsReported = true;
          log.severe('Two message definition with the same id '
              '"${storeMessage.definition.id}" but different '
              'text have been detected.\n'
              'They come from the following sources:\n'
              '- ${storeMessage.sourcePath}\n- $sourcePath');
        }
      }
    } else {
      store[key] = MessageStore(key, sourcePath, definition);
      if (log.level <= Level.FINE) {
        log.fine('The message with id "$key" and text "${definition.text}" '
            'has been processed.');
      }
    }
  }
}
