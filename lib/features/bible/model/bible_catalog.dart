import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';

/// The CDN's `bibles/catalog.json`: every edition Lumway offers, bundled or
/// downloadable.
class BibleCatalog {
  const BibleCatalog({required this.schemaVersion, required this.editions});

  /// Highest schema this build understands. A newer catalog is still read on a
  /// best-effort basis, but a missing required field throws [FormatException].
  static const supportedSchema = 1;

  final int schemaVersion;
  final List<BibleCatalogEntry> editions;

  factory BibleCatalog.fromJson(Map<String, dynamic> json) {
    final list = json['editions'];
    if (json['schemaVersion'] is! int || list is! List) {
      throw const FormatException('bible catalog: bad shape');
    }
    return BibleCatalog(
      schemaVersion: json['schemaVersion'] as int,
      editions: [
        for (final e in list)
          BibleCatalogEntry.fromJson(e as Map<String, dynamic>),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'editions': [for (final e in editions) e.toJson()],
      };
}

class BibleCatalogEntry {
  const BibleCatalogEntry({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.languageCode,
    required this.languageName,
    required this.sizeBytes,
    required this.sha256,
    required this.url,
    required this.attribution,
    required this.bundled,
  });

  final String id;
  final String name;
  final String abbreviation;
  final String languageCode;
  final String languageName;
  final int sizeBytes;
  final String sha256;

  /// Path relative to the CDN base, e.g. `bibles/en-ylt-1a2b3c4d.zip`.
  final String url;
  final String attribution;

  /// Ships inside the app, so there is nothing to download.
  final bool bundled;

  factory BibleCatalogEntry.fromJson(Map<String, dynamic> j) {
    return BibleCatalogEntry(
      id: j['id'] as String,
      name: j['name'] as String,
      abbreviation: j['abbreviation'] as String,
      languageCode: j['languageCode'] as String,
      languageName: j['languageName'] as String,
      sizeBytes: j['sizeBytes'] as int,
      sha256: (j['sha256'] as String).toLowerCase(),
      url: j['url'] as String,
      attribution: j['attribution'] as String,
      bundled: j['bundled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'abbreviation': abbreviation,
        'languageCode': languageCode,
        'languageName': languageName,
        'sizeBytes': sizeBytes,
        'sha256': sha256,
        'url': url,
        'attribution': attribution,
        'bundled': bundled,
      };

  /// The edition this entry becomes once installed.
  BibleEdition toEdition() => BibleEdition(
        id: id,
        languageCode: languageCode,
        versionCode: abbreviation.toLowerCase(),
        displayName: name,
        attribution: attribution,
      );
}
