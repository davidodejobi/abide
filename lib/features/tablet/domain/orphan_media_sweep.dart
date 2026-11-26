import 'dart:io';

import 'package:openbaptisthymnal/features/tablet/domain/transcript.dart';
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
/// A transcript (`<uuid>.transcript.json`, or `.transcript.part.json` while a
/// run is unfinished, beside its audio) is never a
/// candidate on its own: it stays while its audio is referenced and goes only
/// together with its audio.
///
/// Returns the number of files deleted.
Future<int> sweepOrphanMedia({
  required Future<Iterable<String>> Function() loadReferenceTexts,
  required Future<List<File>> Function(String bucket) listFiles,

  /// How many notes (trashed included) were read. Zero while media files exist
  /// means the database looks empty or unreadable, so nothing is deleted.
  required int Function() noteCount,
  DateTime? now,
}) async {
  final Set<String> referenced;
  final Map<String, List<File>> files = {};
  try {
    referenced = {
      for (final text in await loadReferenceTexts())
        for (final m in _mediaRef.allMatches(text)) m[0]!,
    };
    for (final bucket in mediaBuckets) {
      files[bucket] = await listFiles(bucket);
    }
    if (noteCount() == 0 && files.values.any((f) => f.isNotEmpty)) return 0;
  } catch (_) {
    return 0;
  }

  final cutoff = (now ?? DateTime.now()).subtract(orphanGrace);
  var deleted = 0;
  for (final entry in files.entries) {
    for (final file in entry.value) {
      try {
        final ref = '${entry.key}/${p.basename(file.path)}';
        // Only files the app named itself (uuid.ext) are ever candidates.
        if (!_mediaRef.hasMatch(ref) || _mediaRef.firstMatch(ref)![0] != ref) {
          continue;
        }
        if (referenced.contains(ref)) continue;
        if (file.lastModifiedSync().isAfter(cutoff)) continue;
        await file.delete();
        deleted++;
        for (final side in [
          transcriptPathFor(file.path),
          transcriptPartPathFor(file.path),
        ]) {
          final sidecar = File(side);
          if (sidecar.existsSync()) await sidecar.delete();
        }
      } catch (_) {
        // A file we cannot stat or remove is left for the next run.
      }
    }
  }
  return deleted;
}
