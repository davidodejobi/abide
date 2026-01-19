import 'package:freezed_annotation/freezed_annotation.dart';

part 'hymn.freezed.dart';
part 'hymn.g.dart';

@freezed
class Hymn with _$Hymn {
  const factory Hymn({
    required String category,
  }) = _Hymn;

  factory Hymn.fromJson(Map<String, dynamic> json) => _$HymnFromJson(json);
}
