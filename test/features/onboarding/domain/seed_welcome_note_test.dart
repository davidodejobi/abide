import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/audio/audio_quality.dart';
import 'package:openbaptisthymnal/core/storage/storage_service.dart';
import 'package:openbaptisthymnal/features/onboarding/domain/seed_welcome_note.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<StorageService> _makeStorage() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return StorageService(prefs);
}

void main() {
  group('seedWelcomeNoteIfNeeded', () {
    test('creates the example note on first call', () async {
      final storage = await _makeStorage();
      final calls = <({String title, String body})>[];

      await seedWelcomeNoteIfNeeded(
        storage: storage,
        createNote: ({String title = '', String contentMarkdown = ''}) async {
          calls.add((title: title, body: contentMarkdown));
          return 'id-${calls.length}';
        },
        userName: 'David',
      );

      expect(calls, hasLength(1));
      expect(calls.single.title, 'Welcome to your tablets');
      expect(storage.isWelcomeNoteSeeded(), isTrue);
    });

    test('does not seed twice', () async {
      final storage = await _makeStorage();
      final calls = <String>[];
      Future<String> create(
              {String title = '', String contentMarkdown = ''}) async {
        calls.add(title);
        return 'id-${calls.length}';
      }

      await seedWelcomeNoteIfNeeded(
        storage: storage,
        createNote: create,
        userName: 'David',
      );
      await seedWelcomeNoteIfNeeded(
        storage: storage,
        createNote: create,
        userName: 'David',
      );

      expect(calls, hasLength(1));
    });

    test('uses the first name in the greeting when given a full name',
        () async {
      final storage = await _makeStorage();
      String? body;

      await seedWelcomeNoteIfNeeded(
        storage: storage,
        createNote: ({String title = '', String contentMarkdown = ''}) async {
          body = contentMarkdown;
          return 'id';
        },
        userName: 'David Odejobi',
      );

      expect(body, contains('Hi David,'));
    });

    test('falls back to a neutral greeting when no name is given', () async {
      final storage = await _makeStorage();
      String? body;

      await seedWelcomeNoteIfNeeded(
        storage: storage,
        createNote: ({String title = '', String contentMarkdown = ''}) async {
          body = contentMarkdown;
          return 'id';
        },
        userName: null,
      );

      expect(body, contains('Hi there,'));
    });

    test('includes the hymn + bible wikilinks as a discovery hint', () async {
      final storage = await _makeStorage();
      String? body;

      await seedWelcomeNoteIfNeeded(
        storage: storage,
        createNote: ({String title = '', String contentMarkdown = ''}) async {
          body = contentMarkdown;
          return 'id';
        },
        userName: 'Tester',
      );

      expect(body, contains('[[hymn:hymn_0001]]'));
      expect(body, contains('[[bible:JHN.3.16]]'));
      expect(body, contains('[[hymn:hymn_0004]]'));
      expect(body, contains('[[bible:PSA.23.1]]'));
    });

    test('uses the "tablet" wording, never "note" (matches in-app terminology)',
        () async {
      final storage = await _makeStorage();
      String? body;
      String? capturedTitle;

      await seedWelcomeNoteIfNeeded(
        storage: storage,
        createNote: ({String title = '', String contentMarkdown = ''}) async {
          capturedTitle = title;
          body = contentMarkdown;
          return 'id';
        },
        userName: 'Tester',
      );

      expect(capturedTitle, equals('Welcome to your tablets'));
      // "note" is a substring of "notebook", so check for the whole word.
      final wordNote = RegExp(r'\bnote\b', caseSensitive: false);
      expect(wordNote.hasMatch(body!), isFalse,
          reason: 'body should use "tablet", not "note"');
    });

    test('contains no em dashes (per user writing preference)', () async {
      final storage = await _makeStorage();
      String? body;
      await seedWelcomeNoteIfNeeded(
        storage: storage,
        createNote: ({String title = '', String contentMarkdown = ''}) async {
          body = contentMarkdown;
          return 'id';
        },
        userName: 'Tester',
      );

      expect(body, isNot(contains('—')));
    });

    test('a thrown createNote leaves the seeded flag false so we retry next run',
        () async {
      final storage = await _makeStorage();

      await seedWelcomeNoteIfNeeded(
        storage: storage,
        createNote: ({String title = '', String contentMarkdown = ''}) =>
            Future.error(StateError('db hiccup')),
        userName: 'David',
      );

      expect(storage.isWelcomeNoteSeeded(), isFalse);
    });
  });

  test('isWelcomeNoteSeeded defaults to false on a fresh install', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    expect(storage.isWelcomeNoteSeeded(), isFalse);
    // Sanity: persisting unrelated prefs doesn't accidentally toggle the flag.
    await storage.saveAudioQuality(AudioQuality.high);
    expect(storage.isWelcomeNoteSeeded(), isFalse);
  });
}
