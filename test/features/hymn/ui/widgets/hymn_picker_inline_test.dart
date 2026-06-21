import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/features/hymn/data/hymnal_repository.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_core.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_index.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';
import 'package:openbaptisthymnal/features/hymn/model/lyrics.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/hymn_list_tile.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/hymn_picker_inline.dart';

class _FakeHymnalRepository implements HymnalRepository {
  _FakeHymnalRepository(this.packs);
  final Map<String, LanguagePack> packs;

  @override
  Future<HymnalCore> getHymnalCore() => throw UnimplementedError();

  @override
  Future<HymnalIndex> getHymnalIndex() => throw UnimplementedError();

  @override
  Future<LanguagePack> getLanguagePack(String code) async => packs[code]!;
}

HymnTranslation _t(String title, int number) => HymnTranslation(
      title: title,
      number: number,
      lyrics: const Lyrics(stanzas: []),
    );

LanguagePack _pack(String lang, Map<String, HymnTranslation> hymns) =>
    LanguagePack(language: lang, hymnalName: 'Test', hymns: hymns);

void main() {
  Widget host({
    required HymnalRepository repo,
    required String language,
    required void Function(String hymnId, String lang) onSelected,
    ValueChanged<String>? onLanguageChanged,
  }) =>
      ProviderScope(
        overrides: [hymnalRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Scaffold(
            body: HymnPickerInline(
              language: language,
              onSelected: onSelected,
              onLanguageChanged: onLanguageChanged,
            ),
          ),
        ),
      );

  testWidgets('renders all hymns sorted by number once loaded', (tester) async {
    final repo = _FakeHymnalRepository({
      'en': _pack('en', {
        'hymn_0002': _t('Second', 2),
        'hymn_0001': _t('First', 1),
        'hymn_0003': _t('Third', 3),
      }),
    });
    await tester.pumpWidget(host(
      repo: repo,
      language: 'en',
      onSelected: (_, __) {},
    ));
    await tester.pumpAndSettle();

    final tiles = find.byType(HymnListTile);
    expect(tiles, findsNWidgets(3));
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('Third'), findsOneWidget);
  });

  testWidgets('search query filters the list by title', (tester) async {
    final repo = _FakeHymnalRepository({
      'en': _pack('en', {
        'hymn_0001': _t('Amazing Grace', 1),
        'hymn_0002': _t('How Great Thou Art', 2),
      }),
    });
    await tester.pumpWidget(host(
      repo: repo,
      language: 'en',
      onSelected: (_, __) {},
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'grace');
    await tester.pumpAndSettle();

    expect(find.text('Amazing Grace'), findsOneWidget);
    expect(find.text('How Great Thou Art'), findsNothing);
  });

  testWidgets('search query filters the list by zero-padded number',
      (tester) async {
    final repo = _FakeHymnalRepository({
      'en': _pack('en', {
        'hymn_0007': _t('Seven', 7),
        'hymn_0123': _t('One Two Three', 123),
      }),
    });
    await tester.pumpWidget(host(
      repo: repo,
      language: 'en',
      onSelected: (_, __) {},
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '007');
    await tester.pumpAndSettle();

    expect(find.text('Seven'), findsOneWidget);
    expect(find.text('One Two Three'), findsNothing);
  });

  testWidgets('tapping a tile fires onSelected with the hymn id and language',
      (tester) async {
    final repo = _FakeHymnalRepository({
      'yo': _pack('yo', {
        'hymn_0042': _t('Forty-two', 42),
      }),
    });

    String? receivedId;
    String? receivedLang;

    await tester.pumpWidget(host(
      repo: repo,
      language: 'yo',
      onSelected: (id, lang) {
        receivedId = id;
        receivedLang = lang;
      },
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(HymnListTile));
    await tester.pump();

    expect(receivedId, 'hymn_0042');
    expect(receivedLang, 'yo');
  });

  testWidgets('language switch fires onLanguageChanged with the new language',
      (tester) async {
    final repo = _FakeHymnalRepository({
      'en': _pack('en', {'hymn_0001': _t('English', 1)}),
      'yo': _pack('yo', {'hymn_0001': _t('Yoruba', 1)}),
    });

    String? newLang;
    await tester.pumpWidget(host(
      repo: repo,
      language: 'en',
      onSelected: (_, __) {},
      onLanguageChanged: (l) => newLang = l,
    ));
    await tester.pumpAndSettle();

    // The "YO" segment in the language switch.
    await tester.tap(find.text('YO'));
    await tester.pump();

    expect(newLang, 'yo');
  });

  testWidgets('empty state shows "No matches." when search excludes all',
      (tester) async {
    final repo = _FakeHymnalRepository({
      'en': _pack('en', {'hymn_0001': _t('Only One', 1)}),
    });
    await tester.pumpWidget(host(
      repo: repo,
      language: 'en',
      onSelected: (_, __) {},
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();

    expect(find.text('No matches.'), findsOneWidget);
  });
}
