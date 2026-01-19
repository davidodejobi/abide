// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hymnal_index.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

HymnalIndex _$HymnalIndexFromJson(Map<String, dynamic> json) {
  return _HymnalIndex.fromJson(json);
}

/// @nodoc
mixin _$HymnalIndex {
  Map<String, List<String>> get orders => throw _privateConstructorUsedError;

  /// Serializes this HymnalIndex to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HymnalIndex
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HymnalIndexCopyWith<HymnalIndex> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HymnalIndexCopyWith<$Res> {
  factory $HymnalIndexCopyWith(
          HymnalIndex value, $Res Function(HymnalIndex) then) =
      _$HymnalIndexCopyWithImpl<$Res, HymnalIndex>;
  @useResult
  $Res call({Map<String, List<String>> orders});
}

/// @nodoc
class _$HymnalIndexCopyWithImpl<$Res, $Val extends HymnalIndex>
    implements $HymnalIndexCopyWith<$Res> {
  _$HymnalIndexCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HymnalIndex
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orders = null,
  }) {
    return _then(_value.copyWith(
      orders: null == orders
          ? _value.orders
          : orders // ignore: cast_nullable_to_non_nullable
              as Map<String, List<String>>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HymnalIndexImplCopyWith<$Res>
    implements $HymnalIndexCopyWith<$Res> {
  factory _$$HymnalIndexImplCopyWith(
          _$HymnalIndexImpl value, $Res Function(_$HymnalIndexImpl) then) =
      __$$HymnalIndexImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Map<String, List<String>> orders});
}

/// @nodoc
class __$$HymnalIndexImplCopyWithImpl<$Res>
    extends _$HymnalIndexCopyWithImpl<$Res, _$HymnalIndexImpl>
    implements _$$HymnalIndexImplCopyWith<$Res> {
  __$$HymnalIndexImplCopyWithImpl(
      _$HymnalIndexImpl _value, $Res Function(_$HymnalIndexImpl) _then)
      : super(_value, _then);

  /// Create a copy of HymnalIndex
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orders = null,
  }) {
    return _then(_$HymnalIndexImpl(
      orders: null == orders
          ? _value._orders
          : orders // ignore: cast_nullable_to_non_nullable
              as Map<String, List<String>>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HymnalIndexImpl implements _HymnalIndex {
  const _$HymnalIndexImpl({required final Map<String, List<String>> orders})
      : _orders = orders;

  factory _$HymnalIndexImpl.fromJson(Map<String, dynamic> json) =>
      _$$HymnalIndexImplFromJson(json);

  final Map<String, List<String>> _orders;
  @override
  Map<String, List<String>> get orders {
    if (_orders is EqualUnmodifiableMapView) return _orders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_orders);
  }

  @override
  String toString() {
    return 'HymnalIndex(orders: $orders)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HymnalIndexImpl &&
            const DeepCollectionEquality().equals(other._orders, _orders));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_orders));

  /// Create a copy of HymnalIndex
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HymnalIndexImplCopyWith<_$HymnalIndexImpl> get copyWith =>
      __$$HymnalIndexImplCopyWithImpl<_$HymnalIndexImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HymnalIndexImplToJson(
      this,
    );
  }
}

abstract class _HymnalIndex implements HymnalIndex {
  const factory _HymnalIndex(
      {required final Map<String, List<String>> orders}) = _$HymnalIndexImpl;

  factory _HymnalIndex.fromJson(Map<String, dynamic> json) =
      _$HymnalIndexImpl.fromJson;

  @override
  Map<String, List<String>> get orders;

  /// Create a copy of HymnalIndex
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HymnalIndexImplCopyWith<_$HymnalIndexImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
