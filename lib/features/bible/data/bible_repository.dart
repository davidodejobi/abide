import 'package:openbaptisthymnal/features/bible/data/sources/local/bible_local_source.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_chapter.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';

/// Read-only access to Bible text, keyed by edition. The verse text is
/// immutable; highlights and verse notes live in the DB (added later).
/// [editionsOf] is the live bundled + downloaded list.
class BibleRepository {
  BibleRepository(this._local, {List<BibleEdition> Function()? editionsOf})
      : _editionsOf = editionsOf ?? (() => kBibleEditions);

  final BibleLocalSource _local;
  final List<BibleEdition> Function() _editionsOf;

  List<BibleEdition> editions() => _editionsOf();

  BibleEdition? editionById(String id) {
    for (final e in _editionsOf()) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<BibleManifest> manifest(String editionId) =>
      _local.loadManifest(editionId);

  Future<BibleChapter> chapter(
    String editionId,
    String bookCode,
    int chapter,
  ) =>
      _local.loadChapter(editionId, bookCode, chapter);
}
