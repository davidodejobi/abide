import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/storage_service.dart';
import 'package:openbaptisthymnal/features/tablet/domain/release_notes.dart';
import 'package:openbaptisthymnal/features/tablet/domain/seed_release_notes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StorageService storage;
  late List<String> created;

  /// Stands in for TabletsRepository.createNote.
  Future<String> createNote({
    String title = '',
    String contentMarkdown = '',
  }) async {
    created.add(title);
    return 'note-${created.length}';
  }

  const v1 = ReleaseNote(id: 'r-1', title: 'What is new in 1', body: 'one');
  const v2 = ReleaseNote(id: 'r-2', title: 'What is new in 2', body: 'two');

  Future<void> setUpStorage({required bool onboarded}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
    if (onboarded) await storage.saveOnboardingComplete(true);
    created = [];
  }

  group('Given an existing user upgrading into a new release', () {
    setUp(() => setUpStorage(onboarded: true));

    group('When the app starts', () {
      test('Then the release note lands in their tablets', () async {
        await seedReleaseNotesIfNeeded(
          storage: storage,
          createNote: createNote,
          releases: const [v1],
        );

        expect(created, ['What is new in 1']);
        expect(storage.getSeededReleaseNoteIds(), ['r-1']);
      });

      test('Then starting again does not create it twice', () async {
        for (var launch = 0; launch < 3; launch++) {
          await seedReleaseNotesIfNeeded(
            storage: storage,
            createNote: createNote,
            releases: const [v1],
          );
        }

        expect(created, hasLength(1));
      });

      test('Then only the releases they have not seen are created', () async {
        await seedReleaseNotesIfNeeded(
          storage: storage,
          createNote: createNote,
          releases: const [v1],
        );
        created.clear();

        // They skipped a version: two releases exist, one is already seen.
        await seedReleaseNotesIfNeeded(
          storage: storage,
          createNote: createNote,
          releases: const [v1, v2],
        );

        expect(created, ['What is new in 2']);
        expect(storage.getSeededReleaseNoteIds(), ['r-1', 'r-2']);
      });
    });
  });

  group('Given the user deleted the release note', () {
    setUp(() => setUpStorage(onboarded: true));

    group('When the app starts again', () {
      test('Then it does NOT come back', () async {
        await seedReleaseNotesIfNeeded(
          storage: storage,
          createNote: createNote,
          releases: const [v1],
        );
        created.clear();

        // The user deletes the tablet. Nothing here tells the seeder about it,
        // and that is exactly the design: the seeded-id list is the only record
        // consulted, so the note's absence from the database is not an argument
        // for re-creating it. Anything that checked "is the note still there?"
        // would resurrect a note the user threw away, on every single launch.
        await seedReleaseNotesIfNeeded(
          storage: storage,
          createNote: createNote,
          releases: const [v1],
        );

        expect(created, isEmpty, reason: 'a deleted note must stay deleted');
      });
    });
  });

  group('Given a brand-new install', () {
    setUp(() => setUpStorage(onboarded: false));

    group('When the app starts', () {
      test('Then no back-catalogue of release notes is dumped on them',
          () async {
        // Everything in the app is new to them, and they already get the welcome
        // tablet. Handing a new user "what's new in 1.2, 1.3, 1.4" as well is
        // clutter that grows with every release we ever ship.
        await seedReleaseNotesIfNeeded(
          storage: storage,
          createNote: createNote,
          releases: const [v1, v2],
        );

        expect(created, isEmpty);
      });

      test('Then they still get the NEXT release like everyone else', () async {
        await seedReleaseNotesIfNeeded(
          storage: storage,
          createNote: createNote,
          releases: const [v1, v2],
        );
        await storage.saveOnboardingComplete(true);

        const v3 = ReleaseNote(id: 'r-3', title: 'What is new in 3', body: '3');
        await seedReleaseNotesIfNeeded(
          storage: storage,
          createNote: createNote,
          releases: const [v1, v2, v3],
        );

        expect(created, ['What is new in 3']);
      });
    });
  });

  group('Given creating the note throws', () {
    setUp(() => setUpStorage(onboarded: true));

    group('When the app starts', () {
      test('Then the launch survives and it retries next time', () async {
        Future<String> boom({
          String title = '',
          String contentMarkdown = '',
        }) async =>
            throw Exception('database busy');

        await expectLater(
          seedReleaseNotesIfNeeded(
            storage: storage,
            createNote: boom,
            releases: const [v1],
          ),
          completes,
          reason: 'a changelog is not worth failing a cold start over',
        );

        // Nothing was recorded, so the next launch tries again rather than
        // silently swallowing the release note forever.
        expect(storage.getSeededReleaseNoteIds(), isEmpty);
      });
    });
  });

  group('Given the release notes shipped with the app', () {
    test('Then their ids are unique -- a reused id re-seeds a deleted note', () {
      // An id is the ONLY thing that says "this person has seen this". Reuse one
      // and the note reappears for everybody who already deleted it, which is
      // the single promise this feature makes.
      final ids = kReleaseNotes.map((r) => r.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
      expect(ids, everyElement(isNotEmpty));
    });

    test('Then every note has a title and a body', () {
      for (final release in kReleaseNotes) {
        expect(release.title, isNotEmpty, reason: release.id);
        expect(release.body.trim(), isNotEmpty, reason: release.id);
      }
    });
  });
}
