// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'language_pack.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LanguagePack {
  String get language;
  @JsonKey(name: 'hymnal_name')
  String get hymnalName;
  Map<String, HymnTranslation> get hymns;

  /// Create a copy of LanguagePack
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LanguagePackCopyWith<LanguagePack> get copyWith =>
      _$LanguagePackCopyWithImpl<LanguagePack>(
          this as LanguagePack, _$identity);

  /// Serializes this LanguagePack to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as LanguagePack;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LanguagePack &&
            (identical(other.language, _this.language) ||
                other.language == _this.language) &&
            (identical(other.hymnalName, _this.hymnalName) ||
                other.hymnalName == _this.hymnalName) &&
            const DeepCollectionEquality().equals(other.hymns, _this.hymns));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as LanguagePack;
    return Object.hash(runtimeType, _this.language, _this.hymnalName,
        const DeepCollectionEquality().hash(_this.hymns));
  }

  @override
  String toString() {
    final _this = this as LanguagePack;
    return 'LanguagePack(language: ${_this.language}, hymnalName: ${_this.hymnalName}, hymns: ${_this.hymns})';
  }
}

/// @nodoc
abstract mixin class $LanguagePackCopyWith<$Res> {
  factory $LanguagePackCopyWith(
          LanguagePack value, $Res Function(LanguagePack) _then) =
      _$LanguagePackCopyWithImpl;
  @useResult
  $Res call(
      {String language,
      @JsonKey(name: 'hymnal_name') String hymnalName,
      Map<String, HymnTranslation> hymns});
}

/// @nodoc
class _$LanguagePackCopyWithImpl<$Res> implements $LanguagePackCopyWith<$Res> {
  _$LanguagePackCopyWithImpl(this._self, this._then);

  final LanguagePack _self;
  final $Res Function(LanguagePack) _then;

  /// Create a copy of LanguagePack
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? language = null,
    Object? hymnalName = null,
    Object? hymns = null,
  }) {
    return _then(LanguagePack(
      language: null == language
          ? _self.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      hymnalName: null == hymnalName
          ? _self.hymnalName
          : hymnalName // ignore: cast_nullable_to_non_nullable
              as String,
      hymns: null == hymns
          ? _self.hymns
          : hymns // ignore: cast_nullable_to_non_nullable
              as Map<String, HymnTranslation>,
    ));
  }
}

/// Adds pattern-matching-related methods to [LanguagePack].
extension LanguagePackPatterns on LanguagePack {
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
    TResult Function(_LanguagePack value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LanguagePack() when $default != null:
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
    TResult Function(_LanguagePack value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LanguagePack():
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
    TResult? Function(_LanguagePack value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LanguagePack() when $default != null:
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
            String language,
            @JsonKey(name: 'hymnal_name') String hymnalName,
            Map<String, HymnTranslation> hymns)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LanguagePack() when $default != null:
        return $default(_that.language, _that.hymnalName, _that.hymns);
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
            String language,
            @JsonKey(name: 'hymnal_name') String hymnalName,
            Map<String, HymnTranslation> hymns)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LanguagePack():
        return $default(_that.language, _that.hymnalName, _that.hymns);
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
            String language,
            @JsonKey(name: 'hymnal_name') String hymnalName,
            Map<String, HymnTranslation> hymns)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LanguagePack() when $default != null:
        return $default(_that.language, _that.hymnalName, _that.hymns);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _LanguagePack implements LanguagePack {
  const _LanguagePack(
      {required this.language,
      @JsonKey(name: 'hymnal_name') required this.hymnalName,
      required Map<String, HymnTranslation> hymns})
      : _hymns = hymns;
  factory _LanguagePack.fromJson(Map<String, dynamic> json) =>
      _$LanguagePackFromJson(json);

  @override
  final String language;
  @override
  @JsonKey(name: 'hymnal_name')
  final String hymnalName;
  final Map<String, HymnTranslation> _hymns;
  @override
  Map<String, HymnTranslation> get hymns {
    if (_hymns is EqualUnmodifiableMapView) return _hymns;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_hymns);
  }

  /// Create a copy of LanguagePack
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LanguagePackCopyWith<_LanguagePack> get copyWith =>
      __$LanguagePackCopyWithImpl<_LanguagePack>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$LanguagePackToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LanguagePack &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.hymnalName, hymnalName) ||
                other.hymnalName == hymnalName) &&
            const DeepCollectionEquality().equals(other.hymns, _hymns));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, language, hymnalName,
        const DeepCollectionEquality().hash(_hymns));
  }

  @override
  String toString() {
    return 'LanguagePack(language: $language, hymnalName: $hymnalName, hymns: $hymns)';
  }
}

/// @nodoc
abstract mixin class _$LanguagePackCopyWith<$Res>
    implements $LanguagePackCopyWith<$Res> {
  factory _$LanguagePackCopyWith(
          _LanguagePack value, $Res Function(_LanguagePack) _then) =
      __$LanguagePackCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String language,
      @JsonKey(name: 'hymnal_name') String hymnalName,
      Map<String, HymnTranslation> hymns});
}

/// @nodoc
class __$LanguagePackCopyWithImpl<$Res>
    implements _$LanguagePackCopyWith<$Res> {
  __$LanguagePackCopyWithImpl(this._self, this._then);

  final _LanguagePack _self;
  final $Res Function(_LanguagePack) _then;

  /// Create a copy of LanguagePack
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? language = null,
    Object? hymnalName = null,
    Object? hymns = null,
  }) {
    return _then(_LanguagePack(
      language: null == language
          ? _self.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      hymnalName: null == hymnalName
          ? _self.hymnalName
          : hymnalName // ignore: cast_nullable_to_non_nullable
              as String,
      hymns: null == hymns
          ? _self._hymns
          : hymns // ignore: cast_nullable_to_non_nullable
              as Map<String, HymnTranslation>,
    ));
  }
}

/// @nodoc
mixin _$HymnTranslation {
  int get number;
  String get title;
  Lyrics get lyrics;
  @JsonKey(includeFromJson: false)
  String? get id;

  /// Create a copy of HymnTranslation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HymnTranslationCopyWith<HymnTranslation> get copyWith =>
      _$HymnTranslationCopyWithImpl<HymnTranslation>(
          this as HymnTranslation, _$identity);

  /// Serializes this HymnTranslation to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as HymnTranslation;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HymnTranslation &&
            (identical(other.number, _this.number) ||
                other.number == _this.number) &&
            (identical(other.title, _this.title) ||
                other.title == _this.title) &&
            (identical(other.lyrics, _this.lyrics) ||
                other.lyrics == _this.lyrics) &&
            (identical(other.id, _this.id) || other.id == _this.id));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as HymnTranslation;
    return Object.hash(
        runtimeType, _this.number, _this.title, _this.lyrics, _this.id);
  }

  @override
  String toString() {
    final _this = this as HymnTranslation;
    return 'HymnTranslation(number: ${_this.number}, title: ${_this.title}, lyrics: ${_this.lyrics}, id: ${_this.id})';
  }
}

/// @nodoc
abstract mixin class $HymnTranslationCopyWith<$Res> {
  factory $HymnTranslationCopyWith(
          HymnTranslation value, $Res Function(HymnTranslation) _then) =
      _$HymnTranslationCopyWithImpl;
  @useResult
  $Res call(
      {int number,
      String title,
      Lyrics lyrics,
      @JsonKey(includeFromJson: false) String? id});

  $LyricsCopyWith<$Res> get lyrics;
}

/// @nodoc
class _$HymnTranslationCopyWithImpl<$Res>
    implements $HymnTranslationCopyWith<$Res> {
  _$HymnTranslationCopyWithImpl(this._self, this._then);

  final HymnTranslation _self;
  final $Res Function(HymnTranslation) _then;

  /// Create a copy of HymnTranslation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? number = null,
    Object? title = null,
    Object? lyrics = null,
    Object? id = freezed,
  }) {
    return _then(HymnTranslation(
      number: null == number
          ? _self.number
          : number // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      lyrics: null == lyrics
          ? _self.lyrics
          : lyrics // ignore: cast_nullable_to_non_nullable
              as Lyrics,
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of HymnTranslation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LyricsCopyWith<$Res> get lyrics {
    return $LyricsCopyWith<$Res>(_self.lyrics, (value) {
      return _then(_self.copyWith(lyrics: value));
    });
  }
}

/// Adds pattern-matching-related methods to [HymnTranslation].
extension HymnTranslationPatterns on HymnTranslation {
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
    TResult Function(_HymnTranslation value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HymnTranslation() when $default != null:
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
    TResult Function(_HymnTranslation value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HymnTranslation():
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
    TResult? Function(_HymnTranslation value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HymnTranslation() when $default != null:
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
    TResult Function(int number, String title, Lyrics lyrics,
            @JsonKey(includeFromJson: false) String? id)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HymnTranslation() when $default != null:
        return $default(_that.number, _that.title, _that.lyrics, _that.id);
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
    TResult Function(int number, String title, Lyrics lyrics,
            @JsonKey(includeFromJson: false) String? id)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HymnTranslation():
        return $default(_that.number, _that.title, _that.lyrics, _that.id);
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
    TResult? Function(int number, String title, Lyrics lyrics,
            @JsonKey(includeFromJson: false) String? id)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HymnTranslation() when $default != null:
        return $default(_that.number, _that.title, _that.lyrics, _that.id);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _HymnTranslation implements HymnTranslation {
  const _HymnTranslation(
      {required this.number,
      required this.title,
      required this.lyrics,
      @JsonKey(includeFromJson: false) this.id});
  factory _HymnTranslation.fromJson(Map<String, dynamic> json) =>
      _$HymnTranslationFromJson(json);

  @override
  final int number;
  @override
  final String title;
  @override
  final Lyrics lyrics;
  @override
  @JsonKey(includeFromJson: false)
  final String? id;

  /// Create a copy of HymnTranslation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HymnTranslationCopyWith<_HymnTranslation> get copyWith =>
      __$HymnTranslationCopyWithImpl<_HymnTranslation>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$HymnTranslationToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HymnTranslation &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.lyrics, lyrics) || other.lyrics == lyrics) &&
            (identical(other.id, id) || other.id == id));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, number, title, lyrics, id);
  }

  @override
  String toString() {
    return 'HymnTranslation(number: $number, title: $title, lyrics: $lyrics, id: $id)';
  }
}

/// @nodoc
abstract mixin class _$HymnTranslationCopyWith<$Res>
    implements $HymnTranslationCopyWith<$Res> {
  factory _$HymnTranslationCopyWith(
          _HymnTranslation value, $Res Function(_HymnTranslation) _then) =
      __$HymnTranslationCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int number,
      String title,
      Lyrics lyrics,
      @JsonKey(includeFromJson: false) String? id});

  @override
  $LyricsCopyWith<$Res> get lyrics;
}

/// @nodoc
class __$HymnTranslationCopyWithImpl<$Res>
    implements _$HymnTranslationCopyWith<$Res> {
  __$HymnTranslationCopyWithImpl(this._self, this._then);

  final _HymnTranslation _self;
  final $Res Function(_HymnTranslation) _then;

  /// Create a copy of HymnTranslation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? number = null,
    Object? title = null,
    Object? lyrics = null,
    Object? id = freezed,
  }) {
    return _then(_HymnTranslation(
      number: null == number
          ? _self.number
          : number // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      lyrics: null == lyrics
          ? _self.lyrics
          : lyrics // ignore: cast_nullable_to_non_nullable
              as Lyrics,
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of HymnTranslation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LyricsCopyWith<$Res> get lyrics {
    return $LyricsCopyWith<$Res>(_self.lyrics, (value) {
      return _then(_self.copyWith(lyrics: value));
    });
  }
}

// dart format on
