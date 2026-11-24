import 'package:openbaptisthymnal/features/hymn/data/hymnal_repository.dart';

/// Language whose hymn ids are the app-wide canonical id space (the Yoruba
/// Baptist Hymnal, numbered like the printed book). Every other pack is
/// linked to it by content through `assets/hymnal/pairs/yo_<lang>.json`.
const canonicalHymnLanguage = 'yo';

/// Answers "hymn X of language A, which id is it in language B's pack?".
///
/// Ids are NOT shared across packs: `hymn_0001` is the Doxology in `yo` and
/// "Holy, Holy, Holy" in `en`. Pairing therefore never compares ids, it goes
/// through the canonical pair table. Returns null when the other pack has no
/// confirmed version of the hymn, so callers never show a different song.
class HymnPairResolver {
  HymnPairResolver(this._repository);

  final HymnalRepository _repository;

  /// The id in [toLanguage]'s pack of the hymn [hymnId], which is an id in
  /// [fromLanguage]'s pack. Null when there is no confirmed pair.
  Future<String?> idIn(
    String toLanguage,
    String hymnId, {
    required String fromLanguage,
  }) async {
    if (toLanguage == fromLanguage) return hymnId;

    final String? canonical;
    if (fromLanguage == canonicalHymnLanguage) {
      canonical = hymnId;
    } else {
      final table = await _repository.getPairTable(fromLanguage);
      canonical = _reverse(table)[hymnId];
    }
    if (canonical == null) return null;
    if (toLanguage == canonicalHymnLanguage) return canonical;

    final table = await _repository.getPairTable(toLanguage);
    return table[canonical];
  }

  /// The canonical (yo) id of [hymnId] from [fromLanguage]'s pack.
  Future<String?> canonicalId(String hymnId, {required String fromLanguage}) =>
      idIn(canonicalHymnLanguage, hymnId, fromLanguage: fromLanguage);

  // ponytail: rebuilt per call, tables are ~100 entries. Cache if it shows up.
  Map<String, String> _reverse(Map<String, String> table) =>
      {for (final e in table.entries) e.value: e.key};
}
