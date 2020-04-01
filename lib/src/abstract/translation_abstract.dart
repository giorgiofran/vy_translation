import 'package:vy_language_tag/vy_language_tag.dart';
import 'package:vy_lock/vy_lock.dart' show Mutex;
import 'package:logging/logging.dart';
import 'package:vy_translation/src/annotation/message_definition.dart';
import 'package:vy_translation/src/translation/translation_finder.dart';

typedef checkModuleFn = Future Function(LanguageTag);
typedef getTranslationMapFn = Map<String, String> Function(LanguageTag);

abstract class TranslationAbstract {
  static checkModuleFn _checkModule;
  static getTranslationMapFn _getTranslationMap;
  static bool get isInitialized =>
      _checkModule != null && _getTranslationMap != null;

  static final log = Logger('TranslationAbstract');

  static LanguageTag _defaultLanguageTag;
  static final List<String> _openedLanguages = <String>[];

  TranslationAbstract(LanguageTag defaultLanguage) {
    _defaultLanguageTag = defaultLanguage;
    addOpenedLanguageTag(defaultLanguage);
  }

  Mutex lock = Mutex();

  Future<void> setDefaultLanguage(LanguageTag languageTag) async {
    _defaultLanguageTag = languageTag;
    await _checkModuleSecured(languageTag);
    log.fine('Language "${languageTag.code}" set as default. '
        'Tag added to opened list: ${isLanguageOpen(languageTag)}');
  }

  Future<void> initTranslationLanguage(LanguageTag languageTag) async =>
      await _checkModuleSecured(languageTag);

  bool isLanguageOpen(LanguageTag languageTag) =>
      _openedLanguages.contains(languageTag.posixCode);

  void addOpenedLanguageTag(LanguageTag languageTag) =>
      _openedLanguages.add(languageTag.posixCode);

  void setPackageMethod(checkModuleFn checkModuleFunction,
      getTranslationMapFn getTranslationMapFunction) {
    _checkModule = checkModuleFunction;
    _getTranslationMap = getTranslationMapFunction;
  }

  /// This method is not called in this class
  /// it is used as a facility for subclasses
  /// in order to define the method to pass
  /// to the _checkModule method during init
  /// (in the setPackageMethod function)
  ///
  /// If the language tag is not managed throws error
  Future checkModule(LanguageTag languageTag);

  /// This method is not called in this class
  /// it is used as a facility for subclasses
  /// in order to define the method to pass
  /// to the _getTranslationMap method during init
  /// (in the setPackageMethod function)
  ///
  /// If the language tag is not managed returns null
  Map<String, String> getTranslationMap(LanguageTag languageTag);

  Future<void> _checkModuleSecured(LanguageTag languageTag) async {
    await lock.mutex(() async {
      await _checkModule(languageTag);
    });
  }

  Future<String> retrieveTranslation(LanguageTag languageTag, String tag,
      {List<String> values}) async {
    await _checkModuleSecured(languageTag);
    return get(tag, languageTag: languageTag, values: values);
  }

  @MessageDefinition('0002',
      'Language "%0" has not been opened yet. Using default language "en_US".',
      exampleValues: ['it_IT'],
      description: 'Before calling a translated message, the relative language '
          'must be initiated. When this happens the default language is used.')
  String get(String tag, {LanguageTag languageTag, List<String> values}) {
    languageTag ??= _defaultLanguageTag;

    if (!isLanguageOpen(languageTag)) {
      log.warning(finder.get('0002', values: [languageTag.code]));
      languageTag = LanguageTag('en', region: 'US');
    }

    String returnMessage;
    Map translationMap = _getTranslationMap(languageTag);
    if (translationMap.containsKey(tag)) {
      returnMessage = translationMap[tag];
    }
    if (returnMessage == null) {
      LanguageTag retry;
      retry = languageTag;
      while (retry.canBeTruncated) {
        retry = retry.truncated;
        translationMap = _getTranslationMap(retry);
        // In case the truncated tag is not managed.
        if (translationMap == null) {
          continue;
        }
        if (translationMap.containsKey(tag)) {
          returnMessage = translationMap[tag];
          if (returnMessage != null) {
            break;
          }
        }
      }
    }
    if (returnMessage == null) {
      translationMap = _getTranslationMap(LanguageTag('en', region: 'US'));
      returnMessage = translationMap[tag] ?? '';
    }
    if (values == null || values.isEmpty) {
      return returnMessage;
    }
    return _mergeMessage(returnMessage, values, languageTag);
  }

  /// Receive a message String and inject values, if any
  /// Message ex. 'Compose message %0'
  /// values placeholders in the message must be prefixed by a "%" (Ex. %0)
  /// The values List is composed by the values to be used
  /// (already converted into String)
  /// The placeholder %0 is the first element of the list,
  /// the %1 is the second, and so on.
  String _mergeMessage(
      String message, List<String> values, LanguageTag languageTag) {
    if (message == null) {
      return '';
    }
    if (values == null || values.isEmpty) {
      return message;
    }
    @MessageDefinition(
        '0001', 'The placeholder "%%0" in message "%1" has not been found.',
        exampleValues: ['2', 'File %0 in folder %1'],
        description: 'The message evidentiate when a value is passed '
            'but no placeholder has been found to use it.\nThis could be caused '
            'by a wrong message or a wrong list of values in the call')
    String ret, check = message;
    for (var idx = 0; idx < values.length; idx++) {
      ret = check.replaceAll('%$idx', values[idx]);
      if (ret == check) {
        throw ArgumentError(finder.get('0001',
            languageTag: languageTag, values: ['$idx', '$message']));
      }
      check = ret;
    }

    return ret;
  }
}
