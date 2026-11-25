import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/folders_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/note_links_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/tags_dao.dart';
import 'package:openbaptisthymnal/features/tablet/data/repositories/tablets_repository.dart';
import 'package:openbaptisthymnal/features/tablet/data/sources/local/tablets_local_source.dart';
import 'package:openbaptisthymnal/features/tablet/providers/tablets_providers.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';
import 'package:openbaptisthymnal/features/tablet/ui/tablets_tab_screen.dart';

import '../../../support/reader_harness.dart' show appFor, setView, settle;

Note _note(String id, String title, String body) => Note(
      id: id,
      title: title,
      contentMarkdown: body,
      createdAt: DateTime(2026, 11, 25, 6, 40),
      updatedAt: DateTime.now(),
      isDeleted: false,
    );

List<Override> _overrides(List<Note> notes) => [
      tabletsListProvider.overrideWith((ref) => Stream.value(notes)),
      tagsProvider.overrideWith((ref) => Stream.value(const [])),
      foldersProvider.overrideWith((ref) => Stream.value(const [])),
      tagsForNoteProvider.overrideWith((ref, id) => Stream.value(const [])),
    ];

/// Records delete and restore, and keeps the on-screen list in step.
class _FakeRepo extends TabletsRepository {
  _FakeRepo(super.local, this.list, this.out);

  final List<Note> list;
  final StreamController<List<Note>> out;
  final calls = <String>[];

  @override
  Future<void> deleteNote(String id) async {
    calls.add('delete $id');
    list.removeWhere((n) => n.id == id);
    out.add(List.of(list));
  }

  @override
  Future<void> restoreNote(String id) async => calls.add('restore $id');
}

void main() {
  const sizes = [
    ('390x844', Size(390, 844), 1.0),
    ('320 wide at 2x text', Size(320, 700), 2.0),
    ('landscape 844x390', Size(844, 390), 1.0),
  ];

  const screen = Scaffold(body: SafeArea(child: TabletsTabScreen()));

  for (final (name, size, scale) in sizes) {
    testWidgets('lists note cards with previews, $name', (t) async {
      setView(t, size);
      await t.pumpWidget(appFor(
        _overrides([
          _note('a', 'Abiding, not striving', 'Fruit comes from staying.'),
          _note('b', '', 'Mum health. Exams for Kemi.'),
        ]),
        screen,
        scale: scale,
      ));
      await settle(t);
      expect(find.text(NotesStrings.notes), findsOneWidget);
      expect(find.text(NotesStrings.count(2)), findsOneWidget);
      await t.dragUntilVisible(find.text('Abiding, not striving'),
          find.byType(CustomScrollView), const Offset(0, -200));
      expect(find.byType(NoteCard), findsWidgets);
      expect(t.takeException(), isNull);
    });

    testWidgets('shows the empty state with one clear action, $name',
        (t) async {
      setView(t, size);
      await t.pumpWidget(appFor(_overrides(const []), screen,
          theme: AppTheme.darkTheme, scale: scale));
      await settle(t);
      expect(find.text(NotesStrings.noNotesYet), findsOneWidget);
      for (final text in [
        NotesStrings.emptyTitle,
        NotesStrings.writeNote,
        NotesStrings.freeAndLocal,
      ]) {
        await t.dragUntilVisible(find.text(text), find.byType(CustomScrollView),
            const Offset(0, -100));
        expect(find.text(text), findsOneWidget);
      }
      // No search box until there is something to search.
      expect(find.byType(TextField), findsNothing);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('new note button is labelled for screen readers', (t) async {
    setView(t, const Size(390, 844));
    final semantics = t.ensureSemantics();
    try {
      await t.pumpWidget(appFor(_overrides(const []), screen));
      await settle(t);
      expect(find.bySemanticsLabel(NotesStrings.newNote), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('swipe delete offers undo that restores the note', (t) async {
    setView(t, const Size(390, 844));
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final list = [_note('a', 'Abiding', 'Fruit.'), _note('b', 'Prayer', 'x')];
    final out = StreamController<List<Note>>.broadcast();
    addTearDown(out.close);
    final repo = _FakeRepo(
        TabletsLocalSource(
            NotesDao(db), NoteLinksDao(db), FoldersDao(db), TagsDao(db)),
        list,
        out);
    Stream<List<Note>> feed() async* {
      yield List.of(list);
      yield* out.stream;
    }

    await t.pumpWidget(appFor([
      ..._overrides(const []),
      tabletsListProvider.overrideWith((ref) => feed()),
      tabletsRepositoryProvider.overrideWithValue(repo),
    ], screen));
    await settle(t);

    await t.drag(find.text('Abiding'), const Offset(-500, 0));
    await settle(t);
    expect(repo.calls, ['delete a']);
    expect(find.text(NotesStrings.noteDeleted), findsOneWidget);

    await t.pump(const Duration(seconds: 1));
    await t.tap(find.text(NotesStrings.undo));
    await settle(t);
    expect(repo.calls, ['delete a', 'restore a']);
  });
}
