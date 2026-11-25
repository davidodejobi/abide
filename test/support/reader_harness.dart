import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/bible/providers/verse_backlinks_provider.dart';
import 'package:openbaptisthymnal/features/bible/providers/verse_highlights_provider.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';
import 'package:openbaptisthymnal/features/daily/domain/streak.dart';
import 'package:openbaptisthymnal/features/daily/providers/daily_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';

const _verse =
    'I am the true vine, and my Father is the husbandman. Every branch in me '
    'that beareth not fruit he taketh away: and every branch that beareth '
    'fruit, he purgeth it, that it may bring forth more fruit.';

BibleManifest johnManifest() => const BibleManifest(
      edition: 'en-kjv',
      language: 'en',
      name: 'King James Version',
      books: [
        BibleBookInfo(
            ordinal: 43,
            code: 'JHN',
            name: 'John',
            chapterVerseCounts: [51, 25, 36, 54, 47, 71, 53, 59, 41, 42, 57, 50, 38, 31, 27, 33, 26, 40, 42, 31, 25]),
        BibleBookInfo(
            ordinal: 44, code: 'ACT', name: 'Acts', chapterVerseCounts: [26, 47]),
      ],
    );

ReadingPlan ntPlan() => ReadingPlan(
      id: 'nt-90',
      title: 'The New Testament in 90 Days',
      description: '',
      days: [
        for (var i = 1; i <= 90; i++)
          PlanDay(
              dayIndex: i, passages: [VerseRange.tryParse('JHN.15.1-17.26')!]),
      ],
    );

/// Overrides so the reader runs with no assets or database streams.
Future<List<Override>> readerOverrides({List<Override> extra = const []}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    bibleManifestProvider.overrideWith((ref, id) async => johnManifest()),
    bibleChapterProvider.overrideWith((ref, q) async => bibleChapter(
          book: q.bookCode,
          chapter: q.chapter,
          verseTexts: [for (var i = 0; i < 12; i++) _verse],
        )),
    verseBacklinksProvider.overrideWith((ref, q) => Stream.value({})),
    verseHighlightsProvider.overrideWith((ref, q) => Stream.value({})),
    planByIdProvider.overrideWith((ref, id) async => ntPlan()),
    planBookNamesProvider.overrideWith((_) async => {'JHN': 'John'}),
    streakProvider.overrideWithValue(const StreakResult(
        current: 11,
        completedToday: false,
        graceDaysUsed: 0,
        longest: 23,
        totalDays: 40)),
    isTodayCompleteProvider.overrideWithValue(false),
    ...extra,
  ];
}

Widget appFor(List<Override> overrides, Widget home,
    {ThemeData? theme, double scale = 1}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: home,
    ),
  );
}

void setView(WidgetTester t, Size logical, {double dpr = 2}) {
  t.view.physicalSize = logical * dpr;
  t.view.devicePixelRatio = dpr;
  addTearDown(t.view.reset);
}

/// A few frames, never `pumpAndSettle` (the page holds looping animations).
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 4; i++) {
    await t.pump(const Duration(milliseconds: 120));
  }
}
