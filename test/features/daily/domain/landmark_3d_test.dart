import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/daily/domain/landmark_3d.dart';

void main() {
  const ark = '{"landmarks":{"ark":{"camera_distance":12.73,'
      '"yaw_start_deg":90,"bounds_min":[-3.4,0,-2.62],"bounds_max":[3.4,3.513,2.62]}}}';

  test('framing reads the manifest entry and sizes the podium from bounds', () {
    final f = parseFramings(ark);
    expect(f.keys, ['ark']);
    expect(f['ark']!.yawStartTurns, .25);
    final foot = math.sqrt(3.4 * 3.4 + 2.62 * 2.62);
    expect(f['ark']!.podiumRadius, closeTo(podiumFootprintScale * foot, 1e-9));
  });

  test('eye sits at the distance, a three-quarter elevation above the target', () {
    const f = LandmarkFraming(distance: 10, targetY: 2);
    expect(LandmarkFraming.elevationDeg, inInclusiveRange(20, 28));
    final (x, y, z) = f.eye;
    const e = LandmarkFraming.elevationDeg * math.pi / 180;
    expect(x, 0);
    expect(y, closeTo(2 + 10 * math.sin(e), 1e-9));
    expect(z, lessThan(0), reason: 'front of the model faces -Z in the engine');
    expect(math.sqrt(x * x + (y - 2) * (y - 2) + z * z), closeTo(10, 1e-9));
  });

  test('the podium centre lands on the anchor, the target at the view centre', () {
    final f = parseFramings(ark)['ark']!;
    expect(f.project((0, 0, 0)).$2, closeTo(podiumAnchorY, 1e-3));
    expect(f.project((0, f.targetY, 0)).$2, closeTo(0, 1e-9));
  });

  test('every landmark, model top and whole podium, fits the view', () {
    final raw = File('assets/images/road/models/manifest.json').readAsStringSync();
    final lm = (jsonDecode(raw) as Map)['landmarks'] as Map;
    for (final e in parseFramings(raw).entries) {
      final fr = e.value, r = fr.podiumRadius;
      final top = ((lm[e.key] as Map)['bounds_max'] as List)[1] as num;
      final pts = <(double, double, double)>[
        for (var i = 0; i < 36; i++)
          for (final y in [0.0, -podiumDepth * r])
            (r * math.cos(i * math.pi / 18), y, r * math.sin(i * math.pi / 18)),
        (0, top.toDouble(), 0),
        (r, 0, 0),
      ];
      final rim = fr.project((r, 0, 0)).$1;
      expect(rim, greaterThan(.5), reason: '${e.key} podium too small: $rim');
      expect(fr.project((0, top.toDouble(), 0)).$2, lessThanOrEqualTo(LandmarkFraming.topFill + 1e-6));
      for (final p in pts) {
        final (px, py) = fr.project(p);
        expect(px.abs(), lessThanOrEqualTo(LandmarkFraming.viewFill + 1e-6), reason: '${e.key} x');
        expect(py, inInclusiveRange(-1, LandmarkFraming.viewFill + 1e-6), reason: '${e.key} y');
      }
    }
  });

  test('the podium glb is bundled and tiny', () {
    expect(File('assets/images/road/models/podium.glb').lengthSync(), lessThan(20 * 1024));
  });

  test('the bundled manifest covers every landmark sprite', () {
    final f = parseFramings(
        File('assets/images/road/models/manifest.json').readAsStringSync());
    final sprites = Directory('assets/images/road/living')
        .listSync()
        .map((e) => e.uri.pathSegments.last)
        .where((n) => n.startsWith('lm_'))
        .map((n) => n.substring(3, n.length - 5));
    expect(f.keys.toSet(), sprites.toSet());
    for (final k in f.keys) {
      expect(File('assets/images/road/models/$k.glb').existsSync(), isTrue);
      expect(f[k]!.podiumRadius, greaterThan(0));
    }
  });

  test('dragging right is positive; a full width is one turn', () {
    expect(dragTurns(dragPxPerTurn), 1);
    expect(dragTurns(-dragPxPerTurn / 4), -.25);
  });

  test('fling velocity converts to turns per second with its sign', () {
    expect(flingTurnsPerSecond(640), 2);
    expect(flingTurnsPerSecond(-320), -1);
  });

  test('palette picks saturated colours and skips grey and transparent', () {
    final px = Uint8List.fromList([
      for (var i = 0; i < 600; i++) ...[220, 40, 40, 255], // red
      for (var i = 0; i < 600; i++) ...[128, 128, 128, 255], // grey
      for (var i = 0; i < 600; i++) ...[40, 200, 40, 0], // transparent green
    ]);
    final p = spinPalette(px, count: 2);
    expect(p, hasLength(1));
    expect((p.first >> 16) & 0xFF, greaterThan(180));
    expect((p.first >> 8) & 0xFF, lessThan(80));
  });
}
