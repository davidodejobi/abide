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

  test('paired hymn opens the English id, not the same-numbered song',
      () async {
    final t = await resolver().resolve('hymn_0003');
    expect(t?.editionId, 'en');
    expect(t?.hymnId, 'hymn_0004');
    expect(t?.toastMessage, isNull);
  });

  test('unpaired hymn falls back to the canonical yo pack with a hint',
      () async {
    final t = await resolver().resolve('hymn_0001');
    expect(t?.editionId, 'yo');
    expect(t?.hymnId, 'hymn_0001');
    expect(t?.toastMessage, contains('No English version'));
  });

  test('a yo pin keeps the canonical id', () async {
    final t = await resolver().resolve('hymn_0001', editionPin: 'yo');
    expect(t?.editionId, 'yo');
    expect(t?.hymnId, 'hymn_0001');
    expect(t?.toastMessage, isNull);
  });

  test('an en pin on a paired hymn maps the id', () async {
    final t = await resolver().resolve('hymn_0003', editionPin: 'en');
    expect(t?.editionId, 'en');
    expect(t?.hymnId, 'hymn_0004');
  });

  test('empty id resolves to nothing', () async {
    expect(await resolver().resolve(''), isNull);
  });
}
