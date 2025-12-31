// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hymnal_core.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HymnalCoreImpl _$$HymnalCoreImplFromJson(Map<String, dynamic> json) =>
    _$HymnalCoreImpl(
      schemaVersion: json['schema_version'] as String,
      hymnalId: json['hymnal_id'] as String,
      sourceLanguage: json['source_language'] as String,
      hymns: (json['hymns'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, Hymn.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$$HymnalCoreImplToJson(_$HymnalCoreImpl instance) =>
    <String, dynamic>{
      'schema_version': instance.schemaVersion,
      'hymnal_id': instance.hymnalId,
      'source_language': instance.sourceLanguage,
      'hymns': instance.hymns,
    };
