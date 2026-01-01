// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'language_pack.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LanguagePack _$LanguagePackFromJson(Map<String, dynamic> json) {
  return _LanguagePack.fromJson(json);
}

/// @nodoc
mixin _$LanguagePack {
  String get language => throw _privateConstructorUsedError;
  @JsonKey(name: 'hymnal_name')
  String get hymnalName => throw _privateConstructorUsedError;
  Map<String, HymnTranslation> get hymns => throw _privateConstructorUsedError;

  /// Serializes this LanguagePack to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LanguagePack
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LanguagePackCopyWith<LanguagePack> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LanguagePackCopyWith<$Res> {
  factory $LanguagePackCopyWith(
          LanguagePack value, $Res Function(LanguagePack) then) =
      _$LanguagePackCopyWithImpl<$Res, LanguagePack>;
  @useResult
  $Res call(
      {String language,
      @JsonKey(name: 'hymnal_name') String hymnalName,
      Map<String, HymnTranslation> hymns});
}

/// @nodoc
class _$LanguagePackCopyWithImpl<$Res, $Val extends LanguagePack>
    implements $LanguagePackCopyWith<$Res> {
  _$LanguagePackCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LanguagePack
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? language = null,
    Object? hymnalName = null,
    Object? hymns = null,
  }) {
    return _then(_value.copyWith(
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      hymnalName: null == hymnalName
          ? _value.hymnalName
          : hymnalName // ignore: cast_nullable_to_non_nullable
              as String,
      hymns: null == hymns
          ? _value.hymns
          : hymns // ignore: cast_nullable_to_non_nullable
              as Map<String, HymnTranslation>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LanguagePackImplCopyWith<$Res>
    implements $LanguagePackCopyWith<$Res> {
  factory _$$LanguagePackImplCopyWith(
          _$LanguagePackImpl value, $Res Function(_$LanguagePackImpl) then) =
      __$$LanguagePackImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String language,
      @JsonKey(name: 'hymnal_name') String hymnalName,
      Map<String, HymnTranslation> hymns});
}

/// @nodoc
class __$$LanguagePackImplCopyWithImpl<$Res>
    extends _$LanguagePackCopyWithImpl<$Res, _$LanguagePackImpl>
    implements _$$LanguagePackImplCopyWith<$Res> {
  __$$LanguagePackImplCopyWithImpl(
      _$LanguagePackImpl _value, $Res Function(_$LanguagePackImpl) _then)
      : super(_value, _then);

  /// Create a copy of LanguagePack
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? language = null,
    Object? hymnalName = null,
    Object? hymns = null,
  }) {
    return _then(_$LanguagePackImpl(
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      hymnalName: null == hymnalName
          ? _value.hymnalName
          : hymnalName // ignore: cast_nullable_to_non_nullable
              as String,
      hymns: null == hymns
          ? _value._hymns
          : hymns // ignore: cast_nullable_to_non_nullable
              as Map<String, HymnTranslation>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LanguagePackImpl implements _LanguagePack {
  const _$LanguagePackImpl(
      {required this.language,
      @JsonKey(name: 'hymnal_name') required this.hymnalName,
      required final Map<String, HymnTranslation> hymns})
      : _hymns = hymns;

  factory _$LanguagePackImpl.fromJson(Map<String, dynamic> json) =>
      _$$LanguagePackImplFromJson(json);

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

  @override
  String toString() {
    return 'LanguagePack(language: $language, hymnalName: $hymnalName, hymns: $hymns)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LanguagePackImpl &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.hymnalName, hymnalName) ||
                other.hymnalName == hymnalName) &&
            const DeepCollectionEquality().equals(other._hymns, _hymns));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, language, hymnalName,
      const DeepCollectionEquality().hash(_hymns));

  /// Create a copy of LanguagePack
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LanguagePackImplCopyWith<_$LanguagePackImpl> get copyWith =>
      __$$LanguagePackImplCopyWithImpl<_$LanguagePackImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LanguagePackImplToJson(
      this,
    );
  }
}

abstract class _LanguagePack implements LanguagePack {
  const factory _LanguagePack(
      {required final String language,
      @JsonKey(name: 'hymnal_name') required final String hymnalName,
      required final Map<String, HymnTranslation> hymns}) = _$LanguagePackImpl;

  factory _LanguagePack.fromJson(Map<String, dynamic> json) =
      _$LanguagePackImpl.fromJson;

  @override
  String get language;
  @override
  @JsonKey(name: 'hymnal_name')
  String get hymnalName;
  @override
  Map<String, HymnTranslation> get hymns;

  /// Create a copy of LanguagePack
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LanguagePackImplCopyWith<_$LanguagePackImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HymnTranslation _$HymnTranslationFromJson(Map<String, dynamic> json) {
  return _HymnTranslation.fromJson(json);
}

/// @nodoc
mixin _$HymnTranslation {
  int get number => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  Lyrics get lyrics => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false)
  String? get id => throw _privateConstructorUsedError;

  /// Serializes this HymnTranslation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HymnTranslation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HymnTranslationCopyWith<HymnTranslation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HymnTranslationCopyWith<$Res> {
  factory $HymnTranslationCopyWith(
          HymnTranslation value, $Res Function(HymnTranslation) then) =
      _$HymnTranslationCopyWithImpl<$Res, HymnTranslation>;
  @useResult
  $Res call(
      {int number,
      String title,
      Lyrics lyrics,
      @JsonKey(includeFromJson: false) String? id});

  $LyricsCopyWith<$Res> get lyrics;
}

/// @nodoc
class _$HymnTranslationCopyWithImpl<$Res, $Val extends HymnTranslation>
    implements $HymnTranslationCopyWith<$Res> {
  _$HymnTranslationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    return _then(_value.copyWith(
      number: null == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      lyrics: null == lyrics
          ? _value.lyrics
          : lyrics // ignore: cast_nullable_to_non_nullable
              as Lyrics,
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of HymnTranslation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LyricsCopyWith<$Res> get lyrics {
    return $LyricsCopyWith<$Res>(_value.lyrics, (value) {
      return _then(_value.copyWith(lyrics: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$HymnTranslationImplCopyWith<$Res>
    implements $HymnTranslationCopyWith<$Res> {
  factory _$$HymnTranslationImplCopyWith(_$HymnTranslationImpl value,
          $Res Function(_$HymnTranslationImpl) then) =
      __$$HymnTranslationImplCopyWithImpl<$Res>;
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
class __$$HymnTranslationImplCopyWithImpl<$Res>
    extends _$HymnTranslationCopyWithImpl<$Res, _$HymnTranslationImpl>
    implements _$$HymnTranslationImplCopyWith<$Res> {
  __$$HymnTranslationImplCopyWithImpl(
      _$HymnTranslationImpl _value, $Res Function(_$HymnTranslationImpl) _then)
      : super(_value, _then);

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
    return _then(_$HymnTranslationImpl(
      number: null == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      lyrics: null == lyrics
          ? _value.lyrics
          : lyrics // ignore: cast_nullable_to_non_nullable
              as Lyrics,
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HymnTranslationImpl implements _HymnTranslation {
  const _$HymnTranslationImpl(
      {required this.number,
      required this.title,
      required this.lyrics,
      @JsonKey(includeFromJson: false) this.id});

  factory _$HymnTranslationImpl.fromJson(Map<String, dynamic> json) =>
      _$$HymnTranslationImplFromJson(json);

  @override
  final int number;
  @override
  final String title;
  @override
  final Lyrics lyrics;
  @override
  @JsonKey(includeFromJson: false)
  final String? id;

  @override
  String toString() {
    return 'HymnTranslation(number: $number, title: $title, lyrics: $lyrics, id: $id)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HymnTranslationImpl &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.lyrics, lyrics) || other.lyrics == lyrics) &&
            (identical(other.id, id) || other.id == id));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, number, title, lyrics, id);

  /// Create a copy of HymnTranslation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HymnTranslationImplCopyWith<_$HymnTranslationImpl> get copyWith =>
      __$$HymnTranslationImplCopyWithImpl<_$HymnTranslationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HymnTranslationImplToJson(
      this,
    );
  }
}

abstract class _HymnTranslation implements HymnTranslation {
  const factory _HymnTranslation(
          {required final int number,
          required final String title,
          required final Lyrics lyrics,
          @JsonKey(includeFromJson: false) final String? id}) =
      _$HymnTranslationImpl;

  factory _HymnTranslation.fromJson(Map<String, dynamic> json) =
      _$HymnTranslationImpl.fromJson;

  @override
  int get number;
  @override
  String get title;
  @override
  Lyrics get lyrics;
  @override
  @JsonKey(includeFromJson: false)
  String? get id;

  /// Create a copy of HymnTranslation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HymnTranslationImplCopyWith<_$HymnTranslationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
