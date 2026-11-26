import 'dart:ui' show Size;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/folders_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/note_links_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/notes_dao.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/tags_dao.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';
import 'package:openbaptisthymnal/features/tablet/data/repositories/tablets_repository.dart';
import 'package:openbaptisthymnal/features/tablet/data/sources/local/tablets_local_source.dart';
import 'package:openbaptisthymnal/features/tablet/providers/tablets_providers.dart';
import 'package:openbaptisthymnal/features/tablet/providers/templates_providers.dart';
import 'package:openbaptisthymnal/features/tablet/ui/pages/tablet_editor_page.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/note_player_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/reader_harness.dart'
    show appFor, johnManifest, setView, settle;

void main() {
  testWidgets('a note with a recording opens, shows the pinned player',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = TabletsRepository(TabletsLocalSource(
        NotesDao(db), NoteLinksDao(db), FoldersDao(db), TagsDao(db)));
    setView(t, const Size(390, 844));
    await t.pumpWidget(appFor([
      sharedPreferencesProvider.overrideWithValue(prefs),
      tabletsRepositoryProvider.overrideWithValue(repo),
      myTemplatesProvider.overrideWith((ref) => Stream.value(const [])),
      bibleManifestProvider.overrideWith((ref, id) async => johnManifest()),
    ],
        const TabletEditorPage(
          initialMarkdown: '![Rec](note_audio/x.m4a "dur=60000")\n\n'
              '[00:05](t:5) Intro',
        )));
    await settle(t);
    expect(t.takeException(), isNull);
    expect(find.byType(NotePlayerBar), findsOneWidget);
  });
}
