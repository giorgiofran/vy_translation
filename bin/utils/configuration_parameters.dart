import 'dart:io';
import 'package:vy_language_tag/vy_language_tag.dart';

class Parameters {
  String packagePrefix;
  Directory memoryDirectory;
  Directory translationDirectory;
  LanguageTag defaultLanguage;
  Set<LanguageTag> targetLanguages;
}