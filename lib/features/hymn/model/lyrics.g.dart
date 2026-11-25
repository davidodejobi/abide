// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Lyrics _$LyricsFromJson(Map<String, dynamic> json) => _Lyrics(
      stanzas: (json['stanzas'] as List<dynamic>)
          .map((e) => Stanza.fromJson(e as Map<String, dynamic>))
          .toList(),
      chorus: json['chorus'] as String?,
    );

Map<String, dynamic> _$LyricsToJson(_Lyrics instance) => <String, dynamic>{
      'stanzas': instance.stanzas,
      'chorus': instance.chorus,
    };
