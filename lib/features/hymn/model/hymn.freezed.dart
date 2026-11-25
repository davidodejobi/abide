// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hymn.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Hymn {
  String get category;

  /// Create a copy of Hymn
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HymnCopyWith<Hymn> get copyWith =>
      _$HymnCopyWithImpl<Hymn>(this as Hymn, _$identity);

  /// Serializes this Hymn to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as Hymn;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Hymn &&
            (identical(other.category, _this.category) ||
                other.category == _this.category));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as Hymn;
    return Object.hash(runtimeType, _this.category);
  }

  @override
  String toString() {
    final _this = this as Hymn;
    return 'Hymn(category: ${_this.category})';
  }
}

/// @nodoc
abstract mixin class $HymnCopyWith<$Res> {
  factory $HymnCopyWith(Hymn value, $Res Function(Hymn) _then) =
      _$HymnCopyWithImpl;
  @useResult
  $Res call({String category});
}

/// @nodoc
class _$HymnCopyWithImpl<$Res> implements $HymnCopyWith<$Res> {
  _$HymnCopyWithImpl(this._self, this._then);

  final Hymn _self;
  final $Res Function(Hymn) _then;

  /// Create a copy of Hymn
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
  }) {
    return _then(Hymn(
      category: null == category
          ? _self.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [Hymn].
extension HymnPatterns on Hymn {
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
    TResult Function(_Hymn value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Hymn() when $default != null:
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
    TResult Function(_Hymn value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Hymn():
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
    TResult? Function(_Hymn value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Hymn() when $default != null:
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
    TResult Function(String category)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Hymn() when $default != null:
        return $default(_that.category);
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
    TResult Function(String category) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Hymn():
        return $default(_that.category);
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
    TResult? Function(String category)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Hymn() when $default != null:
        return $default(_that.category);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Hymn implements Hymn {
  const _Hymn({required this.category});
  factory _Hymn.fromJson(Map<String, dynamic> json) => _$HymnFromJson(json);

  @override
  final String category;

  /// Create a copy of Hymn
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HymnCopyWith<_Hymn> get copyWith =>
      __$HymnCopyWithImpl<_Hymn>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$HymnToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Hymn &&
            (identical(other.category, category) ||
                other.category == category));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, category);
  }

  @override
  String toString() {
    return 'Hymn(category: $category)';
  }
}

/// @nodoc
abstract mixin class _$HymnCopyWith<$Res> implements $HymnCopyWith<$Res> {
  factory _$HymnCopyWith(_Hymn value, $Res Function(_Hymn) _then) =
      __$HymnCopyWithImpl;
  @override
  @useResult
  $Res call({String category});
}

/// @nodoc
class __$HymnCopyWithImpl<$Res> implements _$HymnCopyWith<$Res> {
  __$HymnCopyWithImpl(this._self, this._then);

  final _Hymn _self;
  final $Res Function(_Hymn) _then;

  /// Create a copy of Hymn
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? category = null,
  }) {
    return _then(_Hymn(
      category: null == category
          ? _self.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
