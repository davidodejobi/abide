import 'package:freezed_annotation/freezed_annotation.dart';

import 'lyrics.dart';

part 'language_pack.freezed.dart';
part 'language_pack.g.dart';

@freezed
class LanguagePack with _$LanguagePack {
  const factory LanguagePack({
    required String languageCode,
    required Map<String, HymnTranslation> hymns, // hymnId: translation
  }) = _LanguagePack;

  factory LanguagePack.fromJson(Map<String, dynamic> json) =>
      _$LanguagePackFromJson(json);
}

@freezed
class HymnTranslation with _$HymnTranslation {
  const factory HymnTranslation({
    required String title,
    required Lyrics lyrics,
  }) = _HymnTranslation;

  factory HymnTranslation.fromJson(Map<String, dynamic> json) =>
      _$HymnTranslationFromJson(json);
}
