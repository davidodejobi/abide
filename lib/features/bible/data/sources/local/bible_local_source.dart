import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:openbaptisthymnal/features/bible/domain/book_codes.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_chapter.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';

/// Reads bundled Bible assets from `assets/bible/<editionId>/`. Books are loaded
/// one file at a time and the most recently read book is cached, so paging
/// through chapters within a book never re-decodes JSON.
class BibleLocalSource {
  BibleLocalSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  String? _cachedKey; // "<editionId>/<ordinal>"
  Map<String, dynamic>? _cachedBook;

  Future<BibleManifest> loadManifest(String editionId) async {
    final raw = await _bundle.loadString('assets/bible/$editionId/manifest.json');
    return BibleManifest.fromJson(json.decode(raw) as Map<String, dynamic>);
  }

  /// Loads a single chapter for [editionId]. [ordinal] is the 1-based book
  /// ordinal; [chapter] is 1-based. Verses come back in canonical order.
  Future<BibleChapter> loadChapter(
    String editionId,
    int ordinal,
    int chapter,
  ) async {
    final book = await _loadBook(editionId, ordinal);
    final code = bookCodeForOrdinal(ordinal) ?? '?';
    final chapterMap = book['$chapter'] as Map<String, dynamic>?;
    final verses = <Verse>[];
    if (chapterMap != null) {
      for (final entry in chapterMap.entries) {
        final number = int.tryParse(entry.key);
        if (number == null) continue;
        verses.add(Verse(
          ref: VerseRef(code, chapter, number),
          text: entry.value as String,
        ));
      }
    }
    return BibleChapter(book: code, chapter: chapter, verses: verses);
  }

  Future<Map<String, dynamic>> _loadBook(String editionId, int ordinal) async {
    final key = '$editionId/$ordinal';
    if (_cachedKey == key && _cachedBook != null) return _cachedBook!;
    final raw = await _bundle.loadString('assets/bible/$editionId/$ordinal.json');
    final decoded = json.decode(raw) as Map<String, dynamic>;
    _cachedKey = key;
    _cachedBook = decoded;
    return decoded;
  }
}
