import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/features/share_card/ui/share_card_composer.dart';
import 'package:openbaptisthymnal/features/share_card/ui/widgets/scripture_card.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';

import '../../support/reader_harness.dart' show setView, settle;

void main() {
  const verses = [
    (number: 5, text: 'I am the vine, ye are the branches.'),
    (number: 6, text: 'If a man abide not in me, he is cast forth.'),
  ];

  testWidgets('composer previews the card and switches look and shape',
      (t) async {
    setView(t, const Size(390, 844));
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: ShareCardComposer(
        title: NotesStrings.shareVerse,
        filename: 'x',
        cardBuilder: (style, format) => ScriptureCard(
            reference: 'John 15:5-6',
            verses: verses,
            style: style,
            format: format),
      ),
    ));
    await settle(t);
    expect(find.text(NotesStrings.shareVerse), findsOneWidget);
    expect(find.text('JOHN 15:5-6'), findsOneWidget);
    expect(find.text(NotesStrings.shareImage), findsOneWidget);

    await t.tap(find.text(NotesStrings.plain));
    await settle(t);
    await t.tap(find.text(NotesStrings.formatSquare));
    await settle(t);
    expect(find.text('JOHN 15:5-6'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
