/// Canonical USFM 3-letter book codes in canonical order (ordinal 1..66).
///
/// The bundled translations key books by their localized display name
/// (Genesis vs Jẹnẹsisi), so only this ordinal aligns editions. A stable code
/// lets us build cross-language verse refs like `JHN.3.16` that survive
/// translation and language changes.
const List<String> kBibleBookCodes = [
  'GEN', 'EXO', 'LEV', 'NUM', 'DEU', 'JOS', 'JDG', 'RUT', '1SA', '2SA', //
  '1KI', '2KI', '1CH', '2CH', 'EZR', 'NEH', 'EST', 'JOB', 'PSA', 'PRO', //
  'ECC', 'SNG', 'ISA', 'JER', 'LAM', 'EZK', 'DAN', 'HOS', 'JOL', 'AMO', //
  'OBA', 'JON', 'MIC', 'NAM', 'HAB', 'ZEP', 'HAG', 'ZEC', 'MAL', 'MAT', //
  'MRK', 'LUK', 'JHN', 'ACT', 'ROM', '1CO', '2CO', 'GAL', 'EPH', 'PHP', //
  'COL', '1TH', '2TH', '1TI', '2TI', 'TIT', 'PHM', 'HEB', 'JAS', '1PE', //
  '2PE', '1JN', '2JN', '3JN', 'JUD', 'REV', //
];

/// Ordinal (1-based) of the first New Testament book (Matthew).
const int kFirstNewTestamentOrdinal = 40;

/// Whether a 1-based book ordinal belongs to the Old Testament.
bool isOldTestament(int ordinal) => ordinal < kFirstNewTestamentOrdinal;

/// Canonical code for a 1-based ordinal, or null if out of range.
String? bookCodeForOrdinal(int ordinal) {
  if (ordinal < 1 || ordinal > kBibleBookCodes.length) return null;
  return kBibleBookCodes[ordinal - 1];
}

/// 1-based ordinal for a canonical code, or null if unknown.
int? ordinalForBookCode(String code) {
  final i = kBibleBookCodes.indexOf(code.toUpperCase());
  return i == -1 ? null : i + 1;
}
