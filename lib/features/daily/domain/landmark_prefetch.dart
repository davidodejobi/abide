import 'road_landmarks.dart';

/// The models worth fetching quietly for a reader on [day]: those of the
/// landmarks standing at [day] through [day] + [ahead], nearest first, once
/// each. Bundled models and those whose file name is in [cached] are skipped.
/// Pure: the caller supplies what is on disk.
List<LandmarkModelInfo> prefetchSelection({
  required Map<int, List<Landmark>> byDay,
  required Map<String, LandmarkModelInfo> models,
  required int day,
  required Set<String> cached,
  int ahead = 7,
}) {
  final out = <LandmarkModelInfo>[];
  final seen = <String>{};
  for (var d = day; d <= day + ahead; d++) {
    for (final lm in byDay[d] ?? const <Landmark>[]) {
      final m = lm.art == null ? null : models[lm.art];
      if (m == null || m.bundled || cached.contains(m.remoteName)) continue;
      if (seen.add(m.art)) out.add(m);
    }
  }
  return out;
}
