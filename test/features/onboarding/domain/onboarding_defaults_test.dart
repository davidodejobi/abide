import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';
import 'package:openbaptisthymnal/features/onboarding/domain/onboarding_defaults.dart';

BibleEdition _e(String id) => BibleEdition(
    id: id,
    languageCode: id.split('-').first,
    versionCode: id.split('-').last,
    displayName: id,
    attribution: '');

void main() {
  // Only the three English Bibles are bundled; the rest are downloaded later,
  // so the multi-language cases use a fixture list.
  final editions = [
    for (final id in ['en-kjv', 'en-bsb', 'yo-bmy', 'ha-biblica']) _e(id)
  ];

  test('phone language is used when a Bible exists in it', () {
    expect(defaultLanguageFor('yo', editions), 'yo');
    expect(defaultLanguageFor('HA', editions), 'ha');
    expect(defaultLanguageFor('yo'), 'en'); // not bundled
  });

  test('unknown phone language falls back to English', () {
    expect(defaultLanguageFor('fr'), 'en');
    expect(defaultLanguageFor(''), 'en');
  });

  test('languages are listed once, in catalogue order', () {
    final langs = onboardingLanguages(editions);
    expect(langs.first, 'en');
    expect(langs.toSet().length, langs.length);
    expect(langs, containsAll(['en', 'yo']));
    expect(onboardingLanguages(), ['en']);
  });

  test('editions are filtered by language and the first one is the default',
      () {
    final en = editionsForLanguage('en');
    expect(en.length, greaterThan(1));
    expect(en.every((e) => e.languageCode == 'en'), isTrue);
    expect(defaultEditionFor('en'), en.first.id);
    expect(defaultEditionFor('en'), 'en-kjv');
  });

  group('onboardingDefaultPlan', () {
    ReadingPlan plan(String id, {String? startsOn, int? year}) => ReadingPlan(
        id: id,
        title: id,
        description: '',
        days: const [],
        startsOn: startsOn,
        firstRunYear: year);
    final plans = [
      plan('psalms-30'),
      plan('nt-90'),
      plan('bible-in-a-year', startsOn: '01-01', year: 2027),
    ];

    test('is the New Testament plan before 1 January, never the locked one',
        () {
      expect(onboardingDefaultPlan(plans, DateTime(2026, 11, 25)).id, 'nt-90');
    });

    test('stays the New Testament plan once the year plan opens', () {
      expect(onboardingDefaultPlan(plans, DateTime(2027, 1, 1)).id, 'nt-90');
    });

    test('falls back to the first open plan if the default is missing', () {
      final only = [plans.last, plans.first];
      expect(
          onboardingDefaultPlan(only, DateTime(2026, 11, 25)).id, 'psalms-30');
    });
  });
}
