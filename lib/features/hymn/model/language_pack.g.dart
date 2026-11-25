// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language_pack.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LanguagePack _$LanguagePackFromJson(Map<String, dynamic> json) =>
    _LanguagePack(
      language: json['language'] as String,
      hymnalName: json['hymnal_name'] as String,
      hymns: (json['hymns'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, HymnTranslation.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$LanguagePackToJson(_LanguagePack instance) =>
    <String, dynamic>{
      'language': instance.language,
      'hymnal_name': instance.hymnalName,
      'hymns': instance.hymns,
    };

_HymnTranslation _$HymnTranslationFromJson(Map<String, dynamic> json) =>
    _HymnTranslation(
      number: (json['number'] as num).toInt(),
      title: json['title'] as String,
      lyrics: Lyrics.fromJson(json['lyrics'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$HymnTranslationToJson(_HymnTranslation instance) =>
    <String, dynamic>{
      'number': instance.number,
      'title': instance.title,
      'lyrics': instance.lyrics,
    };
