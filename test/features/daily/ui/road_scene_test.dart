import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';
import 'package:openbaptisthymnal/features/daily/ui/widgets/road_art.dart';
import 'package:openbaptisthymnal/features/daily/ui/widgets/road_scene.dart';

final _plan = ReadingPlan(id: 'p', title: '', description: '', days: [
  for (var i = 1; i <= 30; i++)
    PlanDay(dayIndex: i, passages: [VerseRange.tryParse('GEN.$i.1-31')!]),
]);

Widget _road(Key key, int day) => RoadScene(
      key: key,
      width: 390,
      mood: RoadMood.day,
      currentDay: day,
      totalDays: 30,
      plan: _plan,
    );

Widget _app(Widget child, {bool reduce = false}) => MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (c, w) => MediaQuery(
        data: MediaQuery.of(c).copyWith(disableAnimations: reduce),
        child: w!,
      ),
      home: Scaffold(body: child),
    );

RoadSceneState _state(WidgetTester t, Key k) =>
    t.state<RoadSceneState>(find.byKey(k, skipOffstage: false));

void main() {
  // The art decodes with real async I/O, so load it outside the fake clock
  // before the widget asks for it.
  Future<void> loadArt(WidgetTester t) => t.runAsync(RoadArt.load);

  testWidgets('Given a day is read, Then the traveller walks to the next stop',
      (t) async {
    await loadArt(t);
    const k = ValueKey('road');
    await t.pumpWidget(_app(_road(k, 1)));
    await t.pump(const Duration(milliseconds: 50));
    expect(_state(t, k).debugPos, 1);
    await t.pumpWidget(_app(_road(k, 2)));
    await t.pump(const Duration(milliseconds: 1300));
    final mid = _state(t, k).debugPos;
    expect(mid, greaterThan(1.1));
    expect(mid, lessThan(1.9));
    await t.pump(const Duration(milliseconds: 1500));
    expect(_state(t, k).debugPos, 2);
    expect(t.takeException(), isNull);
  });

  testWidgets('Given reduced motion, Then the road cuts to the new stop',
      (t) async {
    await loadArt(t);
    const k = ValueKey('road');
    await t.pumpWidget(_app(_road(k, 1), reduce: true));
    await t.pumpWidget(_app(_road(k, 2), reduce: true));
    expect(_state(t, k).debugPos, 2);
    await t.pump(const Duration(milliseconds: 300));
    // No ambient loop and no walk: nothing left to animate.
    expect(t.binding.hasScheduledFrame, isFalse);
    expect(t.takeException(), isNull);
  });

  testWidgets(
      'Given Today is hidden, Then nothing animates and a read day waits to be walked',
      (t) async {
    await loadArt(t);
    const k = ValueKey('road');
    Widget stack(int index, int day) =>
        _app(IndexedStack(index: index, children: [
          for (final (i, w) in [_road(k, day), const SizedBox()].indexed)
            TickerMode(enabled: i == index, child: w),
        ]));
    await t.pumpWidget(stack(0, 1));
    await t.pump(const Duration(milliseconds: 50));
    await t.pumpWidget(stack(1, 1)); // switch away
    await t.pump(const Duration(seconds: 1));
    expect(t.binding.transientCallbackCount, 0,
        reason: 'no tickers should run');
    await t.pumpWidget(stack(1, 2)); // day read while hidden
    await t.pump(const Duration(seconds: 4));
    expect(_state(t, k).debugPos, 1, reason: 'the walk must wait for the tab');
    await t.pumpWidget(stack(0, 2)); // back to Today
    await t.pump(const Duration(milliseconds: 1300));
    final mid = _state(t, k).debugPos;
    expect(mid, greaterThan(1.1));
    expect(mid, lessThan(1.9));
    await t.pump(const Duration(milliseconds: 1500));
    expect(_state(t, k).debugPos, 2);
  });

  testWidgets(
      'Given the plan is finished, Then it draws without a current stop',
      (t) async {
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      home: const Scaffold(
        body: RoadScene(
            width: 390,
            mood: RoadMood.evening,
            currentDay: null,
            totalDays: 30),
      ),
    ));
    await t.pump(const Duration(milliseconds: 100));
    expect(t.takeException(), isNull);
  });

  testWidgets('Given the sky changes mid-walk, Then it waits for the walk',
      (t) async {
    await loadArt(t);
    const k = ValueKey('road');
    Widget road(int day, RoadMood mood) => RoadScene(
        key: k,
        width: 390,
        mood: mood,
        currentDay: day,
        totalDays: 30,
        plan: _plan);
    await t.pumpWidget(_app(road(1, RoadMood.day)));
    await t.pump(const Duration(milliseconds: 50));
    await t.pumpWidget(_app(road(2, RoadMood.day)));
    await t.pump(const Duration(milliseconds: 1000));
    await t.pumpWidget(_app(road(2, RoadMood.evening)));
    await t.pump(const Duration(milliseconds: 1));
    // The walk was not restarted: the traveller is still on the way, sky unchanged.
    expect(_state(t, k).debugPos, greaterThan(1.1));
    expect(_state(t, k).debugDusk, 0);
    await t.pump(const Duration(seconds: 2));
    await t.pump(const Duration(seconds: 2));
    expect(_state(t, k).debugPos, 2);
    expect(_state(t, k).debugDusk, 1);
  });
}
