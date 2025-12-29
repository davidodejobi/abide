// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LyricsImpl _$$LyricsImplFromJson(Map<String, dynamic> json) => _$LyricsImpl(
      stanzas:
          (json['stanzas'] as List<dynamic>).map((e) => e as String).toList(),
      chorus: json['chorus'] as String?,
    );

Map<String, dynamic> _$$LyricsImplToJson(_$LyricsImpl instance) =>
    <String, dynamic>{
      'stanzas': instance.stanzas,
      'chorus': instance.chorus,
    };
