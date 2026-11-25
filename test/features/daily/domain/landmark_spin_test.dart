import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/daily/domain/landmark_spin.dart';

void main() {
  test('frame index wraps both ways round a full turn', () {
    expect(spinFrameFor(0), 0);
    expect(spinFrameFor(.5), 8);
    expect(spinFrameFor(1), 0);
    expect(spinFrameFor(2.25), 4);
    expect(spinFrameFor(-.25), 12);
    expect(spinFrameFor(.999), 0);
  });

  test('dragging right advances the frames; a full width is one turn', () {
    expect(dragTurns(dragPxPerTurn), 1);
    expect(spinFrameFor(dragTurns(dragPxPerTurn / 4)), 4);
    expect(spinFrameFor(dragTurns(-dragPxPerTurn / 4)), 12);
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
