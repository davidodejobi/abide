// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hymnal_index.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HymnalIndex _$HymnalIndexFromJson(Map<String, dynamic> json) => _HymnalIndex(
      orders: (json['orders'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
    );

Map<String, dynamic> _$HymnalIndexToJson(_HymnalIndex instance) =>
    <String, dynamic>{
      'orders': instance.orders,
    };
