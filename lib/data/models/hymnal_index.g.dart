// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hymnal_index.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HymnalIndexImpl _$$HymnalIndexImplFromJson(Map<String, dynamic> json) =>
    _$HymnalIndexImpl(
      orders: (json['orders'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
    );

Map<String, dynamic> _$$HymnalIndexImplToJson(_$HymnalIndexImpl instance) =>
    <String, dynamic>{
      'orders': instance.orders,
    };
