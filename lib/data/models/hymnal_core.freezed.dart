// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hymnal_core.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

HymnalCore _$HymnalCoreFromJson(Map<String, dynamic> json) {
  return _HymnalCore.fromJson(json);
}

/// @nodoc
mixin _$HymnalCore {
  @JsonKey(name: 'schema_version')
  String get schemaVersion => throw _privateConstructorUsedError;
  @JsonKey(name: 'hymnal_id')
  String get hymnalId => throw _privateConstructorUsedError;
  @JsonKey(name: 'source_language')
  String get sourceLanguage => throw _privateConstructorUsedError;
  Map<String, Hymn> get hymns => throw _privateConstructorUsedError;

  /// Serializes this HymnalCore to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HymnalCore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HymnalCoreCopyWith<HymnalCore> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HymnalCoreCopyWith<$Res> {
  factory $HymnalCoreCopyWith(
          HymnalCore value, $Res Function(HymnalCore) then) =
      _$HymnalCoreCopyWithImpl<$Res, HymnalCore>;
  @useResult
  $Res call(
      {@JsonKey(name: 'schema_version') String schemaVersion,
      @JsonKey(name: 'hymnal_id') String hymnalId,
      @JsonKey(name: 'source_language') String sourceLanguage,
      Map<String, Hymn> hymns});
}

/// @nodoc
class _$HymnalCoreCopyWithImpl<$Res, $Val extends HymnalCore>
    implements $HymnalCoreCopyWith<$Res> {
  _$HymnalCoreCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HymnalCore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? schemaVersion = null,
    Object? hymnalId = null,
    Object? sourceLanguage = null,
    Object? hymns = null,
  }) {
    return _then(_value.copyWith(
      schemaVersion: null == schemaVersion
          ? _value.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as String,
      hymnalId: null == hymnalId
          ? _value.hymnalId
          : hymnalId // ignore: cast_nullable_to_non_nullable
              as String,
      sourceLanguage: null == sourceLanguage
          ? _value.sourceLanguage
          : sourceLanguage // ignore: cast_nullable_to_non_nullable
              as String,
      hymns: null == hymns
          ? _value.hymns
          : hymns // ignore: cast_nullable_to_non_nullable
              as Map<String, Hymn>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HymnalCoreImplCopyWith<$Res>
    implements $HymnalCoreCopyWith<$Res> {
  factory _$$HymnalCoreImplCopyWith(
          _$HymnalCoreImpl value, $Res Function(_$HymnalCoreImpl) then) =
      __$$HymnalCoreImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'schema_version') String schemaVersion,
      @JsonKey(name: 'hymnal_id') String hymnalId,
      @JsonKey(name: 'source_language') String sourceLanguage,
      Map<String, Hymn> hymns});
}

/// @nodoc
class __$$HymnalCoreImplCopyWithImpl<$Res>
    extends _$HymnalCoreCopyWithImpl<$Res, _$HymnalCoreImpl>
    implements _$$HymnalCoreImplCopyWith<$Res> {
  __$$HymnalCoreImplCopyWithImpl(
      _$HymnalCoreImpl _value, $Res Function(_$HymnalCoreImpl) _then)
      : super(_value, _then);

  /// Create a copy of HymnalCore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? schemaVersion = null,
    Object? hymnalId = null,
    Object? sourceLanguage = null,
    Object? hymns = null,
  }) {
    return _then(_$HymnalCoreImpl(
      schemaVersion: null == schemaVersion
          ? _value.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as String,
      hymnalId: null == hymnalId
          ? _value.hymnalId
          : hymnalId // ignore: cast_nullable_to_non_nullable
              as String,
      sourceLanguage: null == sourceLanguage
          ? _value.sourceLanguage
          : sourceLanguage // ignore: cast_nullable_to_non_nullable
              as String,
      hymns: null == hymns
          ? _value._hymns
          : hymns // ignore: cast_nullable_to_non_nullable
              as Map<String, Hymn>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HymnalCoreImpl implements _HymnalCore {
  const _$HymnalCoreImpl(
      {@JsonKey(name: 'schema_version') required this.schemaVersion,
      @JsonKey(name: 'hymnal_id') required this.hymnalId,
      @JsonKey(name: 'source_language') required this.sourceLanguage,
      required final Map<String, Hymn> hymns})
      : _hymns = hymns;

  factory _$HymnalCoreImpl.fromJson(Map<String, dynamic> json) =>
      _$$HymnalCoreImplFromJson(json);

  @override
  @JsonKey(name: 'schema_version')
  final String schemaVersion;
  @override
  @JsonKey(name: 'hymnal_id')
  final String hymnalId;
  @override
  @JsonKey(name: 'source_language')
  final String sourceLanguage;
  final Map<String, Hymn> _hymns;
  @override
  Map<String, Hymn> get hymns {
    if (_hymns is EqualUnmodifiableMapView) return _hymns;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_hymns);
  }

  @override
  String toString() {
    return 'HymnalCore(schemaVersion: $schemaVersion, hymnalId: $hymnalId, sourceLanguage: $sourceLanguage, hymns: $hymns)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HymnalCoreImpl &&
            (identical(other.schemaVersion, schemaVersion) ||
                other.schemaVersion == schemaVersion) &&
            (identical(other.hymnalId, hymnalId) ||
                other.hymnalId == hymnalId) &&
            (identical(other.sourceLanguage, sourceLanguage) ||
                other.sourceLanguage == sourceLanguage) &&
            const DeepCollectionEquality().equals(other._hymns, _hymns));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, schemaVersion, hymnalId,
      sourceLanguage, const DeepCollectionEquality().hash(_hymns));

  /// Create a copy of HymnalCore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HymnalCoreImplCopyWith<_$HymnalCoreImpl> get copyWith =>
      __$$HymnalCoreImplCopyWithImpl<_$HymnalCoreImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HymnalCoreImplToJson(
      this,
    );
  }
}

abstract class _HymnalCore implements HymnalCore {
  const factory _HymnalCore(
      {@JsonKey(name: 'schema_version') required final String schemaVersion,
      @JsonKey(name: 'hymnal_id') required final String hymnalId,
      @JsonKey(name: 'source_language') required final String sourceLanguage,
      required final Map<String, Hymn> hymns}) = _$HymnalCoreImpl;

  factory _HymnalCore.fromJson(Map<String, dynamic> json) =
      _$HymnalCoreImpl.fromJson;

  @override
  @JsonKey(name: 'schema_version')
  String get schemaVersion;
  @override
  @JsonKey(name: 'hymnal_id')
  String get hymnalId;
  @override
  @JsonKey(name: 'source_language')
  String get sourceLanguage;
  @override
  Map<String, Hymn> get hymns;

  /// Create a copy of HymnalCore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HymnalCoreImplCopyWith<_$HymnalCoreImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
