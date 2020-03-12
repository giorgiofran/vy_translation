import 'dart:io';

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
  final TranslationFinder finder = TranslationFinder._();
  finder.setPackageMethod(finder.checkModule, finder.getTranslationMap);
}
''';
const String defFinder =
    'TranslationFinder get finder => TranslationFinder();\n';
const String classDef = '''
class TranslationFinder extends TranslationAbstract {
  static TranslationFinder _singleton;
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
  Map<String, String> getTranslationMap(LanguageTag languageTag) {
    switch (languageTag.posixCode) {
      case 'en_US':
        return translationsEnUs;
        break;
''';
const String defLanguageTranslationMap = r'''
      case '%0':
        return def_translations_%1.translations%2;
        break;
''';
const String defEndTranslationMap = r'''
      default:
        return null;
    }
  }
''';
const String defGet = r'''
  @override
  String get(String tag, {LanguageTag languageTag, List<String> values}) =>
      super.get('%0.$tag',
          languageTag: languageTag, values: values);
''';
const String closeClassDef = '}';

Future<void> generateTranslationFinderClass(Parameters parms) async {
  Directory directory = parms.translationDirectory;
  File targetFile = File('${directory.path}/translation_finder.dart');
  bool exists = await targetFile.exists();
  if (exists) {
    await targetFile.delete();
  }
  await targetFile.create(recursive: true);

  StringBuffer buffer = StringBuffer();
  buffer.writeln('');
  buffer.writeln(genericImports);
  writeLanguageImport(buffer, parms.defaultLanguage, isDefault: true);
  for (LanguageTag languageTag in parms.targetLanguages) {
    writeLanguageImport(buffer, languageTag);
  }
  buffer.writeln('');
  buffer.writeln(initTrFinder);
  buffer.writeln(defFinder);
  buffer.writeln(classDef);
  buffer.writeln(
      defConstructor.replaceFirst('%0', parms.defaultLanguage.posixCode));
  buffer.writeln(defFactory);
  buffer.writeln(
      defInitCheckModule.replaceFirst('%0', parms.defaultLanguage.posixCode));
  for (LanguageTag languageTag in parms.targetLanguages) {
    buffer.writeln(defLanguageCheckModule
        .replaceAll('%0', languageTag.posixCode)
        .replaceAll('%1', languageTag.lowercasePosix));
  }
  buffer.writeln(defEndCheckModule);
  buffer.writeln(defInitTranslationMap.replaceFirst(
      '%0', parms.defaultLanguage.posixCode));
  for (LanguageTag languageTag in parms.targetLanguages) {
    buffer.writeln(defLanguageTranslationMap
        .replaceAll('%0', languageTag.posixCode)
        .replaceAll('%1', languageTag.lowercasePosix)
        .replaceAll('%2', ReCase(languageTag.lowercasePosix).pascalCase));
  }
  buffer.writeln(defEndTranslationMap);
  buffer.writeln(defGet.replaceAll('%0', parms.packagePrefix));
  buffer.writeln(closeClassDef);
  await targetFile.writeAsString(buffer.toString());
}

void writeLanguageImport(StringBuffer buffer, LanguageTag languageTag,
    {bool isDefault}) {
  isDefault ??= false;
  buffer.write("import 'translation_${languageTag.lowercasePosix}.dart'");
  if (isDefault) {
    buffer.writeln(';');
  } else {
    buffer.writeln('');
    buffer.write(baseDeferred);
    buffer.writeln('${languageTag.lowercasePosix};');
  }
}
