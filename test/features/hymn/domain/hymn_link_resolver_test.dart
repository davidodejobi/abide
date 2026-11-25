import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/preferences/linking_preferences.dart';
import 'package:openbaptisthymnal/features/hymn/data/hymnal_repository.dart';
import 'package:openbaptisthymnal/features/hymn/domain/hymn_link_resolver.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_core.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_index.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';

class _FakeRepo implements HymnalRepository {
  @override
  Future<HymnalCore> getHymnalCore() => throw UnimplementedError();

  @override
  Future<HymnalIndex> getHymnalIndex() => throw UnimplementedError();

  @override
  Future<LanguagePack> getLanguagePack(String languageCode) =>
      throw UnimplementedError();

  @override
  Future<Map<String, String>> getPairTable(String languageCode) async =>
      languageCode == 'en' ? {'hymn_0003': 'hymn_0004'} : const {};
}

class _NoPrefs extends LinkingPreferencesNotifier {
  @override
  LinkingPreferences build() => const LinkingPreferences();
}

class _YoPrefs extends LinkingPreferencesNotifier {
  @override
  LinkingPreferences build() =>
      const LinkingPreferences(defaultHymnEditionId: 'yo');
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(overrides: [
      hymnalRepositoryProvider.overrideWithValue(_FakeRepo()),
      linkingPreferencesProvider.overrideWith(_NoPrefs.new),
    ]);
    addTearDown(container.dispose);
  });

  HymnLinkResolver resolver() => container.read(hymnLinkResolverProvider);

  test('unpinned link is English: opens the same en id, no switch', () async {
    final t = await resolver().resolve('hymn_0004');
    expect(t?.editionId, 'en');
    expect(t?.hymnId, 'hymn_0004');
    expect(t?.toastMessage, isNull);
  });

  test('a yo pin keeps the yo id in the yo pack', () async {
    final t = await resolver().resolve('hymn_0003', editionPin: 'yo');
    expect(t?.editionId, 'yo');
    expect(t?.hymnId, 'hymn_0003');
    expect(t?.toastMessage, isNull);
  });

  test('an en pin keeps the en id', () async {
    final t = await resolver().resolve('hymn_0004', editionPin: 'en');
    expect(t?.editionId, 'en');
    expect(t?.hymnId, 'hymn_0004');
  });

  test('unpinned en link maps to yo when the reader prefers yo', () async {
    final c = ProviderContainer(overrides: [
      hymnalRepositoryProvider.overrideWithValue(_FakeRepo()),
      linkingPreferencesProvider.overrideWith(_YoPrefs.new),
    ]);
    addTearDown(c.dispose);
    final t = await c.read(hymnLinkResolverProvider).resolve('hymn_0004');
    expect(t?.editionId, 'yo');
    expect(t?.hymnId, 'hymn_0003');
  });

  test('unpaired en hymn falls back to the source pack with a hint', () async {
    final c = ProviderContainer(overrides: [
      hymnalRepositoryProvider.overrideWithValue(_FakeRepo()),
      linkingPreferencesProvider.overrideWith(_YoPrefs.new),
    ]);
    addTearDown(c.dispose);
    final t = await c.read(hymnLinkResolverProvider).resolve('hymn_0001');
    expect(t?.editionId, 'en');
    expect(t?.hymnId, 'hymn_0001');
    expect(t?.toastMessage, contains('No Yoruba version'));
  });

  test('empty id resolves to nothing', () async {
    expect(await resolver().resolve(''), isNull);
  });
}
