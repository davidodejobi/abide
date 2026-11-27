import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/features/hymn/providers/enabled_hymn_languages_provider.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(Map<String, Object> prefs,
    {String language = 'en'}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(p),
    languageProvider.overrideWith((ref) => language),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('defaults to English only', () async {
    final c = await _container({});
    expect(c.read(enabledHymnLanguagesProvider), ['en']);
  });

  test('Yorùbá on when the reading language is Yorùbá', () async {
    final c = await _container({}, language: 'yo');
    expect(c.read(enabledHymnLanguagesProvider), ['en', 'yo']);
  });

  test('Yorùbá on when there is a Yorùbá favourite', () async {
    final c = await _container({
      'favorites_hymn_ids': '["yo:hymn_0005"]',
    });
    expect(c.read(enabledHymnLanguagesProvider), ['en', 'yo']);
  });

  test('never zero: the last language cannot be turned off', () async {
    final c = await _container({});
    await c.read(enabledHymnLanguagesProvider.notifier).setEnabled('en', false);
    expect(c.read(enabledHymnLanguagesProvider), ['en']);
  });

  test('The language Songs is showing cannot go off; others can; persisted',
      () async {
    final c = await _container({});
    final n = c.read(enabledHymnLanguagesProvider.notifier);
    await n.setEnabled('yo', true);
    await n.setEnabled('en', false); // showing English: refused
    expect(c.read(enabledHymnLanguagesProvider), ['en', 'yo']);
    c.read(languageProvider.notifier).state = 'yo';
    await n.setEnabled('en', false);
    expect(c.read(enabledHymnLanguagesProvider), ['yo']);
    final prefs = c.read(sharedPreferencesProvider);
    expect(prefs.getStringList('hymn_languages_enabled'), ['yo']);
  });

  test('The first-run default is saved, so a relaunch keeps it', () async {
    final c = await _container({}, language: 'yo');
    expect(c.read(enabledHymnLanguagesProvider), ['en', 'yo']);
    final prefs = c.read(sharedPreferencesProvider);
    expect(prefs.getStringList('hymn_languages_enabled'), ['en', 'yo']);
  });

  test('Opening a hymn in a language that is off turns it on', () async {
    final c = await _container({});
    expect(c.read(enabledHymnLanguagesProvider), ['en']);
    c.read(languageProvider.notifier).state = 'yo';
    await Future<void>.delayed(Duration.zero);
    expect(c.read(enabledHymnLanguagesProvider), ['en', 'yo']);
  });
}
