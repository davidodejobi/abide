import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/features/tablet/data/repositories/templates_repository.dart';
import 'package:openbaptisthymnal/features/tablet/domain/builtin_templates.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_template.dart';

void main() {
  late AppDatabase db;
  late TemplatesRepository repo;
  var tick = 0;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tick = 0;
    repo = TemplatesRepository(db.noteTemplatesDao,
        clock: () => DateTime.utc(2026, 11, 26, 9, 0, tick++));
  });
  tearDown(() => db.close());

  const sections = [
    TemplateSection(TemplateSectionType.field, 'Speaker'),
    TemplateSection(TemplateSectionType.bullet, 'Main points', hint: 'Why?'),
  ];

  test('Given a new template, it is saved, listed and keeps its sections',
      () async {
    final id = await repo.save(name: ' Sunday sermon ', icon: 'church', sections: sections);
    final mine = await repo.watchMine().first;
    expect(mine, hasLength(1));
    expect(mine.single.id, id);
    expect(mine.single.name, 'Sunday sermon');
    expect(mine.single.icon, 'church');
    expect(mine.single.sections, sections);
    expect(mine.single.builtIn, isFalse);
  });

  test('Given an edit, the same row changes and its created date is kept',
      () async {
    final id = await repo.save(name: 'One', icon: 'book', sections: sections);
    final before = await db.select(db.noteTemplates).getSingle();
    await repo.save(id: id, name: 'Two', icon: 'heart', sections: const []);
    final row = await db.select(db.noteTemplates).getSingle();
    expect(row.name, 'Two');
    expect(row.icon, 'heart');
    expect(decodeSections(row.sectionsJson), isEmpty);
    expect(row.createdAt, before.createdAt);
    expect(row.updatedAt.isAfter(before.updatedAt), isTrue);
  });

  test('Given a delete, the template disappears and undo brings it back',
      () async {
    final id = await repo.save(name: 'Gone', icon: 'book', sections: sections);
    await repo.delete(id);
    expect(await repo.watchMine().first, isEmpty);
    await repo.restore(id);
    expect((await repo.watchMine().first).single.name, 'Gone');
  });

  test('Given a built-in, duplicating makes an independent Mine copy',
      () async {
    final id = await repo.duplicate(sermonTemplate, 'Sermon copy');
    final copy = (await repo.watchMine().first).single;
    expect(copy.id, id);
    expect(copy.id, isNot(sermonTemplate.id));
    expect(copy.name, 'Sermon copy');
    expect(copy.sections, sermonTemplate.sections);
    expect(copy.builtIn, isFalse);
  });

  test('Given a template, notes made from it are not touched by its deletion',
      () async {
    final id = await repo.save(name: 'T', icon: 'book', sections: sections);
    await db.into(db.notes).insert(NotesCompanion.insert(
          id: 'n1',
          title: const Value('From template'),
          contentMarkdown: const Value('## Main points'),
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ));
    await repo.delete(id);
    final note = await db.select(db.notes).getSingle();
    expect(note.contentMarkdown, '## Main points');
  });

  test('Given a template save, nothing is queued for sync', () async {
    await db.customStatement(
        "INSERT INTO sync_state(key, value) VALUES ('sync_enabled', '1')");
    await repo.save(name: 'Local only', icon: 'book', sections: sections);
    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });
}
