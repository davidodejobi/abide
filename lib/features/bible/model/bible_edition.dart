/// One available Bible edition: a (language, version) pair mapped to a folder
/// of text, bundled under `assets/bible/<id>/` or downloaded. This is the Bible-local seed of the
/// future shared "editions" abstraction that will also back Songs.
class BibleEdition {
  const BibleEdition({
    required this.id,
    required this.languageCode,
    required this.versionCode,
    required this.displayName,
    required this.attribution,
  });

  /// Stable id, also the asset folder name, e.g. `en-kjv`.
  final String id;
  final String languageCode;
  final String versionCode;
  final String displayName;

  /// Source + license credit shown on the translations credits screen. Required
  /// to satisfy CC BY-SA attribution for the Biblica editions; the public-domain
  /// editions carry a plain "Public Domain" note.
  final String attribution;

  String get assetDir => 'assets/bible/$id';

  Map<String, dynamic> toJson() => {
        'id': id,
        'languageCode': languageCode,
        'versionCode': versionCode,
        'displayName': displayName,
        'attribution': attribution,
      };

  factory BibleEdition.fromJson(Map<String, dynamic> j) => BibleEdition(
        id: j['id'] as String,
        languageCode: j['languageCode'] as String,
        versionCode: j['versionCode'] as String,
        displayName: j['displayName'] as String,
        attribution: j['attribution'] as String,
      );
}

/// The editions that ship inside the app. Everything else is downloaded from
/// the catalog and lives in the app support directory (see
/// `InstalledBibleStore`); `bibleEditionsProvider` merges both.
const List<BibleEdition> kBibleEditions = [
  BibleEdition(
    id: 'en-kjv',
    languageCode: 'en',
    versionCode: 'kjv',
    displayName: 'English (KJV)',
    attribution: 'King James Version (1769) · Public Domain',
  ),
  BibleEdition(
    id: 'en-bsb',
    languageCode: 'en',
    versionCode: 'bsb',
    displayName: 'English (BSB)',
    attribution: 'Berean Standard Bible · Public Domain (CC0)',
  ),
  BibleEdition(
    id: 'en-asv',
    languageCode: 'en',
    versionCode: 'asv',
    displayName: 'English (ASV)',
    attribution: 'American Standard Version (1901) · Public Domain',
  ),
];
