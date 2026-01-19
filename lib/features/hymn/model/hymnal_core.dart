import 'package:freezed_annotation/freezed_annotation.dart';

import 'hymn.dart';

part 'hymnal_core.freezed.dart';
part 'hymnal_core.g.dart';

// ignore_for_file: invalid_annotation_target
@freezed
class HymnalCore with _$HymnalCore {
  const factory HymnalCore({
    @JsonKey(name: 'schema_version') required String schemaVersion,
    @JsonKey(name: 'hymnal_id') required String hymnalId,
    required Map<String, Hymn> hymns,
  }) = _HymnalCore;

  factory HymnalCore.fromJson(Map<String, dynamic> json) =>
      _$HymnalCoreFromJson(json);
}
