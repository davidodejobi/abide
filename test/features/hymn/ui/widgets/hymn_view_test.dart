import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';
import 'package:openbaptisthymnal/features/hymn/model/lyrics.dart';
import 'package:openbaptisthymnal/features/hymn/model/stanza.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/hymn_view.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/stanza_card.dart';

HymnTranslation _hymn({
  required String title,
  int number = 1,
  List<String> stanzas = const ['line one'],
  String? chorus,
}) =>
    HymnTranslation(
      title: title,
      number: number,
      lyrics: Lyrics(
        stanzas: [
          for (var i = 0; i < stanzas.length; i++)
            Stanza(index: i + 1, text: stanzas[i]),
        ],
        chorus: chorus,
      ),
    );

void main() {
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: child));

  testWidgets('renders the title and every stanza', (tester) async {
    await tester.pumpWidget(host(HymnView(
      translation: _hymn(
        title: 'Amazing Grace',
        stanzas: ['amazing grace', 'how sweet the sound'],
      ),
      textScale: 1,
      onShare: (_) {},
    )));

    expect(find.text('Amazing Grace'), findsOneWidget);
    expect(find.byType(StanzaCard), findsNWidgets(2));
  });

  testWidgets('renders the chorus card when present', (tester) async {
    await tester.pumpWidget(host(HymnView(
      translation: _hymn(
        title: 'With Chorus',
        stanzas: ['v1', 'v2'],
        chorus: 'sing along',
      ),
      textScale: 1,
      onShare: (_) {},
    )));

    // 2 stanzas + 1 chorus = 3 cards.
    expect(find.byType(StanzaCard), findsNWidgets(3));
  });

  testWidgets('skips the chorus card when chorus is null', (tester) async {
    await tester.pumpWidget(host(HymnView(
      translation: _hymn(
        title: 'No Chorus',
        stanzas: ['v1', 'v2', 'v3'],
      ),
      textScale: 1,
      onShare: (_) {},
    )));

    expect(find.byType(StanzaCard), findsNWidgets(3));
  });

  testWidgets('shows the uppercase language label when provided',
      (tester) async {
    await tester.pumpWidget(host(HymnView(
      translation: _hymn(title: 'T'),
      textScale: 1,
      onShare: (_) {},
      languageLabel: 'yo',
    )));

    expect(find.text('YO'), findsOneWidget);
  });

  testWidgets('omits the language label when none is provided', (tester) async {
    await tester.pumpWidget(host(HymnView(
      translation: _hymn(title: 'T'),
      textScale: 1,
      onShare: (_) {},
    )));

    // No label means the only "Y…" text is whatever stanza/title content has.
    expect(find.text('YO'), findsNothing);
    expect(find.text('EN'), findsNothing);
  });

  testWidgets('mounts the trailing header above the title', (tester) async {
    await tester.pumpWidget(host(HymnView(
      translation: _hymn(title: 'After'),
      textScale: 1,
      onShare: (_) {},
      trailingHeader: const Text('header'),
    )));

    expect(find.text('header'), findsOneWidget);
  });
}
