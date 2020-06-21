import 'package:vy_language_tag/vy_language_tag.dart';
import 'package:vy_translation/src/abstract/translation_abstract.dart';

import 'translation_en_us.dart';
import 'translation_en_gb.dart' deferred as def_translations_en_gb;
import 'translation_en_ca.dart' deferred as def_translations_en_ca;
import 'translation_en_in.dart' deferred as def_translations_en_in;

void initTranslationFinder() {
  var finder = TranslationFinder._();
  finder.setPackageMethod(finder.checkModule, finder.getTranslationMap);
}

TranslationFinder get finder => TranslationFinder();

class TranslationFinder extends TranslationAbstract {
  static TranslationFinder _singleton;

  TranslationFinder._() : super(LanguageTag.parse('en_US'));
  factory TranslationFinder() {
    if (!TranslationAbstract.isInitialized) {
      throw StateError('Translation Finder not yet initialized');
    }
    return _singleton ??= TranslationFinder._();
  }

  @override
  Future checkModule(LanguageTag languageTag) async {
    if (!isLanguageOpen(languageTag)) {
      TranslationAbstract.log
          .fine('Opening message file for language tag ${languageTag.code}.');
      switch (languageTag.posixCode) {
        case 'en_US':
          // it is opened by default
          break;

        case 'en_GB':
          await def_translations_en_gb.loadLibrary();
          addOpenedLanguageTag(languageTag);
          break;

        case 'en_CA':
          await def_translations_en_ca.loadLibrary();
          addOpenedLanguageTag(languageTag);
          break;

        case 'en_IN':
          await def_translations_en_in.loadLibrary();
          addOpenedLanguageTag(languageTag);
          break;

        default:
          throw ArgumentError('Unmanaged locale $languageTag');
      }
    }
  }

  @override
  Map<String, String> getTranslationMap(LanguageTag languageTag) {
    switch (languageTag.posixCode) {
      case 'en_US':
        return translationsEnUs;
        break;

      case 'en_GB':
        return def_translations_en_gb.translationsEnGb;
        break;

      case 'en_CA':
        return def_translations_en_ca.translationsEnCa;
        break;

      case 'en_IN':
        return def_translations_en_in.translationsEnIn;
        break;

      default:
        return null;
    }
  }

  @override
  String get(String tag,
          {LanguageTag languageTag, List<String> values, Object flavorKeys}) =>
      super.get('vy_translation.$tag',
          languageTag: languageTag, values: values, flavorKeys: flavorKeys);
}
