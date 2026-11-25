import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/database_provider.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_reader_page.dart';
import 'package:openbaptisthymnal/features/daily/providers/daily_providers.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_strings.dart';
import 'package:openbaptisthymnal/features/bible/ui/bible_tab_screen.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/bible_chapter_view.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/edition_sheet.dart';
import 'package:openbaptisthymnal/features/bible/ui/widgets/mark_read_dock.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';

import '../../../support/pump_app.dart';
import '../../../support/reader_harness.dart';

void main() {
  // The verse is long, so its centre can be off screen: press near its start.
  Future<void> longPressFirstVerse(WidgetTester t) => t.longPressAt(
      t.getTopLeft(find.textContaining('true vine', findRichText: true).first) +
          const Offset(24, 12));

  Future<ProviderContainer> pumpReader(
    WidgetTester t,
    Widget page, {
    Size size = const Size(390, 844),
    double scale = 1,
    ThemeData? theme,
    List<Override> extra = const [],
    int chapter = 15,
  }) async {
    setView(t, size);
    await t.pumpWidget(appFor(await readerOverrides(extra: extra), page,
        scale: scale, theme: theme));
    await settle(t);
    final container =
        ProviderScope.containerOf(t.element(find.byType(BibleTabScreen)));
    container
        .read(bibleReadingPositionProvider.notifier)
        .openChapter('JHN', chapter);
    await settle(t);
    return container;
  }

  testWidgets(
      'Given the Bible tab, Then it shows the title, text and chapter nav',
      (t) async {
    await pumpReader(
        t, const Scaffold(body: SafeArea(child: BibleTabScreen())));
    expect(find.text('John 15'), findsWidgets);
    expect(find.text('KJV'), findsWidgets);
    expect(find.textContaining('true vine', findRichText: true), findsWidgets);
    expect(find.text(BibleStrings.markRead), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('Given a plan day, Then the reader shows the day and Mark read',
      (t) async {
    await pumpReader(t, const BibleReaderPage(planId: 'nt-90', dayIndex: 41));
    expect(find.text('DAY 41 · JOHN 15–17'), findsOneWidget);
    expect(find.text('CHAPTER 1 OF 3'), findsOneWidget);
    expect(find.text(BibleStrings.markRead), findsOneWidget);
    expect(find.text(BibleStrings.litDay(12)), findsOneWidget);
  });

  testWidgets(
      'Given Mark read is tapped, Then the plan day is saved and the route pops true',
      (t) async {
    final db = testDb();
    addTearDown(db.close);
    await t.runAsync(() => db.readingPlansDao
        .startPlan(planId: 'nt-90', startDateKey: '2026-01-01'));
    bool? result;
    setView(t, const Size(390, 844));
    await t.pumpWidget(appFor(
      await readerOverrides(extra: [appDatabaseProvider.overrideWithValue(db)]),
      Builder(
        builder: (context) => TextButton(
          onPressed: () async =>
              result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
                builder: (_) =>
                    const BibleReaderPage(planId: 'nt-90', dayIndex: 41)),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await settle(t);
    await t.tap(find.text(BibleStrings.markRead));
    await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await settle(t);
    expect(result, isTrue);
    final done = (await t.runAsync(
        () => db.readingPlansDao.watchCompletedDayIndexes('nt-90').first))!;
    expect(done, contains(41));
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 100));
  });

  testWidgets(
      'Given a long press on a verse, Then the glass verse actions replace the chapter nav',
      (t) async {
    await pumpReader(
        t, const Scaffold(body: SafeArea(child: BibleTabScreen())));
    await longPressFirstVerse(t);
    await settle(t);
    expect(find.bySemanticsLabel(BibleStrings.addNote), findsOneWidget);
    expect(find.bySemanticsLabel(BibleStrings.share), findsOneWidget);
    expect(find.bySemanticsLabel(BibleStrings.clearSelection), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  for (final (name, size, scale) in [
    ('390x844', const Size(390, 844), 1.0),
    ('320 wide at 2x text', const Size(320, 700), 2.0),
  ]) {
    testWidgets(
        'Given a plan day at $name, Then the last verse clears the Mark read dock',
        (t) async {
      await pumpReader(t, const BibleReaderPage(planId: 'nt-90', dayIndex: 41),
          size: size, scale: scale);
      final scroll = t.state<ScrollableState>(find
          .descendant(
              of: find.byType(BibleChapterView).first,
              matching: find.byType(Scrollable))
          .first);
      // Extents are estimated until built: jump until the end is real.
      for (var i = 0; i < 6; i++) {
        scroll.position.jumpTo(scroll.position.maxScrollExtent);
        await t.pump();
      }
      await settle(t);
      final verses = find.textContaining('true vine', findRichText: true);
      var lastBottom = 0.0;
      for (var i = 0; i < verses.evaluate().length; i++) {
        final r = t.getRect(verses.at(i));
        if (r.left >= 0 && r.left < size.width && r.bottom > lastBottom) {
          lastBottom = r.bottom;
        }
      }
      expect(lastBottom,
          lessThanOrEqualTo(t.getRect(find.byType(MarkReadDock)).top));
    });
  }

  testWidgets('Given Mark read is double tapped, Then it saves once',
      (t) async {
    var saves = 0;
    final gate = Completer<void>();
    await pumpReader(t, const BibleReaderPage(planId: 'nt-90', dayIndex: 41),
        extra: [
          markPlanDayReadProvider.overrideWithValue((_, __) {
            saves++;
            return gate.future;
          }),
        ]);
    await t.tap(find.text(BibleStrings.markRead));
    await t.pump();
    await t.tap(find.text(BibleStrings.markRead));
    await t.pump();
    expect(saves, 1);
    gate.complete();
    await settle(t);
  });

  testWidgets(
      'Given the save fails, Then a snackbar shows and the reader stays',
      (t) async {
    await pumpReader(
        t, const Scaffold(body: BibleTabScreen(planId: 'nt-90', dayIndex: 41)),
        extra: [
          markPlanDayReadProvider
              .overrideWithValue((_, __) => Future.error('disk full')),
        ]);
    await t.tap(find.text(BibleStrings.markRead));
    await settle(t);
    expect(find.text(BibleStrings.markReadFailed), findsOneWidget);
  });

  testWidgets(
      'Given a plan day, Then the dock offers previous and next chapter',
      (t) async {
    final c = await pumpReader(
        t, const BibleReaderPage(planId: 'nt-90', dayIndex: 41));
    // First chapter of the day: no previous, next goes to chapter 16.
    expect(find.bySemanticsLabel(BibleStrings.previous), findsOneWidget);
    await t.tap(find.bySemanticsLabel(BibleStrings.next));
    await settle(t);
    expect(c.read(bibleReadingPositionProvider).chapter, 16);
    expect(find.text('CHAPTER 2 OF 3'), findsOneWidget);
  });

  group('layout robustness', () {
    Future<void> run(WidgetTester t, Size size, double scale,
        {bool plan = false,
        bool select = false,
        bool dark = false,
        bool split = false}) async {
      await pumpReader(
        t,
        plan
            ? const BibleReaderPage(planId: 'nt-90', dayIndex: 41)
            : const Scaffold(body: SafeArea(child: BibleTabScreen())),
        size: size,
        scale: scale,
        theme: dark ? AppTheme.darkTheme : null,
      );
      if (select) {
        await longPressFirstVerse(t);
        await settle(t);
      }
      if (split) {
        await t.tap(find.bySemanticsLabel(BibleStrings.splitView));
        await settle(t);
      }
      expect(t.takeException(), isNull);
    }

    for (final (name, size, scale) in [
      ('390x844', const Size(390, 844), 1.0),
      ('320 wide at 2x text', const Size(320, 700), 2.0),
      ('landscape 844x390', const Size(844, 390), 1.0),
    ]) {
      testWidgets('reader, $name', (t) => run(t, size, scale));
      testWidgets(
          'reader selection, $name', (t) => run(t, size, scale, select: true));
      testWidgets('reader dark, $name', (t) => run(t, size, scale, dark: true));
      testWidgets('plan day, $name', (t) => run(t, size, scale, plan: true));
      testWidgets('split, $name', (t) => run(t, size, scale, split: true));
    }
  });

  group('edition sheet', () {
    Future<void> sheet(WidgetTester t, Size size, double scale) async {
      setView(t, size);
      await t.pumpWidget(appFor(
        [],
        const Scaffold(
          body: EditionSheet(editions: kBibleEditions, currentId: 'en-kjv'),
        ),
        scale: scale,
      ));
      await settle(t);
      expect(find.text(BibleStrings.inUse), findsOneWidget);
      // Every shipped edition is listed; nothing is "coming soon".
      for (final e in kBibleEditions) {
        expect(find.text(e.displayName), findsOneWidget);
      }
      expect(t.takeException(), isNull);
    }

    testWidgets('390x844', (t) => sheet(t, const Size(390, 844), 1));
    testWidgets(
        '320 wide at 2x text', (t) => sheet(t, const Size(320, 700), 2));
    testWidgets('landscape 844x390', (t) => sheet(t, const Size(844, 390), 1));
  });
}
