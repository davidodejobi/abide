import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';

import '../data/landmark_loader.dart';
import '../domain/landmark_glb_loader.dart';
import '../domain/road_landmarks.dart';

final landmarkLoaderProvider =
    Provider<LandmarkGlbLoader>((_) => sharedLandmarkLoader);

/// The models that are not bundled with the app: what a download fetches.
final remoteLandmarkModelsProvider =
    FutureProvider<List<LandmarkModelInfo>>((ref) async {
  final all = parseLandmarkModels(
      await rootBundle.loadString('assets/images/road/landmarks.json'));
  return [for (final m in all.values) if (!m.bundled) m];
});

enum LandmarkDownloadStatus { idle, downloading, done, failed }

class LandmarkDownloadState {
  const LandmarkDownloadState({
    this.status = LandmarkDownloadStatus.idle,
    this.doneFiles = 0,
    this.totalFiles = 0,
    this.doneBytes = 0,
    this.totalBytes = 0,
    this.accepted = false,
    this.declined = false,
  });

  final LandmarkDownloadStatus status;
  final int doneFiles, totalFiles, doneBytes, totalBytes;

  /// The saved choice: "Download now" / "Later" (or removed).
  final bool accepted, declined;

  double get progress => totalBytes == 0 ? 0 : doneBytes / totalBytes;

  LandmarkDownloadState copyWith({
    LandmarkDownloadStatus? status,
    int? doneFiles,
    int? totalFiles,
    int? doneBytes,
    int? totalBytes,
    bool? accepted,
    bool? declined,
  }) =>
      LandmarkDownloadState(
        status: status ?? this.status,
        doneFiles: doneFiles ?? this.doneFiles,
        totalFiles: totalFiles ?? this.totalFiles,
        doneBytes: doneBytes ?? this.doneBytes,
        totalBytes: totalBytes ?? this.totalBytes,
        accepted: accepted ?? this.accepted,
        declined: declined ?? this.declined,
      );
}

final landmarkDownloadProvider =
    NotifierProvider<LandmarkDownloadNotifier, LandmarkDownloadState>(
        LandmarkDownloadNotifier.new);

/// Downloads every non-bundled landmark model in the background, three at a
/// time, each retried twice and then skipped quietly. The choice is saved so
/// an interrupted download resumes on the next launch.
class LandmarkDownloadNotifier extends Notifier<LandmarkDownloadState> {
  static const _parallel = 3;
  static const _retries = 2;
  static const accepted = 'accepted', declined = 'declined';

  /// Pause before a retry; tests set it to zero.
  static Duration retryDelay = const Duration(milliseconds: 600);

  int _run = 0;

  @override
  LandmarkDownloadState build() {
    final choice =
        ref.read(storageServiceProvider).getLandmarkDownloadChoice();
    return LandmarkDownloadState(
        accepted: choice == accepted, declined: choice == declined);
  }

  /// Whether this platform can keep downloads (false on web).
  bool get supported => ref.read(landmarkLoaderProvider).cache != null;

  Future<void> _save(String choice) =>
      ref.read(storageServiceProvider).saveLandmarkDownloadChoice(choice);

  /// "Later".
  Future<void> decline() async {
    state = state.copyWith(accepted: false, declined: true);
    await _save(declined);
  }

  /// "Download now": remember the choice, then fetch what is missing. Callers
  /// need not await it; onboarding carries on.
  Future<void> start() async {
    state = state.copyWith(accepted: true, declined: false);
    await _save(accepted);
    await _download();
  }

  /// On launch: finish an interrupted download, only if the user asked for it.
  Future<void> resumeIfChosen() async {
    if (!state.accepted || state.status == LandmarkDownloadStatus.downloading) {
      return;
    }
    await _download();
  }

  /// Counts what is already on disk, for the status row.
  Future<void> refresh() async {
    if (state.status == LandmarkDownloadStatus.downloading) return;
    final (done, doneBytes, models) = await _scan();
    final total = models.fold<int>(0, (a, m) => a + m.bytes);
    state = state.copyWith(
      status: done == models.length && models.isNotEmpty
          ? LandmarkDownloadStatus.done
          : LandmarkDownloadStatus.idle,
      doneFiles: done,
      totalFiles: models.length,
      doneBytes: doneBytes,
      totalBytes: total,
    );
  }

  /// Deletes every downloaded model and stops asking: they download one by one
  /// again when a landmark is opened.
  Future<void> remove() async {
    _run++;
    final cache = ref.read(landmarkLoaderProvider).cache;
    for (final m in await _models()) {
      try {
        await cache?.delete(m.remoteName);
      } catch (_) {}
    }
    state = state.copyWith(
        status: LandmarkDownloadStatus.idle,
        doneFiles: 0,
        doneBytes: 0,
        accepted: false,
        declined: true);
    await _save(declined);
  }

  Future<List<LandmarkModelInfo>> _models() async {
    try {
      return await ref.read(remoteLandmarkModelsProvider.future);
    } catch (_) {
      return const [];
    }
  }

  Future<(int, int, List<LandmarkModelInfo>)> _scan() async {
    final cache = ref.read(landmarkLoaderProvider).cache;
    final models = await _models();
    var done = 0, bytes = 0;
    for (final m in models) {
      try {
        if (cache != null && await cache.has(m.remoteName)) {
          done++;
          bytes += m.bytes;
        }
      } catch (_) {}
    }
    return (done, bytes, models);
  }

  Future<void> _download() async {
    if (!supported) return;
    final run = ++_run;
    final loader = ref.read(landmarkLoaderProvider);
    final cache = loader.cache!;
    final models = await _models();
    final missing = <LandmarkModelInfo>[];
    var haveBytes = 0;
    for (final m in models) {
      var have = false;
      try {
        have = await cache.has(m.remoteName);
      } catch (_) {}
      if (have) {
        haveBytes += m.bytes;
      } else {
        missing.add(m);
      }
    }
    final total = models.fold<int>(0, (a, m) => a + m.bytes);
    var doneFiles = models.length - missing.length, doneBytes = haveBytes;
    state = state.copyWith(
      status: missing.isEmpty
          ? LandmarkDownloadStatus.done
          : LandmarkDownloadStatus.downloading,
      doneFiles: doneFiles,
      totalFiles: models.length,
      doneBytes: doneBytes,
      totalBytes: total,
    );
    if (missing.isEmpty) return;

    final queue = List.of(missing);
    Future<void> worker() async {
      while (queue.isNotEmpty && run == _run) {
        final m = queue.removeLast();
        var ok = false;
        for (var attempt = 0; attempt <= _retries && !ok; attempt++) {
          if (run != _run) return;
          if (attempt > 0) await Future<void>.delayed(retryDelay);
          ok = await loader.load(m) != null && await cache.has(m.remoteName);
        }
        if (run != _run) return;
        if (ok) {
          doneFiles++;
          doneBytes += m.bytes;
          state = state.copyWith(doneFiles: doneFiles, doneBytes: doneBytes);
        }
      }
    }

    await Future.wait([for (var i = 0; i < _parallel; i++) worker()]);
    if (run != _run) return;
    state = state.copyWith(
      status: doneFiles == models.length
          ? LandmarkDownloadStatus.done
          : LandmarkDownloadStatus.failed,
    );
  }
}

/// "4.8 MB" for a byte count.
String landmarkSizeLabel(int bytes) =>
    '${(bytes / 1000000).toStringAsFixed(1)} MB';
