import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/features/share_card/ui/scripture_share_card_page.dart';
import 'package:openbaptisthymnal/features/share_card/ui/share_card_page.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';

import '../../support/reader_harness.dart' show setView, settle;

void main() {
  const verses = [
    (number: 5, text: 'I am the vine, ye are the branches.'),
    (number: 6, text: 'If a man abide not in me, he is cast forth.'),
  ];

  Future<void> pump(WidgetTester t, Widget page) async {
    setView(t, const Size(390, 844));
    await t.pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: page));
    await settle(t);
  }

  testWidgets('composer previews the card and switches look and shape',
      (t) async {
    await pump(t,
        const ScriptureShareCardPage(reference: 'John 15:5-6', verses: verses));
    expect(find.text(NotesStrings.shareVerse), findsOneWidget);
    expect(find.text('JOHN 15:5-6'), findsOneWidget);
    expect(find.text(NotesStrings.shareImage), findsOneWidget);
    expect(find.text(NotesStrings.saveImage), findsOneWidget);

    await t.ensureVisible(find.text(NotesStrings.plain));
    await t.tap(find.text(NotesStrings.plain));
    await settle(t);
    await t.ensureVisible(find.text(NotesStrings.formatSquare));
    await t.tap(find.text(NotesStrings.formatSquare));
    await settle(t);
    expect(find.text('JOHN 15:5-6'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('reference toggle hides the line; copy text honours it',
      (t) async {
    String? copied;
    t.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() => t.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await pump(t,
        const ScriptureShareCardPage(reference: 'John 15:5-6', verses: verses));

    await t.ensureVisible(find.text(NotesStrings.showReference));
    await t.tap(find.text(NotesStrings.showReference));
    await settle(t);
    expect(find.text('JOHN 15:5-6'), findsNothing);

    await t.tap(find.text(NotesStrings.copyText));
    await settle(t);
    expect(copied, isNotNull);
    expect(copied, contains('5 I am the vine'));
    expect(copied, isNot(contains('John 15:5-6')));
    expect(copied, endsWith(NotesStrings.appMark));
    await t.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('hymn composer preselects the opened stanza and toggles parts',
      (t) async {
    await pump(
      t,
      const ShareCardPage(
        hymnNumber: '001',
        title: 'Amazing Grace',
        body: 'Stanza two words',
        parts: [
          (label: 'Verse 1', text: 'Stanza one words'),
          (label: 'Verse 2', text: 'Stanza two words'),
          (label: 'Chorus', text: 'Chorus words'),
        ],
      ),
    );
    expect(find.textContaining('Stanza two words'), findsOneWidget);
    expect(find.textContaining('Stanza one words'), findsNothing);

    await t.ensureVisible(find.text('Chorus'));
    await t.tap(find.text('Chorus'));
    await settle(t);
    expect(find.textContaining('Chorus words'), findsOneWidget);

    // The last remaining part cannot be switched off.
    await t.tap(find.text('Verse 2'));
    await settle(t);
    await t.tap(find.text('Chorus'));
    await settle(t);
    expect(find.textContaining('Chorus words'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
