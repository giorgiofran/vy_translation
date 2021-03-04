import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:recase/recase.dart';
import 'package:vy_language_tag/vy_language_tag.dart';

import '../utils/configuration_parameters.dart';

const String genericImports =
    '''import 'package:vy_language_tag/vy_language_tag.dart';
import 'package:vy_translation/src/abstract/translation_abstract.dart';
''';

const String baseDeferred = '    deferred as def_translations_';

const String initTrFinder = '''
void initTranslationFinder() {
  var finder = TranslationFinder._();
  finder.setPackageMethod(finder.checkModule, finder.getTranslationMap);
}
''';
const String defFinder =
    'TranslationFinder get finder => TranslationFinder();\n';
const String classDef = '''
class TranslationFinder extends TranslationAbstract {
  static TranslationFinder? _singleton;
''';
String defConstructor =
    "TranslationFinder._() : super(LanguageTag.parse('%0'));";
const String defFactory = '''
  factory TranslationFinder() {
    if (!TranslationAbstract.isInitialized) {
      throw StateError('Translation Finder not yet initialized');
    }
    return _singleton ??= TranslationFinder._();
  }
''';
const String defInitCheckModule = r'''
  @override
  Future checkModule(LanguageTag languageTag) async {
    if (!isLanguageOpen(languageTag)) {
      TranslationAbstract.log
          .fine('Opening message file for language tag ${languageTag.code}.');
      switch (languageTag.posixCode) {
        case '%0':
          // it is opened by default
          break;
''';
const String defLanguageCheckModule = r'''
        case '%0':
          await def_translations_%1.loadLibrary();
          addOpenedLanguageTag(languageTag);
          break;
''';
const String defEndCheckModule = r'''
        default:
          throw ArgumentError('Unmanaged locale $languageTag');
      }
    }
  }
''';
const String defInitTranslationMap = r'''
 @override
  Map<String, String>? getTranslationMap(LanguageTag languageTag) {
    switch (languageTag.posixCode) {
      case '%0':
        return translations%1;
''';
const String defLanguageTranslationMap = r'''
      case '%0':
        return def_translations_%1.translations%2;
''';
const String defEndTranslationMap = r'''
      default:
        return null;
    }
  }
''';
const String defGet = r'''
  @override
  String get(String tag,
          {LanguageTag? languageTag,
          List<String>? values,
          Object? flavorKeys,
          String? project,
          bool? throwErrorIfMissing}) =>
      super.get('${project ?? '%0'}.$tag',
          languageTag: languageTag,
          values: values,
          flavorKeys: flavorKeys,
          throwErrorIfMissing: throwErrorIfMissing);
''';
const String closeClassDef = '}';

Future<void> generateTranslationFinderClass(Parameters parms) async {
  final _dartFmt = DartFormatter();

  if (parms.translationDirectory == null) {
    throw StateError('Missing translation Directory');
  }
  if (parms.defaultLanguage == null) {
    throw StateError('Missing Default Language');
  }
  var _defaultLanguage = parms.defaultLanguage!;
  if (parms.packagePrefix == null) {
    throw StateError('Missing Package Prefix');
  }

  var directory = parms.translationDirectory!;
  var targetFile = File('${directory.path}/translation_finder.dart');
  var exists = await targetFile.exists();
  if (exists) {
    await targetFile.delete();
  }
  await targetFile.create(recursive: true);

  var buffer = StringBuffer();
  buffer.writeln('');
  buffer.writeln(genericImports);
  writeLanguageImport(buffer, _defaultLanguage, isDefault: true);
  for (var languageTag in parms.targetLanguages ?? {}) {
    writeLanguageImport(buffer, languageTag);
  }
  buffer.writeln('');
  buffer.writeln(initTrFinder);
  buffer.writeln(defFinder);
  buffer.writeln(classDef);
  buffer.writeln(defConstructor.replaceFirst('%0', _defaultLanguage.posixCode));
  buffer.writeln(defFactory);
  buffer.writeln(
      defInitCheckModule.replaceFirst('%0', _defaultLanguage.posixCode));
  for (var languageTag in parms.targetLanguages ?? {}) {
    buffer.writeln(defLanguageCheckModule
        .replaceAll('%0', languageTag.posixCode)
        .replaceAll('%1', languageTag.lowercasePosix));
  }
  buffer.writeln(defEndCheckModule);
  buffer.writeln(defInitTranslationMap
      .replaceFirst('%0', _defaultLanguage.posixCode)
      .replaceFirst('%1', ReCase(_defaultLanguage.lowercasePosix).pascalCase));
  for (var languageTag in parms.targetLanguages ?? {}) {
    buffer.writeln(defLanguageTranslationMap
        .replaceAll('%0', languageTag.posixCode)
        .replaceAll('%1', languageTag.lowercasePosix)
        .replaceAll('%2', ReCase(languageTag.lowercasePosix).pascalCase));
  }
  buffer.writeln(defEndTranslationMap);
  buffer.writeln(defGet.replaceAll('%0', parms.packagePrefix!));
  buffer.writeln(closeClassDef);
  await targetFile.writeAsString(_dartFmt.format('$buffer'));
}

void writeLanguageImport(StringBuffer buffer, LanguageTag languageTag,
    {bool? isDefault}) {
  var _isDefault = isDefault ?? false;
  buffer.write("import 'translation_${languageTag.lowercasePosix}.dart'");
  if (_isDefault) {
    buffer.writeln(';');
  } else {
    buffer.writeln('');
    buffer.write(baseDeferred);
    buffer.writeln('${languageTag.lowercasePosix};');
  }
}
