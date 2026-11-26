import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/landmark_prefetch.dart';
import '../domain/reading_plan.dart';
import '../domain/road_landmarks.dart';
import 'landmark_download_provider.dart';

/// Quietly fetches the models of the landmarks from the reader's day through
/// the next 7, so they are on disk before the road reaches them. Two at a
/// time, never throws, does nothing on web or without a CDN. Call it freely:
/// a model already tried this run is not asked for twice.
final landmarkPrefetchProvider =
    Provider<Future<void> Function(ReadingPlan plan, int day)>((ref) {
  final tried = <String>{};
  var active = 0;
  return (plan, day) async {
    final loader = ref.read(landmarkLoaderProvider);
    final cache = loader.cache;
    if (cache == null || loader.cdnBase.isEmpty) return;
    try {
      final catalog = await ref.read(landmarkCatalogProvider.future);
      final byDay = landmarksByDay(plan, catalog);
      final cached = <String>{};
      for (final m in catalog.models.values) {
        if (!m.bundled && await cache.has(m.remoteName)) {
          cached.add(m.remoteName);
        }
      }
      final queue = prefetchSelection(
          byDay: byDay, models: catalog.models, day: day, cached: cached);
      Future<void> worker() async {
        while (queue.isNotEmpty) {
          final m = queue.removeAt(0);
          if (tried.add(m.art)) await loader.load(m);
        }
      }

      // A shared counter keeps overlapping calls from running more than 2.
      final n = (2 - active).clamp(0, 2);
      active += n;
      await Future.wait([for (var i = 0; i < n; i++) worker()])
          .whenComplete(() => active -= n);
    } catch (_) {}
  };
});
