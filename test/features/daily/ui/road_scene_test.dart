import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/features/daily/ui/widgets/road_scene.dart';

Widget _app(int day, {bool reduce = false}) => MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(disableAnimations: reduce),
        child: child!,
      ),
      home: Scaffold(
        body: RoadScene(
          width: 390,
          mood: RoadMood.day,
          currentDay: day,
          totalDays: 365,
        ),
      ),
    );

bool _walking(WidgetTester t) => t.binding.hasScheduledFrame;

void main() {
  testWidgets('Given a day is read, Then the traveller walks for a few seconds',
      (t) async {
    await t.pumpWidget(_app(1));
    await t.pump(const Duration(milliseconds: 50));
    await t.pumpWidget(_app(2));
    await t.pump(const Duration(milliseconds: 1200));
    // Still mid-walk after 1.2 s, so a frame is scheduled; it ends by ~2.6 s.
    expect(_walking(t), isTrue);
    await t.pump(const Duration(milliseconds: 1600));
    expect(t.takeException(), isNull);
  });

  testWidgets('Given reduced motion, Then the road cuts to the new stop',
      (t) async {
    await t.pumpWidget(_app(1, reduce: true));
    await t.pumpWidget(_app(2, reduce: true));
    await t.pump(const Duration(milliseconds: 300));
    // No ambient loop and no walk: nothing left to animate.
    expect(_walking(t), isFalse);
    expect(t.takeException(), isNull);
  });

  testWidgets('Given the plan is finished, Then it draws without a current stop',
      (t) async {
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      home: const Scaffold(
        body: RoadScene(
            width: 390, mood: RoadMood.evening, currentDay: null, totalDays: 30),
      ),
    ));
    await t.pump(const Duration(milliseconds: 100));
    expect(t.takeException(), isNull);
  });
}
