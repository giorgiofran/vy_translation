/*
/// Copyright © 2016 Vidya sas. All rights reserved.
/// Created by Giorgio on 04/11/2017.

import 'package:vidya_base/translation/translation_en.dart'
    as def_translations_en;
import 'package:vidya_base/translation/translation_en_us.dart'
    deferred as def_translations_en_US;
import 'package:vidya_base/translation/translation_it.dart'
    deferred as def_translations_it;
import 'package:vidya_base/translation/translation_it_it.dart'
    deferred as def_translations_it_IT;
import 'package:vidya_base/translation/translation_pt.dart'
    deferred as def_translations_pt;
import 'package:vidya_base/translation/translation_pt_br.dart'
    deferred as def_translations_pt_BR;
import 'package:vidya_base/vidya_base.dart' show Locker;
import 'package:vidya_base/vidya_base.dart';

/// Receive a message String and inject values, if any
/// Message ex. 'Compose message $0'
/// values placeholders in the message must be prefixed by a $ (Ex. $0)
/// The values List is composed by the values to be used
/// (already converted into String)
/// The placeholder $0 is the first element of the list,
/// the $1 is the second, and so on.
String mergeMessage(String message, List<String> values) {
  if (message == null) {
    return '';
  }
  if (values == null || values.isEmpty) {
    return message;
  }
  String ret, check = message;
  for (int idx = 0; idx < values.length; idx++) {
    ret = check.replaceAll('\$$idx', values[idx]);
    if (ret == check) {
      throw ArgumentError(
          'The placeholder "\$$idx" in message $message has not been found.');
    }
  }

  return ret;
}

class TranslationFinder {
  static const String parmLanguage = 'language';

  List<String> openedLanguages = <String>['en'];
  Locker sideListLocker = Locker();

  bool isLanguageOpen(String languageLocale) =>
      openedLanguages.contains(languageLocale);

  Future _checkModule(String languageLocale) async {
    if (!openedLanguages.contains(languageLocale)) {
      switch (languageLocale) {
        case 'en':
          // it is opened by default
          break;
        case 'en_US':
          await def_translations_en_US.loadLibrary();
          openedLanguages.add(languageLocale);
          break;
        case 'it':
          await def_translations_it.loadLibrary();
          openedLanguages.add(languageLocale);
          break;
        case 'it_IT':
          await def_translations_it_IT.loadLibrary();
          openedLanguages.add(languageLocale);
          break;
        case 'pt':
          await def_translations_pt.loadLibrary();
          openedLanguages.add(languageLocale);
          break;
        case 'pt_BR':
          await def_translations_pt_BR.loadLibrary();
          openedLanguages.add(languageLocale);
          break;
      }
    }
  }

  Map _getTranslationMap(String languageLocale) {
    switch (languageLocale) {
      case 'en':
        return def_translations_en.translationsEn;
        break;
      case 'en_US':
        return def_translations_en_US.translationsEnUS;
        break;
      case 'it':
        return def_translations_it.translationsIt;
        break;
      case 'it_IT':
        return def_translations_it_IT.translationsItIT;
        break;
      case 'pt':
        return def_translations_pt.translationsPt;
        break;
      case 'pt_BR':
        return def_translations_pt_BR.translationsPtBR;
        break;
    }
    return null;
  }

  Future<T> _checkModuleSecured<T>(String languageLocale) async {
    Future<T> _recall<T>(Map<dynamic, dynamic> values) =>
        _checkModuleSecured<T>(values[parmLanguage]);

    if (sideListLocker.locked) {
      return sideListLocker.waitLock<T>({parmLanguage: languageLocale});
    }
    sideListLocker.setFunction(_recall);
    sideListLocker.lock();
    try {
      await _checkModule(languageLocale);
    } finally {
      sideListLocker.unlock();
    }
    return null;
  }

  Future<String> retrieveTranslation(String languageLocale, String tag) async {
    await _checkModuleSecured(languageLocale);
    return retrieveOpenTranslation(languageLocale, tag);
  }

  String retrieveOpenTranslation(String languageLocale, String tag) {
    if (!isLanguageOpen(languageLocale)) {
      languageLocale = 'en';
    }
    // Todo escalate locale
    final Map translationMap = _getTranslationMap(languageLocale);
    return translationMap[tag];
  }
}

class TranslationCreator {
  final String id;
  final String text;
  final String description;

  TranslationCreator(this.id, this.text, {this.description});
}
*/
