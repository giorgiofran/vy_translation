import 'dart:collection';

Map<String, String> translationsEnUs = SplayTreeMap<String, String>()
  ..addAll(<String, String>{
    'vy_translation.0001': 'The placeholder "%%0" in message "%1" has not been '
        'found.',
    'vy_translation.0002':
        'Language "%0" has not been opened yet. Using default '
            'language "en_US".',
    'vy_translation.test-message': 'Male version',
    'vy_translation.test-message.female': 'Female version',
  });
