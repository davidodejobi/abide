// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hymnal_index.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HymnalIndex {
  Map<String, List<String>> get orders;

  /// Create a copy of HymnalIndex
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HymnalIndexCopyWith<HymnalIndex> get copyWith =>
      _$HymnalIndexCopyWithImpl<HymnalIndex>(this as HymnalIndex, _$identity);

  /// Serializes this HymnalIndex to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as HymnalIndex;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HymnalIndex &&
            const DeepCollectionEquality().equals(other.orders, _this.orders));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as HymnalIndex;
    return Object.hash(
        runtimeType, const DeepCollectionEquality().hash(_this.orders));
  }

  @override
  String toString() {
    final _this = this as HymnalIndex;
    return 'HymnalIndex(orders: ${_this.orders})';
  }
}

/// @nodoc
abstract mixin class $HymnalIndexCopyWith<$Res> {
  factory $HymnalIndexCopyWith(
          HymnalIndex value, $Res Function(HymnalIndex) _then) =
      _$HymnalIndexCopyWithImpl;
  @useResult
  $Res call({Map<String, List<String>> orders});
}

/// @nodoc
class _$HymnalIndexCopyWithImpl<$Res> implements $HymnalIndexCopyWith<$Res> {
  _$HymnalIndexCopyWithImpl(this._self, this._then);

  final HymnalIndex _self;
  final $Res Function(HymnalIndex) _then;

  /// Create a copy of HymnalIndex
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orders = null,
  }) {
    return _then(HymnalIndex(
      orders: null == orders
          ? _self.orders
          : orders // ignore: cast_nullable_to_non_nullable
              as Map<String, List<String>>,
    ));
  }
}

/// Adds pattern-matching-related methods to [HymnalIndex].
extension HymnalIndexPatterns on HymnalIndex {
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
    TResult Function(_HymnalIndex value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HymnalIndex() when $default != null:
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
    TResult Function(_HymnalIndex value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HymnalIndex():
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
    TResult? Function(_HymnalIndex value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HymnalIndex() when $default != null:
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
    TResult Function(Map<String, List<String>> orders)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HymnalIndex() when $default != null:
        return $default(_that.orders);
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
    TResult Function(Map<String, List<String>> orders) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HymnalIndex():
        return $default(_that.orders);
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
    TResult? Function(Map<String, List<String>> orders)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HymnalIndex() when $default != null:
        return $default(_that.orders);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _HymnalIndex implements HymnalIndex {
  const _HymnalIndex({required Map<String, List<String>> orders})
      : _orders = orders;
  factory _HymnalIndex.fromJson(Map<String, dynamic> json) =>
      _$HymnalIndexFromJson(json);

  final Map<String, List<String>> _orders;
  @override
  Map<String, List<String>> get orders {
    if (_orders is EqualUnmodifiableMapView) return _orders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_orders);
  }

  /// Create a copy of HymnalIndex
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HymnalIndexCopyWith<_HymnalIndex> get copyWith =>
      __$HymnalIndexCopyWithImpl<_HymnalIndex>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$HymnalIndexToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HymnalIndex &&
            const DeepCollectionEquality().equals(other.orders, _orders));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
        runtimeType, const DeepCollectionEquality().hash(_orders));
  }

  @override
  String toString() {
    return 'HymnalIndex(orders: $orders)';
  }
}

/// @nodoc
abstract mixin class _$HymnalIndexCopyWith<$Res>
    implements $HymnalIndexCopyWith<$Res> {
  factory _$HymnalIndexCopyWith(
          _HymnalIndex value, $Res Function(_HymnalIndex) _then) =
      __$HymnalIndexCopyWithImpl;
  @override
  @useResult
  $Res call({Map<String, List<String>> orders});
}

/// @nodoc
class __$HymnalIndexCopyWithImpl<$Res> implements _$HymnalIndexCopyWith<$Res> {
  __$HymnalIndexCopyWithImpl(this._self, this._then);

  final _HymnalIndex _self;
  final $Res Function(_HymnalIndex) _then;

  /// Create a copy of HymnalIndex
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? orders = null,
  }) {
    return _then(_HymnalIndex(
      orders: null == orders
          ? _self._orders
          : orders // ignore: cast_nullable_to_non_nullable
              as Map<String, List<String>>,
    ));
  }
}

// dart format on
