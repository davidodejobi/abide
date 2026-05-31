import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The last place the reader left off: which edition, book, and chapter. Stored
/// as one JSON blob so a single read/write keeps the three fields in sync.
class ReadingPosition {
  const ReadingPosition({
    required this.editionId,
    required this.ordinal,
    required this.chapter,
  });

  final String editionId;
  final int ordinal;
  final int chapter;

  ReadingPosition copyWith({String? editionId, int? ordinal, int? chapter}) {
    return ReadingPosition(
      editionId: editionId ?? this.editionId,
      ordinal: ordinal ?? this.ordinal,
      chapter: chapter ?? this.chapter,
    );
  }

  Map<String, dynamic> toJson() =>
      {'edition': editionId, 'ordinal': ordinal, 'chapter': chapter};

  factory ReadingPosition.fromJson(Map<String, dynamic> json) {
    return ReadingPosition(
      editionId: json['edition'] as String,
      ordinal: json['ordinal'] as int,
      chapter: json['chapter'] as int,
    );
  }
}

class BibleReadingPositionSource {
  BibleReadingPositionSource(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'bible_reading_position';

  ReadingPosition? read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    return ReadingPosition.fromJson(json.decode(raw) as Map<String, dynamic>);
  }

  Future<void> write(ReadingPosition position) async {
    await _prefs.setString(_key, json.encode(position.toJson()));
  }
}
