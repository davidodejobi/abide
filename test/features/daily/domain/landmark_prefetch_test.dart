import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/daily/domain/landmark_prefetch.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_landmarks.dart';

void main() {
  LandmarkModelInfo model(String art, {bool bundled = false}) =>
      LandmarkModelInfo(
          art: art, title: art, sha256: 'a' * 64, bundled: bundled, bytes: 5);
  Landmark lm(String art) => Landmark(
      id: 'x-$art',
      book: 'GEN',
      fromChapter: 1,
      toChapter: 1,
      title: art,
      short: art,
      ref: 'Genesis 1',
      art: art);

  final models = {
    for (final a in ['a', 'b', 'c', 'd', 'e', 'f'])
      a: model(a, bundled: a == 'b'),
  };
  final byDay = {
    for (var d = 1; d <= 12; d++) d: [lm(['a', 'b', 'c', 'd', 'e', 'f'][d % 6])],
  };

  test('takes the day through day + 7, nearest first, once each', () {
    final got = prefetchSelection(
        byDay: byDay, models: models, day: 3, cached: {}).map((m) => m.art);
    // days 3..10 are d e f a b c d e: b is bundled, repeats dropped.
    expect(got, ['d', 'e', 'f', 'a', 'c']);
  });

  test('skips cached files and bundled models', () {
    final got = prefetchSelection(
        byDay: byDay,
        models: models,
        day: 3,
        cached: {models['e']!.remoteName}).map((m) => m.art);
    expect(got, ['d', 'f', 'a', 'c']);
  });

  test('does not look past the window or before the day', () {
    final got = prefetchSelection(
        byDay: {1: [lm('a')], 5: [lm('c')], 13: [lm('d')]},
        models: models,
        day: 5,
        cached: {}).map((m) => m.art);
    expect(got, ['c']);
  });

  test('a landmark with no art or no manifest entry is ignored', () {
    const none = Landmark(
        id: 'n',
        book: 'GEN',
        fromChapter: 1,
        toChapter: 1,
        title: 'n',
        short: 'n',
        ref: 'r',
        art: null);
    expect(
        prefetchSelection(byDay: {
          1: [none, lm('zzz')]
        }, models: models, day: 1, cached: {}),
        isEmpty);
  });
}
