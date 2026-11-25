// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lyrics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Lyrics {
  List<Stanza> get stanzas;
  String? get chorus;

  /// Create a copy of Lyrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LyricsCopyWith<Lyrics> get copyWith =>
      _$LyricsCopyWithImpl<Lyrics>(this as Lyrics, _$identity);

  /// Serializes this Lyrics to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as Lyrics;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Lyrics &&
            const DeepCollectionEquality()
                .equals(other.stanzas, _this.stanzas) &&
            (identical(other.chorus, _this.chorus) ||
                other.chorus == _this.chorus));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as Lyrics;
    return Object.hash(runtimeType,
        const DeepCollectionEquality().hash(_this.stanzas), _this.chorus);
  }

  @override
  String toString() {
    final _this = this as Lyrics;
    return 'Lyrics(stanzas: ${_this.stanzas}, chorus: ${_this.chorus})';
  }
}

/// @nodoc
abstract mixin class $LyricsCopyWith<$Res> {
  factory $LyricsCopyWith(Lyrics value, $Res Function(Lyrics) _then) =
      _$LyricsCopyWithImpl;
  @useResult
  $Res call({List<Stanza> stanzas, String? chorus});
}

/// @nodoc
class _$LyricsCopyWithImpl<$Res> implements $LyricsCopyWith<$Res> {
  _$LyricsCopyWithImpl(this._self, this._then);

  final Lyrics _self;
  final $Res Function(Lyrics) _then;

  /// Create a copy of Lyrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stanzas = null,
    Object? chorus = freezed,
  }) {
    return _then(Lyrics(
      stanzas: null == stanzas
          ? _self.stanzas
          : stanzas // ignore: cast_nullable_to_non_nullable
              as List<Stanza>,
      chorus: freezed == chorus
          ? _self.chorus
          : chorus // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Lyrics].
extension LyricsPatterns on Lyrics {
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
    TResult Function(_Lyrics value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Lyrics() when $default != null:
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
    TResult Function(_Lyrics value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Lyrics():
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
    TResult? Function(_Lyrics value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Lyrics() when $default != null:
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
    TResult Function(List<Stanza> stanzas, String? chorus)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Lyrics() when $default != null:
        return $default(_that.stanzas, _that.chorus);
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
    TResult Function(List<Stanza> stanzas, String? chorus) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Lyrics():
        return $default(_that.stanzas, _that.chorus);
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
    TResult? Function(List<Stanza> stanzas, String? chorus)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Lyrics() when $default != null:
        return $default(_that.stanzas, _that.chorus);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Lyrics implements Lyrics {
  const _Lyrics({required List<Stanza> stanzas, this.chorus})
      : _stanzas = stanzas;
  factory _Lyrics.fromJson(Map<String, dynamic> json) => _$LyricsFromJson(json);

  final List<Stanza> _stanzas;
  @override
  List<Stanza> get stanzas {
    if (_stanzas is EqualUnmodifiableListView) return _stanzas;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stanzas);
  }

  @override
  final String? chorus;

  /// Create a copy of Lyrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LyricsCopyWith<_Lyrics> get copyWith =>
      __$LyricsCopyWithImpl<_Lyrics>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$LyricsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Lyrics &&
            const DeepCollectionEquality().equals(other.stanzas, _stanzas) &&
            (identical(other.chorus, chorus) || other.chorus == chorus));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
        runtimeType, const DeepCollectionEquality().hash(_stanzas), chorus);
  }

  @override
  String toString() {
    return 'Lyrics(stanzas: $stanzas, chorus: $chorus)';
  }
}

/// @nodoc
abstract mixin class _$LyricsCopyWith<$Res> implements $LyricsCopyWith<$Res> {
  factory _$LyricsCopyWith(_Lyrics value, $Res Function(_Lyrics) _then) =
      __$LyricsCopyWithImpl;
  @override
  @useResult
  $Res call({List<Stanza> stanzas, String? chorus});
}

/// @nodoc
class __$LyricsCopyWithImpl<$Res> implements _$LyricsCopyWith<$Res> {
  __$LyricsCopyWithImpl(this._self, this._then);

  final _Lyrics _self;
  final $Res Function(_Lyrics) _then;

  /// Create a copy of Lyrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? stanzas = null,
    Object? chorus = freezed,
  }) {
    return _then(_Lyrics(
      stanzas: null == stanzas
          ? _self._stanzas
          : stanzas // ignore: cast_nullable_to_non_nullable
              as List<Stanza>,
      chorus: freezed == chorus
          ? _self.chorus
          : chorus // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
