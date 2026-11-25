import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/onboarding/domain/onboarding_defaults.dart';

void main() {
  test('phone language is used when a Bible exists in it', () {
    expect(defaultLanguageFor('yo'), 'yo');
    expect(defaultLanguageFor('HA'), 'ha');
  });

  test('unknown phone language falls back to English', () {
    expect(defaultLanguageFor('fr'), 'en');
    expect(defaultLanguageFor(''), 'en');
  });

  test('languages are listed once, in catalogue order', () {
    final langs = onboardingLanguages();
    expect(langs.first, 'en');
    expect(langs.toSet().length, langs.length);
    expect(langs, containsAll(['en', 'yo']));
  });

  test('editions are filtered by language and the first one is the default', () {
    final en = editionsForLanguage('en');
    expect(en.length, greaterThan(1));
    expect(en.every((e) => e.languageCode == 'en'), isTrue);
    expect(defaultEditionFor('en'), en.first.id);
    expect(defaultEditionFor('en'), 'en-kjv');
  });
}
