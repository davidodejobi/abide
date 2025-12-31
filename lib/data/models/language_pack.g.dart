// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language_pack.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LanguagePackImpl _$$LanguagePackImplFromJson(Map<String, dynamic> json) =>
    _$LanguagePackImpl(
      language: json['language'] as String,
      hymnalName: json['hymnal_name'] as String,
      hymns: (json['hymns'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, HymnTranslation.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$$LanguagePackImplToJson(_$LanguagePackImpl instance) =>
    <String, dynamic>{
      'language': instance.language,
      'hymnal_name': instance.hymnalName,
      'hymns': instance.hymns,
    };

_$HymnTranslationImpl _$$HymnTranslationImplFromJson(
        Map<String, dynamic> json) =>
    _$HymnTranslationImpl(
      number: (json['number'] as num).toInt(),
      title: json['title'] as String,
      lyrics: Lyrics.fromJson(json['lyrics'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$HymnTranslationImplToJson(
        _$HymnTranslationImpl instance) =>
    <String, dynamic>{
      'number': instance.number,
      'title': instance.title,
      'lyrics': instance.lyrics,
    };
