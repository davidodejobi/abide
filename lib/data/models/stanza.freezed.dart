// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stanza.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Stanza _$StanzaFromJson(Map<String, dynamic> json) {
  return _Stanza.fromJson(json);
}

/// @nodoc
mixin _$Stanza {
  int get index => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;

  /// Serializes this Stanza to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Stanza
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StanzaCopyWith<Stanza> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StanzaCopyWith<$Res> {
  factory $StanzaCopyWith(Stanza value, $Res Function(Stanza) then) =
      _$StanzaCopyWithImpl<$Res, Stanza>;
  @useResult
  $Res call({int index, String text});
}

/// @nodoc
class _$StanzaCopyWithImpl<$Res, $Val extends Stanza>
    implements $StanzaCopyWith<$Res> {
  _$StanzaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Stanza
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? index = null,
    Object? text = null,
  }) {
    return _then(_value.copyWith(
      index: null == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
              as int,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StanzaImplCopyWith<$Res> implements $StanzaCopyWith<$Res> {
  factory _$$StanzaImplCopyWith(
          _$StanzaImpl value, $Res Function(_$StanzaImpl) then) =
      __$$StanzaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int index, String text});
}

/// @nodoc
class __$$StanzaImplCopyWithImpl<$Res>
    extends _$StanzaCopyWithImpl<$Res, _$StanzaImpl>
    implements _$$StanzaImplCopyWith<$Res> {
  __$$StanzaImplCopyWithImpl(
      _$StanzaImpl _value, $Res Function(_$StanzaImpl) _then)
      : super(_value, _then);

  /// Create a copy of Stanza
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? index = null,
    Object? text = null,
  }) {
    return _then(_$StanzaImpl(
      index: null == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
              as int,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StanzaImpl implements _Stanza {
  const _$StanzaImpl({required this.index, required this.text});

  factory _$StanzaImpl.fromJson(Map<String, dynamic> json) =>
      _$$StanzaImplFromJson(json);

  @override
  final int index;
  @override
  final String text;

  @override
  String toString() {
    return 'Stanza(index: $index, text: $text)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StanzaImpl &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.text, text) || other.text == text));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, index, text);

  /// Create a copy of Stanza
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StanzaImplCopyWith<_$StanzaImpl> get copyWith =>
      __$$StanzaImplCopyWithImpl<_$StanzaImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StanzaImplToJson(
      this,
    );
  }
}

abstract class _Stanza implements Stanza {
  const factory _Stanza(
      {required final int index, required final String text}) = _$StanzaImpl;

  factory _Stanza.fromJson(Map<String, dynamic> json) = _$StanzaImpl.fromJson;

  @override
  int get index;
  @override
  String get text;

  /// Create a copy of Stanza
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StanzaImplCopyWith<_$StanzaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
