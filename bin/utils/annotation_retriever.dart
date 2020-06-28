import 'package:vy_analyzer_utils/vy_analyzer_utils.dart'
    show AstUnitInfo, dartConstObjectField, dartConstObjectValue;
import 'package:vy_dart_meme/vy_dart_meme.dart';
import 'package:vy_translation/vy_translation.dart' show MessageDefinition;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:logging/logging.dart';
import 'package:analyzer/dart/element/type.dart';

import '../command/extract_messages_cmd.dart' show errorsReported, parms, store;
import '../extract_messages.dart' show  log ;
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
    List<dynamic> flavors =
        dartConstObjectFieldTranslation(dartObject, 'flavorCollections');
    Map<dynamic, dynamic> flavorTexts =
        dartConstObjectField(dartObject, 'flavorTextPerKey');

    return MessageDefinition(id, text,
        description: description,
        exampleValues: exampleValues,
        flavorCollections: <FlavorCollection>[
          if (flavors != null) ...flavors
        ],
        flavorTextPerKey: <List<String>, String>{
          if (flavorTexts != null)
            for (var keyList in flavorTexts.keys)
              <String>[...keyList]: flavorTexts[keyList]
        });
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

dynamic dartConstObjectFieldTranslation(
    DartObject dartObject, String fieldName) {
  if (dartObject == null) {
    return null;
  }
  return dartConstObjectValueTranslation(dartObject.getField(fieldName));
}

dynamic dartConstObjectValueTranslation(DartObject dartObject) {
  if (dartObject == null) {
    return null;
  }
  ParameterizedType fieldType;
  fieldType = dartObject.type;

  if (fieldType == null || fieldType.isDartCoreNull) {
    return null;
  } else if (fieldType. /*getDisplayString()*/ toString() ==
      'List<FlavorCollection>') {
    List internal = dartObject.toListValue();
    if (internal == null) {
      return null;
    }
    return [
      for (DartObject content in internal)
        dartConstObjectValueTranslation(content)
    ];
  } else if (fieldType. /*getDisplayString()*/ toString() ==
      'FlavorCollection') {
    return (FlavorCollection(
        dartConstObjectFieldTranslation(dartObject, 'name'),
        <String>[...dartConstObjectFieldTranslation(dartObject, '_flavors')]));
  } else if (dartObject
          .getField('(super)')
          ?.type
          ?. /*getDisplayString()*/ toString() ==
      'FlavorCollection') {
    return dartConstObjectFieldTranslation(dartObject, '(super)');
  } else {
    return dartConstObjectValue(dartObject);
  }
}
