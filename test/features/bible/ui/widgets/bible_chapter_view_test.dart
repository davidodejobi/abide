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

  Widget subject({
    VoidCallback? onPrev,
    VoidCallback? onNext,
    bool hasPrev = false,
    bool hasNext = false,
  }) {
    return ProviderScope(
      overrides: [
        bibleChapterProvider(query).overrideWith((ref) async => bibleChapter()),
      ],
      child: BibleChapterView(
        editionId: query.editionId,
        bookCode: query.bookCode,
        chapter: query.chapter,
        textScale: 1,
        bookName: 'Genesis',
        onPrev: onPrev,
        onNext: onNext,
        hasPrev: hasPrev,
        hasNext: hasNext,
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

    group('When it is the first chapter of the Bible', () {
      testWidgets('Then Previous is present but not tappable', (tester) async {
        var prevTaps = 0;
        await tester.pumpApp(subject(
          onPrev: () => prevTaps++,
          onNext: () {},
          hasNext: true,
          // hasPrev is false: Genesis 1 has nothing before it.
        ));

        await tester.tap(find.text('Previous'), warnIfMissed: false);
        await tester.pump();

        expect(prevTaps, 0, reason: 'Previous must be inert on Genesis 1');
      });
    });

    group('When a next chapter exists', () {
      testWidgets('Then tapping Next advances the reader', (tester) async {
        var nextTaps = 0;
        await tester.pumpApp(subject(
          onNext: () => nextTaps++,
          hasNext: true,
        ));

        await tester.tap(find.text('Next'));
        await tester.pump();

        expect(nextTaps, 1);
      });
    });
  });
}
