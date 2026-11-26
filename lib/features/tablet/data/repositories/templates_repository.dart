import 'package:drift/drift.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart' as db;
import 'package:openbaptisthymnal/core/storage/database/daos/note_templates_dao.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_template.dart';
import 'package:uuid/uuid.dart';

/// The user's own templates ("Mine"). Built-ins are const data and never pass
/// through here. Local-only: nothing here is queued for sync.
class TemplatesRepository {
  TemplatesRepository(this._dao, {Uuid? uuid, DateTime Function()? clock})
      : _uuid = uuid ?? const Uuid(),
        _now = clock ?? DateTime.now;

  final NoteTemplatesDao _dao;
  final Uuid _uuid;
  final DateTime Function() _now;

  Stream<List<NoteTemplate>> watchMine() =>
      _dao.watchTemplates().map((rows) => rows.map(_fromRow).toList());

  /// Creates a template, or updates it when [id] names an existing one.
  /// Returns the id.
  Future<String> save({
    String? id,
    required String name,
    required String icon,
    required List<TemplateSection> sections,
  }) async {
    final now = _now();
    final tid = id ?? _uuid.v4();
    final sectionsJson = encodeSections(sections);
    if (id == null) {
      await _dao.upsertTemplate(db.NoteTemplatesCompanion.insert(
        id: tid,
        name: name.trim(),
        icon: icon,
        sectionsJson: sectionsJson,
        createdAt: now,
        updatedAt: now,
      ));
    } else {
      await _dao.updateTemplate(
        tid,
        db.NoteTemplatesCompanion(
          name: Value(name.trim()),
          icon: Value(icon),
          sectionsJson: Value(sectionsJson),
          updatedAt: Value(now),
        ),
      );
    }
    return tid;
  }

  Future<String> duplicate(NoteTemplate source, String copyName) => save(
        name: copyName,
        icon: source.icon,
        sections: source.sections,
      );

  Future<void> delete(String id) => _dao.setDeleted(id, true);

  Future<void> restore(String id) => _dao.setDeleted(id, false);

  NoteTemplate _fromRow(db.NoteTemplateRow r) => NoteTemplate(
        id: r.id,
        name: r.name,
        icon: r.icon,
        sections: decodeSections(r.sectionsJson),
      );
}
