/// Copyright © 2016 Vidya sas. All rights reserved.
/// Created by Giorgio on 04/11/2017.

import 'package:vy_language_tag/vy_language_tag.dart';
import 'package:vy_translation/src/abstract/translation_abstractr.dart';
import 'package:vy_translation/src/annotation/message_definition.dart';
import 'package:vy_translation/src/translation/translation_en_US.dart';

void initTranslationFinder() {
  final TranslationFinder finder = TranslationFinder._();
  finder.setPackageMethod(finder.checkModule, finder.getTranslationMap);
}

TranslationFinder get finder => TranslationFinder();

class TranslationFinder extends TranslationAbstract {
  static TranslationFinder _singleton;

  TranslationFinder._() : super();

  factory TranslationFinder() {
    if (!TranslationAbstract.isInitialized) {
      throw StateError('Translation Finder not yet initialized');
    }
    return _singleton ??= TranslationFinder._();
  }

  @override
  Future checkModule(LanguageTag localeTag) async {
    if (!isLanguageOpen(localeTag)) {
      switch (localeTag.posixCode) {
        case 'en_US':
          // it is opened by default
          break;
        default:
          throw ArgumentError('Unmanaged locale $localeTag');
      }
    }
  }

  @override
  @MessageDefinition('001', 'Unmanaged locale %0', exampleValues: ['fr_FR'])
  Map<String, String> getTranslationMap(LanguageTag language) {
    switch (language.posixCode) {
      case 'en_US':
        return translationsEnUs;
        break;
      default:
        throw ArgumentError('Unmanaged locale $language');
    }
  }

  // Add prefix to tag;
  @override
  String retrieveOpenTranslation(String tag,
      {LanguageTag languageTag, List<String> values}) {
    return super.retrieveOpenTranslation('i18n.$tag',
        languageTag: languageTag, values: values);
  }
}
