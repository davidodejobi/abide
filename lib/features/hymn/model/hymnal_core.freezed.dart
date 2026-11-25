// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hymnal_core.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HymnalCore {
  @JsonKey(name: 'schema_version')
  String get schemaVersion;
  @JsonKey(name: 'hymnal_id')
  String get hymnalId;
  Map<String, Hymn> get hymns;

  /// Create a copy of HymnalCore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HymnalCoreCopyWith<HymnalCore> get copyWith =>
      _$HymnalCoreCopyWithImpl<HymnalCore>(this as HymnalCore, _$identity);

  /// Serializes this HymnalCore to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as HymnalCore;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HymnalCore &&
            (identical(other.schemaVersion, _this.schemaVersion) ||
                other.schemaVersion == _this.schemaVersion) &&
            (identical(other.hymnalId, _this.hymnalId) ||
                other.hymnalId == _this.hymnalId) &&
            const DeepCollectionEquality().equals(other.hymns, _this.hymns));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as HymnalCore;
    return Object.hash(runtimeType, _this.schemaVersion, _this.hymnalId,
        const DeepCollectionEquality().hash(_this.hymns));
  }

  @override
  String toString() {
    final _this = this as HymnalCore;
    return 'HymnalCore(schemaVersion: ${_this.schemaVersion}, hymnalId: ${_this.hymnalId}, hymns: ${_this.hymns})';
  }
}

/// @nodoc
abstract mixin class $HymnalCoreCopyWith<$Res> {
  factory $HymnalCoreCopyWith(
          HymnalCore value, $Res Function(HymnalCore) _then) =
      _$HymnalCoreCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(name: 'schema_version') String schemaVersion,
      @JsonKey(name: 'hymnal_id') String hymnalId,
      Map<String, Hymn> hymns});
}

/// @nodoc
class _$HymnalCoreCopyWithImpl<$Res> implements $HymnalCoreCopyWith<$Res> {
  _$HymnalCoreCopyWithImpl(this._self, this._then);

  final HymnalCore _self;
  final $Res Function(HymnalCore) _then;

  /// Create a copy of HymnalCore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? schemaVersion = null,
    Object? hymnalId = null,
    Object? hymns = null,
  }) {
    return _then(HymnalCore(
      schemaVersion: null == schemaVersion
          ? _self.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as String,
      hymnalId: null == hymnalId
          ? _self.hymnalId
          : hymnalId // ignore: cast_nullable_to_non_nullable
              as String,
      hymns: null == hymns
          ? _self.hymns
          : hymns // ignore: cast_nullable_to_non_nullable
              as Map<String, Hymn>,
    ));
  }
}

/// Adds pattern-matching-related methods to [HymnalCore].
extension HymnalCorePatterns on HymnalCore {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_HymnalCore value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HymnalCore() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_HymnalCore value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HymnalCore():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_HymnalCore value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HymnalCore() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            @JsonKey(name: 'schema_version') String schemaVersion,
            @JsonKey(name: 'hymnal_id') String hymnalId,
            Map<String, Hymn> hymns)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HymnalCore() when $default != null:
        return $default(_that.schemaVersion, _that.hymnalId, _that.hymns);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            @JsonKey(name: 'schema_version') String schemaVersion,
            @JsonKey(name: 'hymnal_id') String hymnalId,
            Map<String, Hymn> hymns)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HymnalCore():
        return $default(_that.schemaVersion, _that.hymnalId, _that.hymns);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            @JsonKey(name: 'schema_version') String schemaVersion,
            @JsonKey(name: 'hymnal_id') String hymnalId,
            Map<String, Hymn> hymns)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HymnalCore() when $default != null:
        return $default(_that.schemaVersion, _that.hymnalId, _that.hymns);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _HymnalCore implements HymnalCore {
  const _HymnalCore(
      {@JsonKey(name: 'schema_version') required this.schemaVersion,
      @JsonKey(name: 'hymnal_id') required this.hymnalId,
      required Map<String, Hymn> hymns})
      : _hymns = hymns;
  factory _HymnalCore.fromJson(Map<String, dynamic> json) =>
      _$HymnalCoreFromJson(json);

  @override
  @JsonKey(name: 'schema_version')
  final String schemaVersion;
  @override
  @JsonKey(name: 'hymnal_id')
  final String hymnalId;
  final Map<String, Hymn> _hymns;
  @override
  Map<String, Hymn> get hymns {
    if (_hymns is EqualUnmodifiableMapView) return _hymns;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_hymns);
  }

  /// Create a copy of HymnalCore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HymnalCoreCopyWith<_HymnalCore> get copyWith =>
      __$HymnalCoreCopyWithImpl<_HymnalCore>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$HymnalCoreToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HymnalCore &&
            (identical(other.schemaVersion, schemaVersion) ||
                other.schemaVersion == schemaVersion) &&
            (identical(other.hymnalId, hymnalId) ||
                other.hymnalId == hymnalId) &&
            const DeepCollectionEquality().equals(other.hymns, _hymns));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, schemaVersion, hymnalId,
        const DeepCollectionEquality().hash(_hymns));
  }

  @override
  String toString() {
    return 'HymnalCore(schemaVersion: $schemaVersion, hymnalId: $hymnalId, hymns: $hymns)';
  }
}

/// @nodoc
abstract mixin class _$HymnalCoreCopyWith<$Res>
    implements $HymnalCoreCopyWith<$Res> {
  factory _$HymnalCoreCopyWith(
          _HymnalCore value, $Res Function(_HymnalCore) _then) =
      __$HymnalCoreCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'schema_version') String schemaVersion,
      @JsonKey(name: 'hymnal_id') String hymnalId,
      Map<String, Hymn> hymns});
}

/// @nodoc
class __$HymnalCoreCopyWithImpl<$Res> implements _$HymnalCoreCopyWith<$Res> {
  __$HymnalCoreCopyWithImpl(this._self, this._then);

  final _HymnalCore _self;
  final $Res Function(_HymnalCore) _then;

  /// Create a copy of HymnalCore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? schemaVersion = null,
    Object? hymnalId = null,
    Object? hymns = null,
  }) {
    return _then(_HymnalCore(
      schemaVersion: null == schemaVersion
          ? _self.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as String,
      hymnalId: null == hymnalId
          ? _self.hymnalId
          : hymnalId // ignore: cast_nullable_to_non_nullable
              as String,
      hymns: null == hymns
          ? _self._hymns
          : hymns // ignore: cast_nullable_to_non_nullable
              as Map<String, Hymn>,
    ));
  }
}

// dart format on
