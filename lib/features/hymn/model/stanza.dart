import 'package:freezed_annotation/freezed_annotation.dart';

part 'stanza.freezed.dart';
part 'stanza.g.dart';

@freezed
class Stanza with _$Stanza {
  const factory Stanza({
    required int index,
    required String text,
  }) = _Stanza;

  factory Stanza.fromJson(Map<String, dynamic> json) => _$StanzaFromJson(json);
}
