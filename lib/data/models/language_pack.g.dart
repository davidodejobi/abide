// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language_pack.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LanguagePackImpl _$$LanguagePackImplFromJson(Map<String, dynamic> json) =>
    _$LanguagePackImpl(
      languageCode: json['languageCode'] as String,
      hymns: (json['hymns'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, HymnTranslation.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$$LanguagePackImplToJson(_$LanguagePackImpl instance) =>
    <String, dynamic>{
      'languageCode': instance.languageCode,
      'hymns': instance.hymns,
    };

_$HymnTranslationImpl _$$HymnTranslationImplFromJson(
        Map<String, dynamic> json) =>
    _$HymnTranslationImpl(
      title: json['title'] as String,
      lyrics: Lyrics.fromJson(json['lyrics'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$HymnTranslationImplToJson(
        _$HymnTranslationImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'lyrics': instance.lyrics,
    };
