import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _yo = BibleEdition(
  id: 'yo-bmy',
  languageCode: 'yo',
  versionCode: 'bmy',
  displayName: 'Yorùbá',
  attribution: 'Public Domain',
);

Future<ProviderContainer> _container(
    {String? saved, List<BibleEdition> installed = const []}) async {
  SharedPreferences.setMockInitialValues({
    if (saved != null)
      'bible_reading_position': json
          .encode({'edition': saved, 'bookCode': 'JHN', 'chapter': 3}),
  });
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    initialInstalledBiblesProvider.overrideWithValue(installed),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('a saved edition that is not on the phone falls back to KJV', () async {
    final c = await _container(saved: 'yo-bmy');
    final pos = c.read(bibleReadingPositionProvider);
    expect(pos.editionId, 'en-kjv');
    expect(pos.bookCode, 'JHN');
    expect(pos.chapter, 3); // place is kept
    expect(c.read(missingSavedEditionProvider), 'yo-bmy');
  });

  test('a downloaded saved edition is used, no prompt', () async {
    final c = await _container(saved: 'yo-bmy', installed: [_yo]);
    expect(c.read(bibleReadingPositionProvider).editionId, 'yo-bmy');
    expect(c.read(missingSavedEditionProvider), isNull);
  });

  test('removing the edition in use falls back; re-adding restores it',
      () async {
    final c = await _container(saved: 'yo-bmy', installed: [_yo]);
    expect(c.read(bibleReadingPositionProvider).editionId, 'yo-bmy');

    c.read(installedBiblesProvider.notifier).remove('yo-bmy');
    expect(c.read(bibleReadingPositionProvider).editionId, 'en-kjv');
    expect(c.read(missingSavedEditionProvider), 'yo-bmy');

    c.read(installedBiblesProvider.notifier).add(_yo);
    expect(c.read(bibleReadingPositionProvider).editionId, 'yo-bmy');
  });

  test('picking another edition clears the prompt', () async {
    final c = await _container(saved: 'yo-bmy');
    c.read(bibleReadingPositionProvider.notifier).setEdition('en-bsb');
    expect(c.read(missingSavedEditionProvider), isNull);
    expect(c.read(bibleReadingPositionProvider).editionId, 'en-bsb');
  });

  test('editions are bundled first, then downloaded', () async {
    final c = await _container(installed: [_yo]);
    expect(c.read(bibleEditionsProvider).map((e) => e.id),
        ['en-kjv', 'en-bsb', 'en-asv', 'yo-bmy']);
    expect(c.read(bibleRepositoryProvider).editionById('yo-bmy'), isNotNull);
  });
}
