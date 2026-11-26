import 'dart:async';

import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/features/tablet/data/repositories/templates_repository.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_template.dart';
import 'package:openbaptisthymnal/features/tablet/providers/templates_providers.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';
import 'package:openbaptisthymnal/features/tablet/ui/pages/manage_templates_page.dart';
import 'package:openbaptisthymnal/features/tablet/ui/pages/template_editor_page.dart';
import 'package:openbaptisthymnal/features/tablet/ui/widgets/new_note_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/reader_harness.dart' show appFor, setView, settle;

const _mine = NoteTemplate(
  id: 'mine-1',
  name: 'Sunday sermon',
  icon: 'church',
  sections: [
    TemplateSection(TemplateSectionType.field, 'Speaker'),
    TemplateSection(TemplateSectionType.bullet, 'Points'),
  ],
);

/// Records what the UI asks of storage.
class _FakeRepo extends TemplatesRepository {
  _FakeRepo(super.dao);

  final calls = <String>[];
  String? savedName;
  List<TemplateSection>? savedSections;

  @override
  Future<String> save({
    String? id,
    required String name,
    required String icon,
    required List<TemplateSection> sections,
  }) async {
    calls.add('save ${id ?? 'new'}');
    savedName = name;
    savedSections = sections;
    return id ?? 'new-id';
  }

  @override
  Future<String> duplicate(NoteTemplate source, String copyName) async {
    calls.add('duplicate ${source.id} as $copyName');
    return 'copy';
  }

  @override
  Future<void> delete(String id) async {
    calls.add('delete $id');
    _mineChanges.add(const []);
  }

  @override
  Future<void> restore(String id) async => calls.add('restore $id');
}

late SharedPreferences _prefs;
late AppDatabase _db;
late _FakeRepo _repo;

/// Lets a test play the part of the database stream after a delete.
final _mineChanges = StreamController<List<NoteTemplate>>.broadcast();

List<Override> _overrides({List<NoteTemplate> mine = const [_mine]}) => [
      sharedPreferencesProvider.overrideWithValue(_prefs),
      myTemplatesProvider.overrideWith((ref) async* {
        yield mine;
        yield* _mineChanges.stream;
      }),
      templatesRepositoryProvider.overrideWithValue(_repo),
    ];

/// A host that opens the picker and remembers what it returned.
class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  NewNoteChoice? choice;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          TextButton(
            onPressed: () async {
              choice = await showModalBottomSheet<NewNoteChoice>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const NewNoteSheet(),
              );
            },
            child: const Text('open'),
          ),
        ]),
      );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'note_template_pins': ['builtin:prayer_journal'],
    });
    _prefs = await SharedPreferences.getInstance();
    _db = AppDatabase.forTesting(NativeDatabase.memory());
    _repo = _FakeRepo(_db.noteTemplatesDao);
  });
  tearDown(() => _db.close());

  Future<void> openPicker(WidgetTester t) async {
    setView(t, const Size(390, 844));
    await t.pumpWidget(appFor(_overrides(), const _Host()));
    await t.tap(find.text('open'));
    await settle(t);
  }

  double top(WidgetTester t, String text) =>
      t.getTopLeft(find.text(text).first).dy;

  testWidgets('picker lists Blank, Pinned, Mine, Built-in, then Create',
      (t) async {
    await openPicker(t);
    final order = [
      NotesStrings.blankNote,
      NotesStrings.pinned,
      'Prayer journal',
      NotesStrings.mine,
      'Sunday sermon',
      NotesStrings.builtIn,
      'Sermon',
      'Bible study',
      'Small group',
      'Devotional',
      NotesStrings.createTemplate,
    ];
    final ys = [for (final o in order) top(t, o)];
    expect(ys, orderedEquals([...ys]..sort()), reason: '$order at $ys');
    // A pinned template is shown once, under Pinned, not again in Built-in.
    expect(find.text('Prayer journal'), findsOneWidget);
  });

  testWidgets('picker cards are 56 to 60 pt tall', (t) async {
    await openPicker(t);
    for (final card in t.widgetList<TemplateCard>(find.byType(TemplateCard))) {
      final h = t.getSize(find.byWidget(card)).height;
      expect(h, inInclusiveRange(56, 60), reason: card.template.name);
    }
  });

  testWidgets('tapping a template returns it, Blank returns blank', (t) async {
    await openPicker(t);
    await t.tap(find.text('Bible study'));
    await settle(t);
    final host = t.state<_HostState>(find.byType(_Host));
    expect((host.choice as TemplateNoteChoice).templateId,
        'builtin:bible_study');

    await t.tap(find.text('open'));
    await settle(t);
    await t.tap(find.text(NotesStrings.blankNote));
    await settle(t);
    expect(host.choice, isA<BlankNoteChoice>());
  });

  testWidgets('long press offers pin, duplicate and preview; pin persists',
      (t) async {
    await openPicker(t);
    await t.longPress(find.text('Sermon'));
    await settle(t);
    expect(find.text(NotesStrings.pin), findsOneWidget);
    expect(find.text(NotesStrings.duplicate), findsOneWidget);
    expect(find.text(NotesStrings.previewSections), findsOneWidget);

    await t.tap(find.text(NotesStrings.pin));
    await settle(t);
    expect(_prefs.getStringList('note_template_pins'),
        ['builtin:prayer_journal', 'builtin:sermon']);
  });

  testWidgets('long press on a pinned card offers Unpin', (t) async {
    await openPicker(t);
    await t.longPress(find.text('Prayer journal'));
    await settle(t);
    await t.tap(find.text(NotesStrings.unpin));
    await settle(t);
    expect(_prefs.getStringList('note_template_pins'), isEmpty);
  });

  testWidgets('long press, Duplicate adds a copy to Mine', (t) async {
    await openPicker(t);
    await t.longPress(find.text('Devotional'));
    await settle(t);
    await t.tap(find.text(NotesStrings.duplicate));
    await settle(t);
    expect(_repo.calls, ['duplicate builtin:devotional as Devotional copy']);
  });

  testWidgets('long press, Preview lists the template sections', (t) async {
    await openPicker(t);
    await t.longPress(find.text('Sunday sermon'));
    await settle(t);
    await t.tap(find.text(NotesStrings.previewSections));
    await settle(t);
    expect(find.text('Speaker'), findsOneWidget);
    expect(find.text('Points'), findsOneWidget);
    expect(find.text('Bullet list'), findsOneWidget);
  });

  group('Manage templates', () {
    Future<void> openManage(WidgetTester t) async {
      setView(t, const Size(390, 900));
      await t.pumpWidget(appFor(_overrides(), const ManageTemplatesPage()));
      await settle(t);
    }

    testWidgets('shows Pinned, Mine and Built-in, with a note on built-ins',
        (t) async {
      await openManage(t);
      expect(find.text(NotesStrings.pinnedManageHeader), findsOneWidget);
      expect(find.text(NotesStrings.mine), findsOneWidget);
      expect(find.text(NotesStrings.builtIn), findsWidgets);
      expect(find.text('Sunday sermon'), findsOneWidget);
      // Five built-ins, each can only be duplicated.
      expect(find.text(NotesStrings.duplicate), findsNWidgets(5));
      await t.scrollUntilVisible(find.text(NotesStrings.builtInFootnote),
          200,
          scrollable: find.byType(Scrollable).first);
    });

    testWidgets('Duplicate on a built-in makes a Mine copy', (t) async {
      await openManage(t);
      await t.scrollUntilVisible(find.text('Bible study'), 200,
          scrollable: find.byType(Scrollable).first);
      await t.tap(find.text(NotesStrings.duplicate).at(2));
      await settle(t);
      expect(_repo.calls.single, startsWith('duplicate builtin:'));
      expect(find.text(NotesStrings.addedToMine), findsOneWidget);
    });

    testWidgets('swipe delete on Mine offers undo that restores it',
        (t) async {
      await openManage(t);
      await t.drag(find.text('Sunday sermon'), const Offset(-500, 0));
      await settle(t);
      expect(_repo.calls, ['delete mine-1']);
      expect(find.text(NotesStrings.templateDeleted('Sunday sermon')),
          findsOneWidget);
      await t.pump(const Duration(seconds: 1));
      await t.tap(find.widgetWithText(TextButton, NotesStrings.undo));
      await settle(t);
      expect(_repo.calls, ['delete mine-1', 'restore mine-1']);
    });

    testWidgets('the more menu on Mine can delete too', (t) async {
      await openManage(t);
      await t.tap(find.byTooltip(NotesStrings.mediaMore));
      await settle(t);
      expect(find.text(NotesStrings.edit), findsOneWidget);
      await t.tap(find.text(NotesStrings.delete));
      await settle(t);
      expect(_repo.calls, ['delete mine-1']);
    });
  });

  group('Template builder', () {
    Future<void> openForm(WidgetTester t,
        {String name = '', List<TemplateSection> sections = const []}) async {
      setView(t, const Size(390, 900));
      await t.pumpWidget(appFor(
        _overrides(),
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => TemplateEditorPage(
                    initialName: name, initialSections: sections),
              )),
              child: const Text('go'),
            ),
          ),
        ),
      ));
      await t.tap(find.text('go'));
      await settle(t);
    }

    testWidgets('Save is disabled with a hint until the template has a name',
        (t) async {
      await openForm(t);
      expect(find.text(NotesStrings.templateNameHint), findsOneWidget);
      await t.tap(find.text(NotesStrings.saveTemplate));
      await settle(t);
      expect(_repo.calls, isEmpty);

      await t.enterText(find.byType(TextField), 'Home group');
      await settle(t);
      expect(find.text(NotesStrings.templateNameHint), findsNothing);
    });

    testWidgets('Add section offers all six types as rows', (t) async {
      await openForm(t, name: 'X');
      await t.tap(find.text(NotesStrings.addSection));
      await settle(t);
      for (final type in TemplateSectionType.values) {
        expect(find.text(NotesStrings.sectionType(type)), findsOneWidget);
      }
      // 52 pt rows.
      final h = t.getSize(find.text(NotesStrings.sectionType(TemplateSectionType.heading))
          .first);
      expect(h.height, lessThanOrEqualTo(52));
    });

    testWidgets('add, rename, remove and save produce the sections',
        (t) async {
      await openForm(t, name: 'Home group', sections: const [
        TemplateSection(TemplateSectionType.field, 'Host'),
        TemplateSection(TemplateSectionType.text, 'Notes'),
      ]);
      // Add a checklist and name it.
      await t.tap(find.text(NotesStrings.addSection));
      await settle(t);
      await t.tap(find.text('Checklist'));
      await settle(t);
      await t.enterText(find.byType(TextField).last, 'Follow-up');
      await t.tap(find.text(NotesStrings.save));
      await settle(t);
      expect(find.text('Follow-up'), findsOneWidget);

      // Remove "Notes".
      await t.tap(find.byTooltip(NotesStrings.removeSection).at(1));
      await settle(t);
      expect(find.text('Notes'), findsNothing);

      await t.tap(find.text(NotesStrings.saveTemplate));
      await settle(t);
      expect(_repo.calls, ['save new']);
      expect(_repo.savedName, 'Home group');
      expect(_repo.savedSections, const [
        TemplateSection(TemplateSectionType.field, 'Host'),
        TemplateSection(TemplateSectionType.checklist, 'Follow-up'),
      ]);
    });

    testWidgets('a note saved as a template arrives pre-filled', (t) async {
      await openForm(t, name: 'Sunday', sections: const [
        TemplateSection(TemplateSectionType.bullet, 'Main points'),
      ]);
      expect(find.text('Main points'), findsOneWidget);
      expect(find.text(NotesStrings.sectionCount(1)), findsNothing);
      expect(find.textContaining(NotesStrings.sectionCount(1)), findsOneWidget);
    });
  });
}
