// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hymn.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Hymn _$HymnFromJson(Map<String, dynamic> json) {
  return _Hymn.fromJson(json);
}

/// @nodoc
mixin _$Hymn {
  String get category => throw _privateConstructorUsedError;

  /// Serializes this Hymn to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Hymn
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HymnCopyWith<Hymn> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HymnCopyWith<$Res> {
  factory $HymnCopyWith(Hymn value, $Res Function(Hymn) then) =
      _$HymnCopyWithImpl<$Res, Hymn>;
  @useResult
  $Res call({String category});
}

/// @nodoc
class _$HymnCopyWithImpl<$Res, $Val extends Hymn>
    implements $HymnCopyWith<$Res> {
  _$HymnCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Hymn
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
  }) {
    return _then(_value.copyWith(
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HymnImplCopyWith<$Res> implements $HymnCopyWith<$Res> {
  factory _$$HymnImplCopyWith(
          _$HymnImpl value, $Res Function(_$HymnImpl) then) =
      __$$HymnImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String category});
}

/// @nodoc
class __$$HymnImplCopyWithImpl<$Res>
    extends _$HymnCopyWithImpl<$Res, _$HymnImpl>
    implements _$$HymnImplCopyWith<$Res> {
  __$$HymnImplCopyWithImpl(_$HymnImpl _value, $Res Function(_$HymnImpl) _then)
      : super(_value, _then);

  /// Create a copy of Hymn
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
  }) {
    return _then(_$HymnImpl(
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HymnImpl implements _Hymn {
  const _$HymnImpl({required this.category});

  factory _$HymnImpl.fromJson(Map<String, dynamic> json) =>
      _$$HymnImplFromJson(json);

  @override
  final String category;

  @override
  String toString() {
    return 'Hymn(category: $category)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HymnImpl &&
            (identical(other.category, category) ||
                other.category == category));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, category);

  /// Create a copy of Hymn
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HymnImplCopyWith<_$HymnImpl> get copyWith =>
      __$$HymnImplCopyWithImpl<_$HymnImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HymnImplToJson(
      this,
    );
  }
}

abstract class _Hymn implements Hymn {
  const factory _Hymn({required final String category}) = _$HymnImpl;

  factory _Hymn.fromJson(Map<String, dynamic> json) = _$HymnImpl.fromJson;

  @override
  String get category;

  /// Create a copy of Hymn
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HymnImplCopyWith<_$HymnImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
