import 'dart:io';

import 'package:path/path.dart' as p;

const mediaBuckets = ['note_images', 'note_audio'];
const orphanGrace = Duration(days: 7);

final _mediaRef = RegExp(r'note_(?:images|audio)/[\w-]+\.\w+');

/// Mark and sweep for note media files.
///
/// A file is deleted only when no text in [loadReferenceTexts] mentions its
/// `bucket/name`, and it is older than [orphanGrace]. The caller passes the
/// markdown of every note, trashed ones included (trash keeps its files), plus
/// any attachment paths. If building the reference set throws, nothing is
/// deleted. Block removal never deletes a file: editor undo can bring the block
/// back, so files are only reclaimed here, long after the fact.
///
/// Returns the number of files deleted.
Future<int> sweepOrphanMedia({
  required Future<Iterable<String>> Function() loadReferenceTexts,
  required Future<List<File>> Function(String bucket) listFiles,
  DateTime? now,
}) async {
  final Set<String> referenced;
  try {
    referenced = {
      for (final text in await loadReferenceTexts())
        for (final m in _mediaRef.allMatches(text)) m[0]!,
    };
  } catch (_) {
    return 0;
  }

  final cutoff = (now ?? DateTime.now()).subtract(orphanGrace);
  var deleted = 0;
  for (final bucket in mediaBuckets) {
    for (final file in await listFiles(bucket)) {
      try {
        final ref = '$bucket/${p.basename(file.path)}';
        if (referenced.contains(ref)) continue;
        if (file.lastModifiedSync().isAfter(cutoff)) continue;
        await file.delete();
        deleted++;
      } catch (_) {
        // A file we cannot stat or remove is left for the next run.
      }
    }
  }
  return deleted;
}
