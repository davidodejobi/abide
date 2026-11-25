import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_days.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_landmarks.dart';
import 'package:openbaptisthymnal/features/daily/ui/widgets/road_art.dart';
import 'package:openbaptisthymnal/features/daily/ui/widgets/road_scene.dart';
import 'package:openbaptisthymnal/features/daily/ui/widgets/road_sheets.dart';

// Own file: sprite decoding is real async I/O, and a decode started under a
// widget test's fake clock elsewhere would never finish.
void main() {
  testWidgets('Landmark sprites decode small and only for the window',
      (t) async {
    final art = (await t.runAsync(RoadArt.load))!;
    await t.runAsync(() => art.ensureLandmarks(['garden', 'ark']));
    expect(art['lm_garden']!.width, RoadArt.spriteWidth);
    expect(art['lm_ark'], isNotNull);
    // The camera moves on: ark leaves the window and is released.
    await t.runAsync(() => art.ensureLandmarks(['garden', 'tomb']));
    expect(art['lm_ark'], isNull);
    expect(art['lm_tomb'], isNotNull);
    expect(art['lm_garden'], isNotNull);
    // A sprite that does not exist is recorded, never thrown.
    await t.runAsync(() => art.ensureLandmarks(['no-such-art']));
    expect(art.failed, contains('no-such-art'));
    expect(art['lm_garden'], isNull);
  });

  testWidgets('A landmark with its sprite decoded is tappable, and so is a failed one',
      (t) async {
    final plan = ReadingPlan(id: 'p', title: '', description: '', days: [
      for (var i = 1; i <= 30; i++)
        PlanDay(dayIndex: i, passages: [VerseRange.tryParse('GEN.$i.1-31')!]),
    ]);
    final art = (await t.runAsync(RoadArt.load))!;
    // Decode what the scene's window will ask for up front: real I/O must run
    // outside the widget test's fake clock.
    await t.runAsync(() => art.ensureLandmarks([
          for (final l in landmarksByDay(plan, art.landmarks).entries)
            if (l.key <= 21) ...l.value.map((x) => x.art),
        ]));
    final taps = <String>[];
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: RoadScene(
          key: const ValueKey('r'),
          width: 390,
          mood: RoadMood.day,
          currentDay: 6,
          totalDays: 30,
          plan: plan,
          onLandmarkTap: (l, d) => taps.add(l.id),
        ),
      ),
    ));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await t.pump(const Duration(milliseconds: 100));
    final st = t.state<RoadSceneState>(find.byKey(const ValueKey('r')));
    expect(art['lm_ark'], isNotNull, reason: 'Noah stands at day 6');
    await t.tapAt(st.debugLandmarkTap(6)!);
    expect(taps, ['gen-ark']);
    // The same stop with its sprite failed: the signpost takes the tap.
    art.failed.add('ark');
    await t.runAsync(() => art.ensureLandmarks([]));
    await t.pump(const Duration(milliseconds: 100));
    await t.tapAt(st.debugLandmarkTap(6)!);
    expect(taps, ['gen-ark', 'gen-ark']);
  });

  testWidgets('A landmark sheet shows its picture, even if the road evicts it',
      (t) async {
    final art = (await t.runAsync(RoadArt.load))!;
    await t.runAsync(() => art.ensureLandmarks(['garden']));
    final lm = art.landmarks.firstWhere((l) => l.art == 'garden');
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showLandmarkSheet(context,
                landmark: lm,
                story: const LandmarkStory(story: 'A. B. C.', why: 'D.'),
                day: 1,
                sprite: art['lm_garden']),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.byType(RawImage), findsOneWidget);
    await t.runAsync(() => art.ensureLandmarks([]));
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.byType(RawImage), findsOneWidget);
  });
}
