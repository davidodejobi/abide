// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hymnal_core.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HymnalCore _$HymnalCoreFromJson(Map<String, dynamic> json) => _HymnalCore(
      schemaVersion: json['schema_version'] as String,
      hymnalId: json['hymnal_id'] as String,
      hymns: (json['hymns'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, Hymn.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$HymnalCoreToJson(_HymnalCore instance) =>
    <String, dynamic>{
      'schema_version': instance.schemaVersion,
      'hymnal_id': instance.hymnalId,
      'hymns': instance.hymns,
    };
