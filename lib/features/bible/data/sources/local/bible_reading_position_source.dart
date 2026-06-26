import 'dart:convert';

import 'package:openbaptisthymnal/features/bible/domain/book_codes.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The last place the reader left off: which edition, book, and chapter. Stored
/// as one JSON blob so a single read/write keeps the three fields in sync.
class ReadingPosition {
  const ReadingPosition({
    required this.editionId,
    required this.bookCode,
    required this.chapter,
  });

  final String editionId;
  final String bookCode;
  final int chapter;

  ReadingPosition copyWith({String? editionId, String? bookCode, int? chapter}) {
    return ReadingPosition(
      editionId: editionId ?? this.editionId,
      bookCode: bookCode ?? this.bookCode,
      chapter: chapter ?? this.chapter,
    );
  }

  Map<String, dynamic> toJson() =>
      {'edition': editionId, 'bookCode': bookCode, 'chapter': chapter};

  /// Accepts both the current `bookCode` shape and the legacy `ordinal` shape so
  /// a persisted position written before the bookCode migration still loads.
  factory ReadingPosition.fromJson(Map<String, dynamic> json) {
    final String bookCode;
    if (json.containsKey('bookCode')) {
      bookCode = json['bookCode'] as String;
    } else {
      final code = bookCodeForOrdinal(json['ordinal'] as int);
      if (code == null) {
        throw const FormatException('legacy ReadingPosition: invalid ordinal');
      }
      bookCode = code;
    }
    return ReadingPosition(
      editionId: json['edition'] as String,
      bookCode: bookCode,
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
