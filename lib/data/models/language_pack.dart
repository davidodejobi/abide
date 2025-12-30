import 'package:freezed_annotation/freezed_annotation.dart';

import 'lyrics.dart';

part 'language_pack.freezed.dart';
part 'language_pack.g.dart';

// ignore_for_file: invalid_annotation_target
@freezed
class LanguagePack with _$LanguagePack {
  const factory LanguagePack({
    required String language,
    @JsonKey(name: 'hymnal_name') required String hymnalName,
    required Map<String, HymnTranslation> hymns,
  }) = _LanguagePack;

  factory LanguagePack.fromJson(Map<String, dynamic> json) =>
      _$LanguagePackFromJson(json);
}

@freezed
class HymnTranslation with _$HymnTranslation {
  const factory HymnTranslation({
    required int number,
    required String title,
    required Lyrics lyrics,
  }) = _HymnTranslation;

  factory HymnTranslation.fromJson(Map<String, dynamic> json) =>
      _$HymnTranslationFromJson(json);
}
