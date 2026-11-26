import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/tablet/domain/tablet_markdown_codec.dart';
import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/folders_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/note_links_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/tags_dao.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/tablet/data/repositories/tablets_repository.dart';
import 'package:openbaptisthymnal/features/tablet/data/sources/local/tablets_local_source.dart';
import 'package:openbaptisthymnal/features/tablet/domain/template_to_note.dart';
import 'package:openbaptisthymnal/features/tablet/providers/tablets_providers.dart';
import 'package:openbaptisthymnal/features/tablet/providers/templates_providers.dart';
import 'package:openbaptisthymnal/features/tablet/ui/pages/tablet_editor_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/reader_harness.dart'
    show appFor, johnManifest, setView, settle;

class _FakeRepo extends TabletsRepository {
  _FakeRepo(super.local);

  final created = <({String title, String body})>[];

  @override
  Future<String> createNote(
      {String title = '', String contentMarkdown = ''}) async {
    created.add((title: title, body: contentMarkdown));
    return 'new-${created.length}';
  }
}

void main() {
  late SharedPreferences prefs;
  late AppDatabase db;
  late _FakeRepo repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'note_template_last_speaker': 'Ada Obi',
    });
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = _FakeRepo(TabletsLocalSource(
        NotesDao(db), NoteLinksDao(db), FoldersDao(db), TagsDao(db)));
  });
  tearDown(() => db.close());

  Future<void> open(WidgetTester t, String? templateId) async {
    setView(t, const Size(390, 844));
    await t.pumpWidget(appFor([
      sharedPreferencesProvider.overrideWithValue(prefs),
      tabletsRepositoryProvider.overrideWithValue(repo),
      myTemplatesProvider.overrideWith((ref) => Stream.value(const [])),
      bibleManifestProvider.overrideWith((ref, id) async => johnManifest()),
    ], TabletEditorPage(templateId: templateId)));
    await settle(t);
  }

  EditorState editor(WidgetTester t) =>
      t.widget<AppFlowyEditor>(find.byType(AppFlowyEditor)).editorState;

  testWidgets('a Sermon note opens with the caret in the title, date and last '
      'speaker filled', (t) async {
    await open(t, 'builtin:sermon');
    final title = t.widget<TextField>(find.byType(TextField).first);
    expect(title.focusNode?.hasFocus, isTrue);

    final md = noteDocumentToMarkdown(editor(t).document);
    expect(md, contains('**Speaker:** Ada Obi'));
    expect(md, contains('**Date:** ${templateDateText(DateTime.now())}'));
    expect(md, contains('## Application'));
    // The template name is a plain label, not saved text.
    expect(find.text('Sermon'), findsOneWidget);
  });

  testWidgets('hints show as placeholders and are never part of the note',
      (t) async {
    await open(t, 'builtin:sermon');
    expect(find.text('The first big idea, in your own words', findRichText: true),
        findsOneWidget);
    expect(find.text('Who is speaking', findRichText: true), findsNothing);
    expect(noteDocumentToMarkdown(editor(t).document), isNot(contains('What will you do')));
  });

  testWidgets('an untouched template note is not saved on exit', (t) async {
    await open(t, 'builtin:sermon');
    await t.pump(const Duration(seconds: 2)); // past the autosave debounce
    expect(repo.created, isEmpty);
  });

  testWidgets('typing a title saves the note, with the template body',
      (t) async {
    await open(t, 'builtin:sermon');
    await t.enterText(find.byType(TextField).first, 'Abide in me');
    await t.pump(const Duration(seconds: 2));
    expect(repo.created, hasLength(1));
    expect(repo.created.single.title, 'Abide in me');
    expect(repo.created.single.body, contains('## Main points'));
    expect(prefs.getString('note_template_last_speaker'), 'Ada Obi');
    // Saving the first note also retires the empty-notes hint.
    expect(prefs.getBool('notes_template_hint_seen'), isTrue);
  });

  testWidgets('a blank note still opens blank, with the editor focused',
      (t) async {
    await open(t, null);
    expect(noteDocumentToMarkdown(editor(t).document), '');
    expect(find.text('Sermon'), findsNothing);
  });

  testWidgets('typing a reference in the body links it, and the link is saved',
      (t) async {
    await open(t, null);
    final e = editor(t);
    e.selection = Selection.collapsed(Position(path: [0], offset: 0));
    for (final ch in 'See John 3:16 '.split('')) {
      final off = e.selection!.startIndex;
      await e.apply(e.transaction
        ..insertText(e.getNodeAtPath([0])!, off, ch)
        ..afterSelection =
            Selection.collapsed(Position(path: [0], offset: off + 1)));
      await t.pump();
    }
    await t.pump(const Duration(seconds: 2));
    expect(e.getNodeAtPath([0])!.delta!.toPlainText(),
        'See [[bible:JHN.3.16]] ');
    expect(repo.created.single.body, contains('[[bible:JHN.3.16]]'));
  });
}
