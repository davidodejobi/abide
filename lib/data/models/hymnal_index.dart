import 'package:freezed_annotation/freezed_annotation.dart';

part 'hymnal_index.freezed.dart';
part 'hymnal_index.g.dart';

@freezed
class HymnalIndex with _$HymnalIndex {
  const factory HymnalIndex({
    required Map<String, List<String>> orders,
  }) = _HymnalIndex;

  factory HymnalIndex.fromJson(Map<String, dynamic> json) =>
      _$HymnalIndexFromJson(json);
}
