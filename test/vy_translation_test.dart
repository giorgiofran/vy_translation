import 'package:vy_translation/vy_translation.dart';
import 'package:vy_translation/src/translation/translation_finder.dart';
import 'package:vy_dart_meme/src/flavor_collections/male_female_flavor.dart';
import 'package:test/test.dart';

@MessageDefinition('test-message', 'Male version', flavorCollections: [
  MaleFemaleFlavor()
], flavorTextPerKey: {
  [MaleFemaleFlavor.female]: 'Female version'
})
void main() {
  initTranslationFinder();
  group('get', () {
    test('Get test-message', () {
      expect(finder.get('test-message'), 'Male version');
      expect(finder.get('test-message', flavorKeys: MaleFemaleFlavor.female),
          'Female version');
      expect(finder.get('test-message', flavorKeys: [MaleFemaleFlavor.female]),
          'Female version');
      expect(finder.get('test-message', flavorKeys: 'missing'), 'Male version');
      expect(finder.get('test-message', flavorKeys: null), 'Male version');
    });
  });

  group('get error', () {
    test('Get test-message', () {
      expect(finder.get('test-msg'), '*** <vy_translation.test-msg>');
      expect(finder.get('test-msg', flavorKeys: MaleFemaleFlavor.female),
          '*** <vy_translation.test-msg>');
      expect(
          () => finder.get('test-message',
              flavorKeys: [MaleFemaleFlavor.female], values: ['error']),
          throwsArgumentError);
    });
  });
}
