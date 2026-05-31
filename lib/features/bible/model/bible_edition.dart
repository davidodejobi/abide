/// One available Bible edition: a (language, version) pair mapped to a bundled
/// asset folder under `assets/bible/<id>/`. This is the Bible-local seed of the
/// future shared "editions" abstraction that will also back Songs.
class BibleEdition {
  const BibleEdition({
    required this.id,
    required this.languageCode,
    required this.versionCode,
    required this.displayName,
  });

  /// Stable id, also the asset folder name, e.g. `en-kjv`.
  final String id;
  final String languageCode;
  final String versionCode;
  final String displayName;

  String get assetDir => 'assets/bible/$id';
}

/// The editions shipped today. New translations/languages are added here (and
/// their asset folder generated) — the reader and split picker pick them up
/// automatically.
const List<BibleEdition> kBibleEditions = [
  BibleEdition(
    id: 'en-kjv',
    languageCode: 'en',
    versionCode: 'kjv',
    displayName: 'English (KJV)',
  ),
  BibleEdition(
    id: 'yo-bmy',
    languageCode: 'yo',
    versionCode: 'bmy',
    displayName: 'Yorùbá (Bíbélì Mímọ́)',
  ),
];
