import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_atlas.dart';

PlanDay _day(int i, List<String> refs) => PlanDay(
    dayIndex: i, passages: [for (final r in refs) VerseRange.tryParse(r)!]);

ReadingPlan _plan(List<PlanDay> days) =>
    ReadingPlan(id: 'p', title: 't', description: 'd', days: days);

void main() {
  final atlas = RoadAtlas.parse(
      File('assets/images/road/road_atlas.json').readAsStringSync());

  test('the bundled atlas covers every chapter', () {
    expect(atlas.length, 1189);
  });

  test('a Psalms-only plan gets regions and biomes on every day', () {
    final out = resolveDays(
        _plan([for (var i = 1; i <= 20; i++) _day(i, ['PSA.$i.1-$i.1'])]),
        atlas,
        const {});
    expect(out.length, 20);
    for (final d in out.values) {
      expect(d.region, isNotNull);
      expect(d.biome, isNotEmpty);
      expect(d.chapters, hasLength(1));
    }
    expect(out[1]!.gateway, isFalse);
  });

  test('a multi-chapter day lists every chapter; first sets the biome', () {
    final d = resolveDays(_plan([_day(1, ['GEN.1.1-3.24'])]), atlas, const {})[1]!;
    expect(d.chapters.map((c) => c.chapter), [1, 2, 3]);
    expect(d.biome, atlas.chapter('GEN', 1).biome);
  });

  test('a chapter missing from the atlas falls back to scenery', () {
    final c = atlas.chapter('GEN', 999);
    expect(c.tier, AtlasTier.scenic);
    expect(c.region, isNull);
    expect(atlas.has('GEN', 999), isFalse);
    final d =
        resolveDays(_plan([_day(1, ['GEN.999.1-999.1'])]), atlas, const {})[1]!;
    expect(d.props, isEmpty);
    expect(d.biome, 'road');
  });

  test('a gateway appears when the region changes between days', () {
    final out = resolveDays(
        _plan([_day(1, ['GEN.1.1-1.1']), _day(2, ['REV.22.1-22.1'])]),
        atlas,
        const {});
    expect(out[2]!.gateway, isTrue);
  });
}
