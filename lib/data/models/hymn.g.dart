// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hymn.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HymnImpl _$$HymnImplFromJson(Map<String, dynamic> json) => _$HymnImpl(
      id: json['id'] as String,
      category: json['category'] as String,
      orders: Map<String, int>.from(json['orders'] as Map),
    );

Map<String, dynamic> _$$HymnImplToJson(_$HymnImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category,
      'orders': instance.orders,
    };
