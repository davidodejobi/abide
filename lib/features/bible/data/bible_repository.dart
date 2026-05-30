import 'package:openbaptisthymnal/features/bible/data/sources/local/bible_local_source.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_chapter.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_edition.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';

/// Read-only access to bundled Bible text, keyed by edition. The verse text is
/// immutable; highlights and verse notes live in the DB (added later).
class BibleRepository {
  BibleRepository(this._local);

  final BibleLocalSource _local;

  List<BibleEdition> editions() => kBibleEditions;

  BibleEdition? editionById(String id) {
    for (final e in kBibleEditions) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<BibleManifest> manifest(String editionId) =>
      _local.loadManifest(editionId);

  Future<BibleChapter> chapter(String editionId, int ordinal, int chapter) =>
      _local.loadChapter(editionId, ordinal, chapter);
}
