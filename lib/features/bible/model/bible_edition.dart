/// One available Bible edition: a (language, version) pair mapped to a bundled
/// asset folder under `assets/bible/<id>/`. This is the Bible-local seed of the
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
    attribution: 'King James Version (1769) · Public Domain',
  ),
  BibleEdition(
    id: 'yo-bmy',
    languageCode: 'yo',
    versionCode: 'bmy',
    displayName: 'Yorùbá (Bíbélì Mímọ́)',
    attribution: 'Bíbélì Mímọ́ (1900) · Public Domain',
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
  BibleEdition(
    id: 'en-ylt',
    languageCode: 'en',
    versionCode: 'ylt',
    displayName: 'English (YLT)',
    attribution: "Young's Literal Translation (1898) · Public Domain",
  ),
  BibleEdition(
    id: 'ha-biblica',
    languageCode: 'ha',
    versionCode: 'biblica',
    displayName: 'Hausa (Biblica)',
    attribution: 'Hausa Contemporary Bible © 2009, 2020 Biblica, Inc. · '
        'CC BY-SA 4.0',
  ),
  BibleEdition(
    id: 'ig-biblica',
    languageCode: 'ig',
    versionCode: 'biblica',
    displayName: 'Igbo (Biblica)',
    attribution: 'Igbo Contemporary Bible © 2020 Biblica, Inc. · CC BY-SA 4.0',
  ),
  BibleEdition(
    id: 'yo-biblica',
    languageCode: 'yo',
    versionCode: 'biblica',
    displayName: 'Yorùbá (Òde-Òní)',
    attribution: 'Yorùbá Contemporary Bible © 2009, 2017 Biblica, Inc. · '
        'CC BY-SA 4.0',
  ),
];
