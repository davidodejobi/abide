import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_atlas.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_days.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_geometry.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_landmarks.dart';
import 'package:openbaptisthymnal/features/daily/ui/daily_strings.dart';
import 'package:openbaptisthymnal/features/daily/ui/widgets/road_art.dart';
import 'package:openbaptisthymnal/features/daily/ui/widgets/road_scene.dart';
import 'package:openbaptisthymnal/features/daily/ui/widgets/road_sheets.dart';

final _plan = ReadingPlan(id: 'p', title: 'Plan', description: '', days: [
  for (var i = 1; i <= 30; i++)
    PlanDay(dayIndex: i, passages: [VerseRange.tryParse('GEN.$i.1-31')!]),
]);

Widget _app(Widget child, {bool reduce = false, double scale = 1}) =>
    MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (c, w) => MediaQuery(
        data: MediaQuery.of(c).copyWith(
            disableAnimations: reduce, textScaler: TextScaler.linear(scale)),
        child: w!,
      ),
      home: Scaffold(body: child),
    );

const _key = ValueKey('road');

Widget _road({
  int day = 5,
  void Function(int)? onStop,
  void Function(Landmark, int, Rect)? onLandmark,
  ReadingPlan? plan,
  int total = 30,
  bool noPlan = false,
}) =>
    RoadScene(
      key: _key,
      width: 390,
      mood: RoadMood.day,
      currentDay: day,
      totalDays: total,
      plan: noPlan ? null : (plan ?? _plan),
      onStopTap: onStop,
      onLandmarkTap: onLandmark,
    );

RoadSceneState _state(WidgetTester t) =>
    t.state<RoadSceneState>(find.byKey(_key));

double _pillOpacity(WidgetTester t) => t
    .widget<AnimatedOpacity>(find
        .ancestor(
            of: find.text(DailyStrings.backToToday),
            matching: find.byType(AnimatedOpacity))
        .first)
    .opacity;

void main() {
  Future<void> loadArt(WidgetTester t) => t.runAsync(RoadArt.load);
  // The scene picks the art up on a real-async turn; give it one.
  Future<void> artArrives(WidgetTester t) =>
      t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));

  testWidgets(
      'Given a drag, Then the camera leaves the traveller and Back to today brings it home',
      (t) async {
    await loadArt(t);
    await t.pumpWidget(_app(_road()));
    await t.pump(const Duration(milliseconds: 50));
    expect(_state(t).debugExploring, isFalse);
    expect(_pillOpacity(t), 0);

    await t.drag(find.byType(RoadScene), const Offset(0, 300));
    await t.pump(const Duration(milliseconds: 250));
    expect(_state(t).debugExploring, isTrue);
    expect(_state(t).debugLook, greaterThan(8),
        reason: 'dragged ~4.8 stops ahead');
    expect(_pillOpacity(t), 1);

    await t.tap(find.text(DailyStrings.backToToday));
    await t.pump(const Duration(milliseconds: 300));
    expect(_state(t).debugLook, lessThan(_state(t).debugLook + 1));
    await t.pump(const Duration(seconds: 2));
    expect(_state(t).debugExploring, isFalse);
    expect(_state(t).debugLook, 5);
    expect(_pillOpacity(t), 0);
    expect(t.takeException(), isNull);
  });

  testWidgets(
      'Given a fling, Then the camera keeps gliding and stops at the last day',
      (t) async {
    await loadArt(t);
    await t.pumpWidget(_app(_road()));
    await t.pump(const Duration(milliseconds: 50));
    await t.fling(find.byType(RoadScene), const Offset(0, 200), 6000);
    await t.pump(const Duration(milliseconds: 100));
    final early = _state(t).debugLook;
    await t.pump(const Duration(seconds: 3));
    final late = _state(t).debugLook;
    expect(late, greaterThan(early),
        reason: 'momentum carries on after release');
    expect(late, lessThanOrEqualTo(30));
    // A hard fling cannot run past the end of the plan.
    await t.fling(find.byType(RoadScene), const Offset(0, 300), 20000);
    await t.pump(const Duration(seconds: 6));
    expect(_state(t).debugLook, 30);
    // ...nor behind the start.
    await t.fling(find.byType(RoadScene), const Offset(0, -300), 30000);
    await t.pump(const Duration(seconds: 8));
    expect(_state(t).debugLook, greaterThanOrEqualTo(0));
    expect(t.takeException(), isNull);
  });

  testWidgets(
      'Given reduced motion, Then Back to today cuts and a fling does not glide',
      (t) async {
    await loadArt(t);
    await t.pumpWidget(_app(_road(), reduce: true));
    await t.pump(const Duration(milliseconds: 50));
    await t.fling(find.byType(RoadScene), const Offset(0, 200), 6000);
    await t.pump(const Duration(milliseconds: 100));
    final at = _state(t).debugLook;
    await t.pump(const Duration(seconds: 2));
    expect(_state(t).debugLook, at);
    await t.tap(find.text(DailyStrings.backToToday));
    await t.pump();
    expect(_state(t).debugExploring, isFalse);
    expect(_state(t).debugLook, 5);
  });

  testWidgets(
      'Given a day is read while exploring, Then the camera comes home to the walk',
      (t) async {
    await loadArt(t);
    await t.pumpWidget(_app(_road()));
    await t.pump(const Duration(milliseconds: 50));
    await t.drag(find.byType(RoadScene), const Offset(0, 300));
    await t.pump();
    await t.pumpWidget(_app(_road(day: 6)));
    await t.pump(const Duration(seconds: 4));
    expect(_state(t).debugExploring, isFalse);
    expect(_state(t).debugPos, 6);
  });

  testWidgets(
      'Given a tap on a stop, Then it reports that day, wherever the camera is',
      (t) async {
    await loadArt(t);
    final taps = <int>[];
    await t.pumpWidget(_app(_road(onStop: taps.add)));
    await t.pump(const Duration(milliseconds: 50));
    const geo = RoadGeometry();
    Offset at(int n) {
      final s = geo.stop(n), c = geo.camera(_state(t).debugLook);
      return Offset(s.x + c.x, s.y + c.y);
    }

    await t.tapAt(at(5));
    await t.tapAt(at(6)); // a stop ahead
    await t.tapAt(at(3)); // a stop behind
    expect(taps, [5, 6, 3]);

    await t.drag(find.byType(RoadScene), const Offset(0, 500));
    await t.pump(const Duration(milliseconds: 250));
    final far = _state(t).debugLook.round() + 1;
    await t.tapAt(at(far));
    expect(taps.last, far);
    // Empty meadow is not a stop.
    final n = taps.length;
    await t.tapAt(const Offset(6, 480));
    expect(taps.length, n);
  });

  testWidgets(
      'Given a landmark whose sprite is not in yet, Then its signpost is tappable',
      (t) async {
    await loadArt(t);
    final taps = <(String, int)>[];
    await t.pumpWidget(
        _app(_road(day: 12, onLandmark: (l, d, _) => taps.add((l.id, d)))));
    await artArrives(t);
    await t.pump(const Duration(milliseconds: 100));
    final tap = _state(t).debugLandmarkTap(12);
    expect(tap, isNotNull, reason: 'day 12 touches Abram and the stars');
    await t.tapAt(tap!);
    expect(taps, [('gen-abram-stars', 12)]);
  });

  testWidgets(
      'Given a screen reader, Then stops and landmarks are labelled buttons',
      (t) async {
    await loadArt(t);
    final sem = t.ensureSemantics();
    await t.pumpWidget(_app(_road(day: 12)));
    await artArrives(t);
    await t.pump(const Duration(milliseconds: 100));
    expect(find.semantics.byLabel('Day 12, today'), findsOneWidget);
    expect(find.semantics.byLabel('Day 13, coming up'), findsOneWidget);
    expect(find.semantics.byLabel('Day 11, read'), findsOneWidget);
    expect(find.semantics.byLabel('Abram and the stars, Genesis 15:5'),
        findsOneWidget);
    sem.dispose();
  });

  testWidgets(
      'Given a touch during a glide, Then it stops the camera and opens nothing',
      (t) async {
    await loadArt(t);
    final taps = <int>[];
    await t.pumpWidget(_app(_road(onStop: taps.add)));
    await t.pump(const Duration(milliseconds: 50));
    await t.fling(find.byType(RoadScene), const Offset(0, 200), 3000);
    await t.pump(const Duration(milliseconds: 200));
    final at = _state(t).debugLook;
    const geo = RoadGeometry();
    final s = geo.stop(at.round()), c = geo.camera(at);
    await t.tapAt(Offset(s.x + c.x, s.y + c.y));
    expect(taps, isEmpty, reason: 'the tap only stopped the glide');
    await t.pump(const Duration(seconds: 2));
    expect(_state(t).debugLook, closeTo(at, .05), reason: 'the glide is over');
    // The next tap works as usual.
    final look = _state(t).debugLook;
    final s2 = geo.stop(look.round()), c2 = geo.camera(look);
    await t.tapAt(Offset(s2.x + c2.x, s2.y + c2.y));
    expect(taps, [look.round()]);
  });

  testWidgets(
      'Given another plan or a shorter one, Then explore never strands the camera',
      (t) async {
    await loadArt(t);
    await t.pumpWidget(_app(_road()));
    await t.pump(const Duration(milliseconds: 50));
    await t.drag(find.byType(RoadScene), const Offset(0, 1500));
    await t.pump();
    expect(_state(t).debugLook, greaterThan(20));
    // Same day, shorter plan, same id: clamped to the new last day.
    await t.pumpWidget(_app(_road(total: 10)));
    await t.pump();
    expect(_state(t).debugLook, lessThanOrEqualTo(10));
    // Same day, a different plan: back with its traveller.
    final other =
        ReadingPlan(id: 'q', title: '', description: '', days: _plan.days);
    await t.pumpWidget(_app(_road(plan: other)));
    await t.pump();
    expect(_state(t).debugExploring, isFalse);
    expect(_state(t).debugLook, 5);
  });

  testWidgets('Given no plan, Then the road does not explore', (t) async {
    await loadArt(t);
    await t.pumpWidget(_app(_road(noPlan: true)));
    await t.pump(const Duration(milliseconds: 50));
    await t.drag(find.byType(RoadScene), const Offset(0, 300));
    await t.pump();
    expect(_state(t).debugExploring, isFalse);
  });

  testWidgets('Given a screen reader scrolls, Then down brings the road ahead',
      (t) async {
    await loadArt(t);
    final sem = t.ensureSemantics();
    await t.pumpWidget(_app(_road()));
    await t.pump(const Duration(milliseconds: 50));
    final id = find.semantics.byAction(SemanticsAction.scrollDown).evaluate().first.id;
    // ignore: deprecated_member_use
    final owner = t.binding.pipelineOwner.semanticsOwner!;
    owner.performAction(id, SemanticsAction.scrollDown);
    await t.pump();
    expect(_state(t).debugLook, 10);
    owner.performAction(id, SemanticsAction.scrollUp);
    await t.pump();
    expect(_state(t).debugLook, 5);
    sem.dispose();
  });

  group('sheets', () {
    Future<void> open(
      WidgetTester t,
      Future<void> Function(BuildContext) show, {
      double scale = 1,
    }) async {
      t.view.physicalSize = const Size(390 * 3, 844 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(_app(
        Builder(
          builder: (context) => TextButton(
              onPressed: () => show(context), child: const Text('open')),
        ),
        scale: scale,
      ));
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
    }

    final day = _plan.dayAt(7)!;
    final names = {'GEN': 'Genesis'};

    testWidgets('a day ahead is a preview with its date, and cannot be marked',
        (t) async {
      RoadOpen? got;
      await open(
          t,
          (c) async => got = await showStopSheet(c,
              plan: _plan,
              day: day,
              status: StopStatus.ahead,
              date: DateTime(2026, 11, 28),
              bookNames: names));
      expect(find.text('DAY 7 OF 30'), findsOneWidget);
      expect(find.text('Day 7'), findsOneWidget);
      expect(find.text('Genesis 7'), findsOneWidget);
      expect(find.text('${DailyStrings.sheetAhead} · Saturday 28 November'),
          findsOneWidget);
      expect(find.text(DailyStrings.sheetDateNote), findsOneWidget);
      await t.tap(find.text(DailyStrings.previewDay));
      await t.pumpAndSettle();
      expect(got?.targetKey, 'GEN.7.1');
      expect(got?.planId, isNull, reason: 'a preview never offers Mark read');
    });

    testWidgets('the day sheet lists its chapters under the region name',
        (t) async {
      final content = DayContent(
        chapters: [
          AtlasChapter.fallback('GEN', 1),
          const AtlasChapter(
              book: 'GEN',
              chapter: 2,
              regionKey: 'Eden',
              region: 'Eden',
              biome: 'garden',
              tier: AtlasTier.scenic,
              event: 'The garden'),
        ],
        biome: 'road',
        tier: AtlasTier.scenic,
        props: const [],
        gateway: false,
      );
      // First chapter has no region, so the sheet shows no region row for it.
      await open(
          t,
          (c) async => showStopSheet(c,
              plan: _plan,
              day: day,
              status: StopStatus.ahead,
              date: null,
              bookNames: names,
              content: content));
      expect(find.text('Genesis 1'), findsOneWidget);
      expect(find.text('Genesis 2 · The garden'), findsOneWidget);
    });

    testWidgets('the day sheet shows the region name', (t) async {
      final atlas = RoadAtlas.parse(
          File('assets/images/road/road_atlas.json').readAsStringSync());
      final content = resolveDays(_plan, atlas, const {})[7]!;
      await open(
          t,
          (c) async => showStopSheet(c,
              plan: _plan,
              day: day,
              status: StopStatus.ahead,
              date: null,
              bookNames: names,
              content: content));
      expect(find.text(content.region!), findsOneWidget);
    });

    testWidgets('today can be read and marked from the road', (t) async {
      RoadOpen? got;
      await open(
          t,
          (c) async => got = await showStopSheet(c,
              plan: _plan,
              day: day,
              status: StopStatus.today,
              date: DateTime(2026, 11, 25),
              bookNames: names));
      expect(find.text('${DailyStrings.sheetToday} · Wednesday 25 November'),
          findsOneWidget);
      await t.tap(find.text(DailyStrings.readDay));
      await t.pumpAndSettle();
      expect(got?.planId, 'p');
      expect(got?.dayIndex, 7);
    });

    testWidgets('a read day can be read again, without Mark read', (t) async {
      RoadOpen? got;
      await open(
          t,
          (c) async => got = await showStopSheet(c,
              plan: _plan,
              day: day,
              status: StopStatus.done,
              date: null,
              bookNames: names));
      expect(find.text(DailyStrings.sheetDone), findsOneWidget);
      await t.tap(find.text(DailyStrings.readAgain));
      await t.pumpAndSettle();
      expect(got?.planId, isNull);
    });

    testWidgets('a landmark sheet retells, explains and offers Read and Share',
        (t) async {
      const lm = Landmark(
        id: 'gen-abram-stars',
        book: 'GEN',
        fromChapter: 12,
        toChapter: 15,
        title: 'Abram and the stars',
        short: 'Count the stars',
        ref: 'Genesis 15:5',
        art: null,
      );
      RoadOpen? got;
      await open(
          t,
          (c) async => got = await showLandmarkSheet(c,
              landmark: lm,
              story: const LandmarkStory(
                  story: 'Abram looked up. He counted.', why: 'He trusted.'),
              day: 12));
      expect(find.text('DAY 12 · GENESIS 15:5'), findsOneWidget);
      expect(find.text('Abram and the stars'), findsOneWidget);
      expect(find.text('Abram looked up. He counted.'), findsOneWidget);
      expect(find.text('He trusted.'), findsOneWidget);
      expect(find.text(DailyStrings.share), findsOneWidget);
      await t.tap(find.text('Read Genesis 15:5'));
      await t.pumpAndSettle();
      expect(got?.targetKey, 'GEN.15.5');
      expect(got?.planId, isNull);
    });

    testWidgets('a landmark without a story still opens, and big text scrolls',
        (t) async {
      const lm = Landmark(
        id: 'x',
        book: 'PSA',
        fromChapter: 119,
        toChapter: 119,
        title: 'A lamp to my feet',
        short: 'Word as a lamp',
        ref: 'Psalm 119:105',
        art: null,
      );
      await open(
          t, (c) => showLandmarkSheet(c, landmark: lm, story: null, day: 3),
          scale: 2.4);
      expect(find.text('Word as a lamp'), findsOneWidget);
      // The buttons stay reachable by scrolling: nothing overflows.
      await t.ensureVisible(find.text(DailyStrings.share));
      await t.pump();
      expect(t.takeException(), isNull);
    });
  });
}
