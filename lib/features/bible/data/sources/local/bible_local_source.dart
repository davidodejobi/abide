import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:openbaptisthymnal/features/bible/data/sources/local/installed_bible_store.dart';
import 'package:openbaptisthymnal/features/bible/domain/verse_ref.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_chapter.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';

/// Reads Bible text for an edition: downloaded editions from the
/// [InstalledBibleStore], bundled ones from `assets/bible/<editionId>/`. Books are keyed
/// by their USFM code (`books/<CODE>.json`) and loaded one file at a time; the
/// most recently read book is cached, so paging through chapters within a book
/// never re-decodes JSON.
class BibleLocalSource {
  BibleLocalSource({AssetBundle? bundle, InstalledBibleStore? installed})
      : _bundle = bundle ?? rootBundle,
        _installed = installed ?? const NoopInstalledBibleStore();

  final AssetBundle _bundle;
  final InstalledBibleStore _installed;

  String? _cachedKey; // "<editionId>/<bookCode>"
  Map<String, dynamic>? _cachedBook;

  Future<String> _read(String editionId, String relativePath) async =>
      await _installed.readString(editionId, relativePath) ??
      await _bundle.loadString('assets/bible/$editionId/$relativePath');

  Future<BibleManifest> loadManifest(String editionId) async {
    final raw = await _read(editionId, 'manifest.json');
    return BibleManifest.fromJson(json.decode(raw) as Map<String, dynamic>);
  }

  /// Loads a single chapter for [editionId]. [bookCode] is the USFM code
  /// (e.g. `JHN`); [chapter] is 1-based. Verses come back in canonical order.
  Future<BibleChapter> loadChapter(
    String editionId,
    String bookCode,
    int chapter,
  ) async {
    final book = await _loadBook(editionId, bookCode);
    final chapterMap = book['$chapter'] as Map<String, dynamic>?;
    final verses = <Verse>[];
    if (chapterMap != null) {
      for (final entry in chapterMap.entries) {
        final number = int.tryParse(entry.key);
        if (number == null) continue;
        verses.add(Verse(
          ref: VerseRef(bookCode, chapter, number),
          text: entry.value as String,
        ));
      }
    }
    return BibleChapter(book: bookCode, chapter: chapter, verses: verses);
  }

  Future<Map<String, dynamic>> _loadBook(
    String editionId,
    String bookCode,
  ) async {
    final key = '$editionId/$bookCode';
    if (_cachedKey == key && _cachedBook != null) return _cachedBook!;
    final raw = await _read(editionId, 'books/$bookCode.json');
    final decoded = json.decode(raw) as Map<String, dynamic>;
    _cachedKey = key;
    _cachedBook = decoded;
    return decoded;
  }
}
