import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_days.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_landmarks.dart';
import 'package:openbaptisthymnal/features/daily/ui/widgets/road_art.dart';
import 'package:openbaptisthymnal/features/daily/ui/widgets/road_sheets.dart';

const _threeDKey = ValueKey('showcase-3d');
const _staticKey = ValueKey('showcase-static');

Future<void> _pumpFor(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 50; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late RoadArt art;
  late Landmark lm;
  late ui.Image sprite;
  var done = false;

  Future<void> open(WidgetTester t,
      {bool reduce = false,
      Rect? from,
      bool withSprite = true,
      Size size = const Size(390, 844),
      double text = 1}) async {
    art = (await t.runAsync(RoadArt.load))!;
    await t.runAsync(() => art.ensureLandmarks(['garden']));
    lm = art.landmarks.firstWhere((l) => l.art == 'garden');
    sprite = art['lm_garden']!;
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    done = false;
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (c, w) => MediaQuery(
        data: MediaQuery.of(c).copyWith(
            disableAnimations: reduce, textScaler: TextScaler.linear(text)),
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

  testWidgets('flies in, lands on the podium, and falls back to the sprite without 3D',
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

    // 3D cannot start under test (no Flutter GPU): the sprite stays seated
    // on the podium, there is no turntable, and nothing throws.
    await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)));
    await _pumpFor(t, 400);
    expect(t.takeException(), isNull);
    expect(find.byKey(_staticKey), findsOneWidget);
    // The flat 2D podium stays when there is no 3D one to replace it.
    expect(
        t.widgetList<CustomPaint>(find.byType(CustomPaint)).any((p) =>
            p.painter.runtimeType.toString() == '_StagePainter' &&
            (p.painter as dynamic).contact == false),
        isTrue);
    expect(t.widget<AnimatedOpacity>(find.ancestor(of: hero, matching: find.byType(AnimatedOpacity)).first).opacity, 1);
    expect(find.byKey(_threeDKey), findsNothing,
        reason: 'the failed 3D view removes itself');
    await t.drag(find.byKey(_staticKey), const Offset(120, 0));
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

    // Nothing spins on its own and nothing throws.
    await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)));
    await _pumpFor(t, 300);
    expect(find.byKey(_staticKey), findsOneWidget);
    expect(t.takeException(), isNull);

    Navigator.of(t.element(find.byKey(_staticKey))).pop();
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
    final close = find.bySemanticsLabel('Close');
    expect(close, findsOneWidget);
    expect(
        t.getSize(find.descendant(of: close, matching: find.byType(SizedBox)).first),
        const Size(48, 48));
    await t.tap(close);
    await _pumpFor(t, 150);
    expect(done, isFalse, reason: 'flying home');
    await _pumpFor(t, 800);
    expect(done, isTrue);
  });

  for (final (name, size, text) in [
    ('375x667', const Size(375, 667), 1.0),
    ('375x667 text 1.3', const Size(375, 667), 1.3),
    ('360x640 text 1.3', const Size(360, 640), 1.3),
    ('390x844 text 2.0', const Size(390, 844), 2.0),
    ('landscape 844x390', const Size(844, 390), 1.0),
  ]) {
    testWidgets('fits and scrolls to Read on $name', (t) async {
      await open(t,
          size: size, text: text, from: const Rect.fromLTWH(20, 300, 120, 100));
      await _pumpFor(t, 1400);
      expect(t.takeException(), isNull, reason: 'no overflow');
      final read = find.text('Read ${lm.ref}');
      await t.ensureVisible(read);
      await t.pump();
      final r = t.getRect(read);
      expect(r.bottom, lessThanOrEqualTo(size.height + .5));
      expect(r.top, greaterThanOrEqualTo(0));
      expect(t.getRect(find.bySemanticsLabel('Close')).top,
          greaterThanOrEqualTo(0));
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('closing at the watchdog moment shows one image and one haptic',
      (t) async {
    var haptics = 0;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (c) async {
      if (c.method == 'HapticFeedback.vibrate') haptics++;
      return null;
    });
    addTearDown(() => t.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await open(t, from: const Rect.fromLTWH(20, 500, 120, 100));
    await _pumpFor(t, 2850);
    expect(haptics, 1);
    Navigator.of(t.element(find.byType(BottomSheet))).pop();
    await _pumpFor(t, 300);
    expect(haptics, 1, reason: 'no second landing');
    expect(find.byType(RawImage), findsOneWidget, reason: 'only the flier');
    await _pumpFor(t, 600);
    expect(done, isTrue);
  });
}
