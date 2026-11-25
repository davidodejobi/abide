import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_days.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_landmarks.dart';
import 'package:openbaptisthymnal/features/daily/ui/widgets/road_art.dart';
import 'package:openbaptisthymnal/features/daily/ui/widgets/road_sheets.dart';

const _spinKey = ValueKey('showcase-spin');
const _staticKey = ValueKey('showcase-static');

Future<void> _pumpFor(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 50; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// The 2048 px sheet decodes off the fake clock: give real time until it is in.
Future<void> _waitSpin(WidgetTester t) async {
  for (var i = 0; i < 150 && find.byKey(_spinKey).evaluate().isEmpty; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late RoadArt art;
  late Landmark lm;
  late ui.Image sprite;
  var done = false;

  Future<void> open(WidgetTester t,
      {bool reduce = false, Rect? from, bool withSprite = true}) async {
    art = (await t.runAsync(RoadArt.load))!;
    await t.runAsync(RoadArt.spinMeta);
    await t.runAsync(() => art.ensureLandmarks(['garden']));
    lm = art.landmarks.firstWhere((l) => l.art == 'garden');
    sprite = art['lm_garden']!;
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    done = false;
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (c, w) => MediaQuery(
        data: MediaQuery.of(c).copyWith(disableAnimations: reduce),
        child: w!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              await showLandmarkSheet(context,
                  landmark: lm,
                  story: const LandmarkStory(story: 'A. B. C.', why: 'D.'),
                  day: 1,
                  sprite: withSprite ? sprite : null,
                  from: from);
              done = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('open'));
  }

  testWidgets('flies in, lands on the podium, then the turntable takes over',
      (t) async {
    await open(t, from: const Rect.fromLTWH(20, 500, 120, 100));
    await _pumpFor(t, 300);
    // Mid-air: the sheet's own picture is hidden, the flier is on the overlay.
    final hero = find.byKey(_staticKey);
    expect(hero, findsOneWidget);
    expect(t.widget<Opacity>(find.ancestor(of: hero, matching: find.byType(Opacity)).first).opacity, 0);
    expect(find.byType(RawImage), findsNWidgets(2));

    await _pumpFor(t, 1000);
    expect(t.widget<Opacity>(find.ancestor(of: hero, matching: find.byType(Opacity)).first).opacity, 1);
    expect(find.byType(RawImage), findsOneWidget, reason: 'the flier is gone');
    expect(find.text(lm.title), findsOneWidget);

    // Lazy: the sheet decodes only now, off the fake clock.
    await _waitSpin(t);
    await _pumpFor(t, 400);
    expect(find.byKey(_spinKey), findsOneWidget);
    expect(find.byKey(_staticKey), findsNothing);

    // Drag to spin: nothing throws.
    await t.drag(find.byKey(_spinKey), const Offset(120, 0));
    await _pumpFor(t, 300);
    expect(t.takeException(), isNull);
  });

  testWidgets('closing flies it back home before the call resolves',
      (t) async {
    await open(t, from: const Rect.fromLTWH(20, 500, 120, 100));
    await _pumpFor(t, 1400);
    Navigator.of(t.element(find.byKey(_staticKey))).pop();
    await _pumpFor(t, 150);
    expect(done, isFalse, reason: 'still flying home');
    await _pumpFor(t, 800);
    expect(done, isTrue);
    expect(find.byType(RawImage), findsNothing);
  });

  testWidgets('after closing, the overlay rebuilds cleanly and nothing leaks',
      (t) async {
    await open(t, from: const Rect.fromLTWH(20, 500, 120, 100));
    // Handles held by the road's own sprite are the baseline.
    final before = sprite.debugGetOpenHandleStackTraces()!.length;
    await _pumpFor(t, 1400);
    Navigator.of(t.element(find.byKey(_staticKey))).pop();
    await _pumpFor(t, 250);
    // Any overlay rebuild (a dialog here) must not touch a disposed image.
    final ctx = t.element(find.byType(TextButton));
    showDialog<void>(context: ctx, builder: (_) => const AlertDialog(title: Text('hi')));
    await _pumpFor(t, 600);
    expect(t.takeException(), isNull);
    expect(find.text('hi'), findsOneWidget);
    expect(find.byType(ErrorWidget), findsNothing);
    expect(done, isTrue);
    expect(find.byType(RawImage), findsNothing, reason: 'fliers removed');
    expect(sprite.debugGetOpenHandleStackTraces()!.length, before,
        reason: 'no handle left over from the sheet');
  });

  testWidgets('opening another landmark while one closes is independent',
      (t) async {
    await open(t, from: const Rect.fromLTWH(20, 500, 120, 100));
    await _pumpFor(t, 1400);
    Navigator.of(t.element(find.byKey(_staticKey))).pop();
    await _pumpFor(t, 100);
    t.widget<TextButton>(find.byType(TextButton)).onPressed!();
    await _pumpFor(t, 1500);
    expect(t.takeException(), isNull);
    expect(find.byKey(_staticKey), findsOneWidget);
    expect(find.text(lm.title), findsOneWidget);
  });

  testWidgets('reduced motion: no flight, picture is simply there',
      (t) async {
    await open(t, reduce: true, from: const Rect.fromLTWH(20, 500, 120, 100));
    await _pumpFor(t, 100);
    final hero = find.byKey(_staticKey);
    expect(hero, findsOneWidget);
    expect(t.widget<Opacity>(find.ancestor(of: hero, matching: find.byType(Opacity)).first).opacity, 1);
    expect(find.byType(RawImage), findsOneWidget, reason: 'no flier');
    await _pumpFor(t, 400);
    expect(find.text(lm.title), findsOneWidget);

    // Still draggable once the turntable is in; it does not idle on its own.
    await _waitSpin(t);
    await _pumpFor(t, 300);
    expect(find.byKey(_spinKey), findsOneWidget);
    await t.drag(find.byKey(_spinKey), const Offset(-90, 0));
    await t.pump();
    expect(t.takeException(), isNull);

    Navigator.of(t.element(find.byKey(_spinKey))).pop();
    await _pumpFor(t, 400);
    expect(done, isTrue, reason: 'nothing to wait for');
  });

  testWidgets('without a sprite the sheet is the plain title block',
      (t) async {
    await open(t, withSprite: false);
    await t.pumpAndSettle();
    expect(find.byType(RawImage), findsNothing);
    expect(find.text(lm.title), findsOneWidget);
  });

  testWidgets('the sheet is capped so the road shows, with a Close button',
      (t) async {
    await open(t, from: const Rect.fromLTWH(20, 500, 120, 100));
    await _pumpFor(t, 1400);
    final h = t.getSize(find.byType(BottomSheet)).height;
    expect(h, lessThanOrEqualTo(844 * .78 + 1));
    // Round close button, 48 pt target, labelled for screen readers.
    final close = find.bySemanticsLabel('Close');
    expect(close, findsOneWidget);
    expect(t.getSize(find.descendant(of: close, matching: find.byType(SizedBox)).first),
        const Size(48, 48));
    await t.tap(close);
    await _pumpFor(t, 150);
    expect(done, isFalse, reason: 'flying home');
    await _pumpFor(t, 800);
    expect(done, isTrue);
  });

  testWidgets('a turntable that cannot load leaves the static picture',
      (t) async {
    await open(t, from: const Rect.fromLTWH(20, 500, 120, 100));
    await _pumpFor(t, 200);
    Navigator.of(t.element(find.byKey(_staticKey))).pop();
    await _pumpFor(t, 1200);
    // Same sprite, art with no sheet shipped.
    const ghost = Landmark(
        id: 'g',
        book: 'GEN',
        fromChapter: 1,
        toChapter: 1,
        title: 'Ghost',
        short: 's',
        ref: 'Genesis 1',
        art: 'no-such-art');
    final ctx = t.element(find.byType(TextButton));
    showLandmarkSheet(ctx, landmark: ghost, story: null, day: 1, sprite: sprite);
    await _pumpFor(t, 600);
    await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await _pumpFor(t, 300);
    expect(find.byKey(_staticKey), findsOneWidget);
    expect(find.byKey(_spinKey), findsNothing);
    expect(t.takeException(), isNull);
  });
}
