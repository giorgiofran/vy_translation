import 'package:vy_analyzer_utils/vy_analyzer_utils.dart'
    show AstUnitInfo, dartConstObjectField, dartConstObjectValue;
import 'package:vy_dart_meme/vy_dart_meme.dart';
import 'package:vy_translation/vy_translation.dart' show MessageDefinition;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:logging/logging.dart';

import '../command/extract_messages_cmd.dart' show errorsReported, parms, store;
import '../extract_messages.dart' show log;
import 'message_store.dart';

class AnnotationRetriever extends GeneralizingAstVisitor<void>
    with AstUnitInfo<void> {
  @override
  void visitAnnotation(Annotation visitAnnotation) {
    if (visitAnnotation.name.name == 'MessageDefinition') {
      MessageDefinition md;
      md = generateMessageDefinition(visitAnnotation);
      addToStore(md, sourcePath ?? 'Unknown');
    }
    super.visitAnnotation(visitAnnotation);
  }

  MessageDefinition generateMessageDefinition(Annotation visitAnnotation) {
    //DartObject dartObject;
    var dartObject = visitAnnotation.elementAnnotation
        ?.computeConstantValue(); //constantValue;
    var id = dartConstObjectField<String>(dartObject, 'id');
    if (id == null) {
      throw StateError('Mandatory Id field in Message definition');
    }
    var text = dartConstObjectField<String>(dartObject, 'text');
    if (text == null) {
      throw StateError(
          'Translation required for Id field "%id" in Message definition');
    }
    var description = dartConstObjectField<String>(dartObject, 'description');
    var internal = dartConstObjectField<List>(dartObject, 'exampleValues');
    var exampleValues = internal == null
        ? null
        : <String>[for (String string in internal) string];
    List<dynamic>? flavors =
        dartConstObjectFieldTranslation(dartObject, 'flavorCollections');
    var flavorTexts = dartConstObjectField<Map<dynamic, dynamic>>(
        dartObject, 'flavorTextPerKey');

    return MessageDefinition(id, text,
        description: description,
        exampleValues: exampleValues,
        flavorCollections: <FlavorCollection>[
          ...?flavors
        ],
        flavorTextPerKey: <List<String>, String>{
          if (flavorTexts != null)
            for (var keyList in flavorTexts.keys)
              <String>[...keyList]: flavorTexts[keyList]
        });
  }

  void addToStore(MessageDefinition definition, String sourcePath) {
    var key = '${parms.packagePrefix}.${definition.id}';
    if (store[key] != null) {
      var storeMessage = store[key]!;
      if (definition != storeMessage.definition) {
        if (definition.id == storeMessage.definition.id &&
            definition.text == storeMessage.definition.text) {
          if (definition.description != storeMessage.definition.description) {
            log.warning('Two message definition with id '
                '"${storeMessage.definition.id}" and text '
                '"${storeMessage.definition.text}" have a different '
                'description.\nThey come from the following sources:\n'
                '- ${storeMessage.sourcePath}\n- $sourcePath\n'
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
    DartObject? dartObject, String fieldName) {
  if (dartObject == null) {
    return null;
  }
  return dartConstObjectValueTranslation(dartObject.getField(fieldName));
}

dynamic dartConstObjectValueTranslation(DartObject? dartObject) {
  if (dartObject == null) {
    return null;
  }
  //ParameterizedType fieldType;
  var fieldType = dartObject.type;

  if (fieldType == null || fieldType.isDartCoreNull) {
    return null;
  } else if (fieldType.toString() == 'List<FlavorCollection>' ||
      '$fieldType' == 'List<FlavorCollection*>*') {
    var internal = dartObject.toListValue();
    if (internal == null) {
      return null;
    }
    return [
      for (DartObject content in internal)
        dartConstObjectValueTranslation(content)
    ];
  } else if ('$fieldType' == 'FlavorCollection' ||
      '$fieldType' == 'FlavorCollection*') {
    return (FlavorCollection(
        dartConstObjectFieldTranslation(dartObject, 'name'),
        <String>[...dartConstObjectFieldTranslation(dartObject, '_flavors')]));
  } else if (dartObject.getField('(super)')?.type?.toString() ==
          'FlavorCollection' ||
      dartObject.getField('(super)')?.type?.toString() == 'FlavorCollection*') {
    return dartConstObjectFieldTranslation(dartObject, '(super)');
  } else {
    return dartConstObjectValue(dartObject);
  }
}
