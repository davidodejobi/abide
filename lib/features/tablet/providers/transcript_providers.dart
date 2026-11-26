import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/providers/service_providers.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/features/tablet/data/transcribe_engine.dart';
import 'package:openbaptisthymnal/features/tablet/domain/transcript.dart';

/// The engine for this platform; tests override it.
final chunkTranscriberProvider =
    Provider<ChunkTranscriber>((ref) => platformChunkTranscriber());

/// Reads the real audio length natively; tests override it.
final durationProbeProvider =
    Provider<DurationProbe>((ref) => probeDurationMs);

const _wifiOnlyKey = 'notes_transcript_wifi_only';

/// The user's "Wi-Fi only" choice for the Android model download. Defaults on.
final transcriptWifiOnlyProvider =
    NotifierProvider<TranscriptWifiOnlyNotifier, bool>(
        TranscriptWifiOnlyNotifier.new);

class TranscriptWifiOnlyNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(_wifiOnlyKey) ?? true;

  Future<void> set(bool v) async {
    state = v;
    await ref.read(sharedPreferencesProvider).setBool(_wifiOnlyKey, v);
  }
}

/// A transcript of a recording was asked for (from the block menu, or right
/// after recording): the open note switches to its Transcript tab for it.
final transcriptRequestProvider =
    NotifierProvider<TranscriptRequestNotifier, TranscriptKey?>(
        TranscriptRequestNotifier.new);

class TranscriptRequestNotifier extends Notifier<TranscriptKey?> {
  @override
  TranscriptKey? build() => null;
  void request(TranscriptKey key) => state = key;
  void clear() => state = null;
}

enum TranscriptPhase { loading, idle, downloading, running }

class TranscriptState {
  const TranscriptState(this.phase,
      {this.transcript,
      this.progress = 0,
      this.failure,
      this.stopping = false});

  final TranscriptPhase phase;

  /// What the Transcript tab shows: the finished transcript if there is one,
  /// else the saved part.
  final Transcript? transcript;

  /// 0..1: download progress, or how much of the audio is done.
  final double progress;

  /// Set when the last run stopped early; saved results are kept.
  final TranscribeFailure? failure;

  /// Cancel was pressed; the current chunk is finishing.
  final bool stopping;
}

typedef TranscriptKey = ({String path, int durationMs});

/// One recording's transcript. A finished transcript lives in
/// `<uuid>.transcript.json`; a run in progress is saved after every chunk to
/// `<uuid>.transcript.part.json` and only swapped in when it completes, so a
/// replacement never overwrites a complete transcript with a partial one.
final transcriptProvider = NotifierProvider.family<TranscriptNotifier,
    TranscriptState, TranscriptKey>(TranscriptNotifier.new);

class TranscriptNotifier extends FamilyNotifier<TranscriptState, TranscriptKey> {
  bool _cancel = false;
  bool _busy = false;
  String _language = 'en';
  Transcript? _final; // complete, on disk
  Transcript? _part; // a run in progress or stopped, on disk

  @override
  TranscriptState build(TranscriptKey arg) {
    Future.microtask(_load);
    return const TranscriptState(TranscriptPhase.loading);
  }

  Future<Transcript?> _read(String path) async {
    try {
      final text = await ref.read(fileStorageServiceProvider).readText(path);
      if (text == null) return null;
      return Transcript.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (_) {
      return null; // a damaged file is the same as none
    }
  }

  Future<void> _load() async {
    _final = await _read(transcriptPathFor(arg.path));
    _part = await _read(transcriptPartPathFor(arg.path));
    final shown = _final ?? _part;
    state = TranscriptState(TranscriptPhase.idle,
        transcript: shown, progress: _progress(shown));
    final part = _part;
    if (part != null && !part.complete && !part.cancelled && part.doneMs > 0) {
      _language = part.language;
      if (!transcribeNeedsModel || await whisperModelReady()) {
        unawaited(start(part.language, replace: _final != null));
      }
    }
  }

  double _progress(Transcript? t) =>
      t?.progress(t.durationMs > 0 ? t.durationMs : arg.durationMs) ?? 0;

  /// Stops after the chunk in progress (or the download), keeping what is saved.
  void cancel() {
    if (!_busy) return;
    _cancel = true;
    cancelModelDownload();
    state = TranscriptState(state.phase,
        transcript: state.transcript, progress: state.progress, stopping: true);
  }

  void dismissFailure() => state = TranscriptState(TranscriptPhase.idle,
      transcript: state.transcript, progress: state.progress);

  /// Transcribes in [language]. With a finished transcript present it only runs
  /// when [replace] is true (the UI asks first). A saved part in the same
  /// language is continued. On Android the model is downloaded first; with
  /// [wifiOnly] (default: the saved choice) that waits for Wi-Fi.
  Future<void> start(String language,
      {bool? wifiOnly, bool replace = false}) async {
    if (_busy || !transcriptLanguageSupported(language)) return;
    if (_final != null && !replace) return;
    _busy = true;
    _cancel = false;
    _language = language;
    final wifiPref = ref.read(transcriptWifiOnlyProvider);
    final useWifiOnly = wifiOnly ?? wifiPref;
    final shown = _final ?? _part;
    final files = ref.read(fileStorageServiceProvider);
    final partPath = transcriptPartPathFor(arg.path);

    TranscriptState idle([TranscribeFailure? f, Transcript? t]) =>
        TranscriptState(TranscriptPhase.idle,
            transcript: t ?? _final ?? _part,
            progress: _progress(t ?? _final ?? _part),
            failure: f);

    state = TranscriptState(TranscriptPhase.running,
        transcript: shown, progress: _progress(_part));
    try {
      await runSerially(() async {
        try {
          if (_cancel) throw const TranscribeException(TranscribeFailure.cancelled);
          var duration = 0;
          try {
            duration = await ref.read(durationProbeProvider)(arg.path);
          } on TranscribeException {
            // Fall back to the length the note stored.
          }
          if (duration <= 0) duration = arg.durationMs;
          if (duration <= 0) {
            throw const TranscribeException(TranscribeFailure.failed);
          }

          if (transcribeNeedsModel && !await whisperModelReady()) {
            if (useWifiOnly && !await onWifi()) {
              throw const TranscribeException(TranscribeFailure.waitingForWifi);
            }
            state = TranscriptState(TranscriptPhase.downloading,
                transcript: shown, stopping: _cancel);
            await downloadWhisperModel((v) => state = TranscriptState(
                TranscriptPhase.downloading,
                transcript: shown,
                progress: v,
                stopping: _cancel));
          }

          final saved = _part;
          var t = saved != null && saved.language == language && !saved.complete
              ? saved
              : Transcript(language: language, durationMs: duration);
          final engine = ref.read(chunkTranscriberProvider);
          while (!_cancel) {
            final next = t.nextChunk(duration);
            if (next == null) break;
            state = TranscriptState(TranscriptPhase.running,
                transcript: shown,
                progress: t.progress(duration),
                stopping: _cancel);
            final segs = await engine(arg.path, next.$1, next.$2, language);
            t = t.withChunk(next.$2, segs, durationMs: duration);
            _part = t;
            if (!t.complete) {
              await files.writeText(partPath, jsonEncode(t.toJson()));
            }
          }
          if (t.complete) {
            await files.writeText(
                transcriptPathFor(arg.path), jsonEncode(t.toJson()));
            _final = t;
            _part = null;
            await files.deleteFile(partPath);
            state = idle(null, t);
          } else {
            // Stopped by the user: keep the part, do not resume on next open.
            final stopped = t.copyWith(cancelled: true);
            _part = stopped;
            if (stopped.doneMs > 0) {
              await files.writeText(partPath, jsonEncode(stopped.toJson()));
            }
            state = idle();
          }
        } finally {
          await releaseEngine();
        }
      });
    } on TranscribeException catch (e) {
      state = e.failure == TranscribeFailure.cancelled
          ? idle()
          : idle(e.failure);
    } catch (_) {
      state = idle(TranscribeFailure.failed);
    } finally {
      _busy = false;
    }
  }

  /// Run again after a failure, in the language that was last used, with the
  /// saved Wi-Fi choice.
  Future<void> retry() => start(_language, replace: _final != null);
}
