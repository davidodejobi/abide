import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'bible_annotations_dao.g.dart';

/// Persistence for user Bible annotations (highlights today; bookmarks/underline
/// later). Annotations are edition-independent: [BibleAnnotations.verseRef] is a
/// bare USFM verse key (`JHN.3.16`) with no edition, so a highlight set while
/// reading KJV also shows in BSB, ASV, YLT or any future translation.
@DriftAccessor(tables: [BibleAnnotations])
class BibleAnnotationsDao extends DatabaseAccessor<AppDatabase>
    with _$BibleAnnotationsDaoMixin {
  BibleAnnotationsDao(super.db);

  /// Deterministic row id for a verse's highlight, so re-coloring updates the
  /// same row instead of accumulating duplicates, and the eraser is a delete by
  /// id. Namespacing by kind leaves room for a separate bookmark row per verse.
  String _highlightId(String verseRef) => 'highlight:$verseRef';

  /// Active annotations whose verse falls in this chapter. Coarse prefix filter;
  /// the provider confirms the exact chapter. The trailing `.` in the prefix
  /// stops `JHN.3.` from also matching `JHN.30.x`.
  Stream<List<BibleAnnotation>> watchAnnotationsForChapter(
    String bookCode,
    int chapter,
  ) {
    final prefix = '$bookCode.$chapter.';
    return (select(bibleAnnotations)
          ..where((t) =>
              t.isDeleted.equals(false) & t.verseRef.like('$prefix%')))
        .watch();
  }

  /// Sets (or recolors) the highlight on a single verse.
  Future<void> setHighlight(String verseRef, String colorKey) {
    return into(bibleAnnotations).insertOnConflictUpdate(
      BibleAnnotationsCompanion.insert(
        id: _highlightId(verseRef),
        verseRef: verseRef,
        kind: 'highlight',
        color: Value(colorKey),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Removes the highlight on a single verse, if any.
  Future<void> removeHighlight(String verseRef) {
    return (delete(bibleAnnotations)
          ..where((t) => t.id.equals(_highlightId(verseRef))))
        .go();
  }
}
