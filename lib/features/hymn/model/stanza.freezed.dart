// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stanza.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Stanza {
  int get index;
  String get text;

  /// Create a copy of Stanza
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $StanzaCopyWith<Stanza> get copyWith =>
      _$StanzaCopyWithImpl<Stanza>(this as Stanza, _$identity);

  /// Serializes this Stanza to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as Stanza;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Stanza &&
            (identical(other.index, _this.index) ||
                other.index == _this.index) &&
            (identical(other.text, _this.text) || other.text == _this.text));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as Stanza;
    return Object.hash(runtimeType, _this.index, _this.text);
  }

  @override
  String toString() {
    final _this = this as Stanza;
    return 'Stanza(index: ${_this.index}, text: ${_this.text})';
  }
}

/// @nodoc
abstract mixin class $StanzaCopyWith<$Res> {
  factory $StanzaCopyWith(Stanza value, $Res Function(Stanza) _then) =
      _$StanzaCopyWithImpl;
  @useResult
  $Res call({int index, String text});
}

/// @nodoc
class _$StanzaCopyWithImpl<$Res> implements $StanzaCopyWith<$Res> {
  _$StanzaCopyWithImpl(this._self, this._then);

  final Stanza _self;
  final $Res Function(Stanza) _then;

  /// Create a copy of Stanza
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? index = null,
    Object? text = null,
  }) {
    return _then(Stanza(
      index: null == index
          ? _self.index
          : index // ignore: cast_nullable_to_non_nullable
              as int,
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [Stanza].
extension StanzaPatterns on Stanza {
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
    TResult Function(_Stanza value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Stanza() when $default != null:
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
    TResult Function(_Stanza value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Stanza():
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
    TResult? Function(_Stanza value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Stanza() when $default != null:
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
    TResult Function(int index, String text)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Stanza() when $default != null:
        return $default(_that.index, _that.text);
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
    TResult Function(int index, String text) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Stanza():
        return $default(_that.index, _that.text);
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
    TResult? Function(int index, String text)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Stanza() when $default != null:
        return $default(_that.index, _that.text);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Stanza implements Stanza {
  const _Stanza({required this.index, required this.text});
  factory _Stanza.fromJson(Map<String, dynamic> json) => _$StanzaFromJson(json);

  @override
  final int index;
  @override
  final String text;

  /// Create a copy of Stanza
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$StanzaCopyWith<_Stanza> get copyWith =>
      __$StanzaCopyWithImpl<_Stanza>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$StanzaToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Stanza &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.text, text) || other.text == text));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, index, text);
  }

  @override
  String toString() {
    return 'Stanza(index: $index, text: $text)';
  }
}

/// @nodoc
abstract mixin class _$StanzaCopyWith<$Res> implements $StanzaCopyWith<$Res> {
  factory _$StanzaCopyWith(_Stanza value, $Res Function(_Stanza) _then) =
      __$StanzaCopyWithImpl;
  @override
  @useResult
  $Res call({int index, String text});
}

/// @nodoc
class __$StanzaCopyWithImpl<$Res> implements _$StanzaCopyWith<$Res> {
  __$StanzaCopyWithImpl(this._self, this._then);

  final _Stanza _self;
  final $Res Function(_Stanza) _then;

  /// Create a copy of Stanza
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? index = null,
    Object? text = null,
  }) {
    return _then(_Stanza(
      index: null == index
          ? _self.index
          : index // ignore: cast_nullable_to_non_nullable
              as int,
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
