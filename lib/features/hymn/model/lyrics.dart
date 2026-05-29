import 'package:freezed_annotation/freezed_annotation.dart';

import 'stanza.dart';

part 'lyrics.freezed.dart';
part 'lyrics.g.dart';

@freezed
class Lyrics with _$Lyrics {
  const factory Lyrics({
    required List<Stanza> stanzas,
    String? chorus,
  }) = _Lyrics;

  factory Lyrics.fromJson(Map<String, dynamic> json) => _$LyricsFromJson(json);
}
