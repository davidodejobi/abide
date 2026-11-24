import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/reading_plan.dart';

/// The plans bundled with the app, in the order the picker shows them.
///
/// Shortest first: someone who has never finished a reading plan should not have
/// "365 days" as the first thing they see. The New Testament in 90 days is the
/// one most people can actually finish, and finishing one is what makes them
/// start another.
const kBundledPlanIds = <String>[
  'psalms-30',
  'nt-90',
  'bible-in-a-year',
];

/// Loads reading plans from `assets/plans/`. Mirrors `BibleLocalSource`: the
/// JSON is bundled and read-only, so there is nothing to sync and nothing to
/// fail at runtime except a missing asset declaration.
class PlanLocalSource {
  const PlanLocalSource({AssetBundle? bundle}) : _bundle = bundle;

  final AssetBundle? _bundle;

  AssetBundle get _assets => _bundle ?? rootBundle;

  Future<ReadingPlan> load(String planId) async {
    final raw = await _assets.loadString('assets/plans/$planId.json');
    return ReadingPlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Every bundled plan, for the picker.
  Future<List<ReadingPlan>> loadAll() async {
    return Future.wait(kBundledPlanIds.map(load));
  }
}
