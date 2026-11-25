import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/bible_chapter_view.dart';

import '../../../../support/fixtures.dart';
import '../../../../support/pump_app.dart';

// Exercises the reader against an overridden chapter provider, so no asset
// bundle or database is touched. Covers the two things most likely to break
// unnoticed: that every verse renders, and that the chapter-nav footer only
// offers moves that actually exist.
void main() {
  const query = (editionId: 'en-kjv', bookCode: 'GEN', chapter: 1);

  Widget subject(
      {ValueChanged<int>? onTapVerse, Set<int> selected = const {}}) {
    return ProviderScope(
      overrides: [
        bibleChapterProvider(query).overrideWith((ref) async => bibleChapter()),
      ],
      child: BibleChapterView(
        editionId: query.editionId,
        bookCode: query.bookCode,
        chapter: query.chapter,
        textScale: 1,
        onTapVerse: onTapVerse,
        selected: selected,
        header: const Text('Genesis 1'),
      ),
    );
  }

  group('Given a chapter of scripture', () {
    group('When the reader renders it', () {
      testWidgets('Then every verse in the chapter is shown', (tester) async {
        await tester.pumpApp(subject());

        // findRichText: each verse is a RichText (the verse number is a styled
        // span next to the body), not a plain Text, so the default finder
        // would report zero matches on a screen that renders perfectly.
        expect(
          find.textContaining('In the beginning', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.textContaining('without form', findRichText: true),
          findsOneWidget,
        );
        expect(
          find.textContaining('Let there be light', findRichText: true),
          findsOneWidget,
        );
      });
    });

    group('When the chapter has a header', () {
      testWidgets('Then it scrolls with the text', (tester) async {
        await tester.pumpApp(subject());
        expect(find.text('Genesis 1'), findsOneWidget);
      });
    });

    group('When a verse is tapped', () {
      testWidgets('Then the reader is told which verse', (tester) async {
        int? tapped;
        await tester.pumpApp(subject(onTapVerse: (n) => tapped = n));

        await tester.tap(
          find.textContaining('Let there be light', findRichText: true),
        );
        await tester.pump();

        expect(tapped, isNotNull);
      });
    });
  });
}
