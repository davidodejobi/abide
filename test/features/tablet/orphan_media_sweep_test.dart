import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/tablet/domain/orphan_media_sweep.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  final now = DateTime(2026, 11, 26);

  File make(String rel, {required int ageDays}) {
    final f = File(p.join(root.path, rel))..createSync(recursive: true);
    f.setLastModifiedSync(now.subtract(Duration(days: ageDays)));
    return f;
  }

  Future<List<File>> list(String bucket) async {
    final d = Directory(p.join(root.path, bucket));
    return d.existsSync() ? d.listSync().whereType<File>().toList() : [];
  }

  setUp(() => root = Directory.systemTemp.createTempSync('sweep'));
  tearDown(() => root.deleteSync(recursive: true));

  test('keeps referenced, trashed-note and young files; deletes old orphans',
      () async {
    final live = make('note_images/live.png', ageDays: 30);
    final trashed = make('note_audio/trashed.m4a', ageDays: 30);
    final young = make('note_images/young.png', ageDays: 1);
    final orphan = make('note_images/orphan.png', ageDays: 30);
    final orphanAudio = make('note_audio/orphan.m4a', ageDays: 8);

    final deleted = await sweepOrphanMedia(
      now: now,
      listFiles: list,
      noteCount: () => 3,
      loadReferenceTexts: () async => [
        'text\n\n![cap](note_images/live.png "size=m")',
        // A trashed note's markdown is part of the reference set.
        '![](note_audio/trashed.m4a "dur=5")',
      ],
    );

    expect(deleted, 2);
    expect(live.existsSync(), isTrue);
    expect(trashed.existsSync(), isTrue);
    expect(young.existsSync(), isTrue);
    expect(orphan.existsSync(), isFalse);
    expect(orphanAudio.existsSync(), isFalse);
  });

  test('deletes nothing when the reference build fails', () async {
    final orphan = make('note_images/orphan.png', ageDays: 90);
    final deleted = await sweepOrphanMedia(
      now: now,
      listFiles: list,
      noteCount: () => 3,
      loadReferenceTexts: () async => throw StateError('db closed'),
    );
    expect(deleted, 0);
    expect(orphan.existsSync(), isTrue);
  });
  test('deletes nothing when no notes were read but media exists', () async {
    final orphan = make('note_images/orphan.png', ageDays: 90);
    final deleted = await sweepOrphanMedia(
      now: now,
      listFiles: list,
      noteCount: () => 0,
      loadReferenceTexts: () async => const [],
    );
    expect(deleted, 0);
    expect(orphan.existsSync(), isTrue);
  });

  test('never touches files the app did not name', () async {
    final stray = make('note_images/.DS_Store', ageDays: 90);
    final odd = make('note_audio/my recording.m4a', ageDays: 90);
    await sweepOrphanMedia(
      now: now,
      listFiles: list,
      noteCount: () => 1,
      loadReferenceTexts: () async => const [],
    );
    expect(stray.existsSync(), isTrue);
    expect(odd.existsSync(), isTrue);
  });

  test('a failing listing deletes nothing', () async {
    final orphan = make('note_images/orphan.png', ageDays: 90);
    final deleted = await sweepOrphanMedia(
      now: now,
      noteCount: () => 1,
      listFiles: (_) async => throw const FileSystemException('denied'),
      loadReferenceTexts: () async => const [],
    );
    expect(deleted, 0);
    expect(orphan.existsSync(), isTrue);
  });
}
