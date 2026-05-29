import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/hymn_stanza.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/stanza_card.dart';

// The lyric base size is 16 (AppTextStyles.bodyLarge); the reader's font-size
// preference multiplies it. These verify the literal requirement — lyric text
// resizes — on the actual lyric widgets.
void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('StanzaCard scales its lyric text by textScale', (tester) async {
    await tester.pumpWidget(host(
      const StanzaCard(text: 'grace', displayIndex: 1, textScale: 1.5),
    ));

    final style = tester.widget<Text>(find.text('grace')).style;
    expect(style?.fontSize, 16 * 1.5);
  });

  testWidgets('StanzaCard defaults to the base size', (tester) async {
    await tester.pumpWidget(host(
      const StanzaCard(text: 'grace', displayIndex: 1),
    ));

    expect(tester.widget<Text>(find.text('grace')).style?.fontSize, 16);
  });

  testWidgets('HymnStanza scales its lyric text by textScale', (tester) async {
    await tester.pumpWidget(host(
      const HymnStanza(number: 1, text: 'grace', textScale: 1.5),
    ));

    expect(tester.widget<Text>(find.text('grace')).style?.fontSize, 16 * 1.5);
  });
}
