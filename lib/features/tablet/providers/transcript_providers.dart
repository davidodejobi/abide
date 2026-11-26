import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/providers/service_providers.dart';
import 'package:openbaptisthymnal/features/tablet/data/transcribe_engine.dart';
import 'package:openbaptisthymnal/features/tablet/domain/transcript.dart';

/// The engine for this platform; tests override it.
final chunkTranscriberProvider =
    Provider<ChunkTranscriber>((ref) => platformChunkTranscriber());

enum TranscriptPhase { loading, idle, downloading, running }

class TranscriptState {
  const TranscriptState(this.phase,
      {this.transcript, this.progress = 0, this.failure});

  final TranscriptPhase phase;

  /// Whatever is saved so far, possibly partial.
  final Transcript? transcript;

  /// 0..1: download progress, or how much of the audio is done.
  final double progress;

  /// Set when the last run stopped early; the saved part is kept.
  final TranscribeFailure? failure;
}

typedef TranscriptKey = ({String path, int durationMs});

/// One recording's transcript: loads the saved file, runs the chunk loop and
/// saves after every chunk. Opening the note again resumes a partial one.
final transcriptProvider =
    NotifierProvider.family<TranscriptNotifier, TranscriptState, TranscriptKey>(
        TranscriptNotifier.new);

class TranscriptNotifier
    extends FamilyNotifier<TranscriptState, TranscriptKey> {
  bool _cancel = false;
  bool _busy = false;
  String _language = 'en';

  @override
  TranscriptState build(TranscriptKey arg) {
    Future.microtask(_load);
    return const TranscriptState(TranscriptPhase.loading);
  }

  Future<void> _load() async {
    Transcript? saved;
    try {
      final text = await ref
          .read(fileStorageServiceProvider)
          .readText(transcriptPathFor(arg.path));
      if (text != null) {
        saved = Transcript.fromJson(jsonDecode(text) as Map<String, dynamic>);
      }
    } catch (_) {
      // A damaged file is the same as none: start again.
    }
    state = TranscriptState(TranscriptPhase.idle,
        transcript: saved, progress: saved?.progress(arg.durationMs) ?? 0);
    if (saved != null && !saved.complete && saved.doneMs > 0) {
      _language = saved.language;
      if (!transcribeNeedsModel || await whisperModelReady()) {
        unawaited(start(saved.language));
      }
    }
  }

  void cancel() => _cancel = true;

  /// Transcribes in [language], continuing the saved partial one when it is in
  /// the same language. Downloads the Android model first if needed; with
  /// [wifiOnly] that waits for Wi-Fi.
  Future<void> start(String language, {bool wifiOnly = true}) async {
    if (_busy || !transcriptLanguageSupported(language)) return;
    _busy = true;
    _cancel = false;
    _language = language;
    final saved = state.transcript;
    var t = saved != null && saved.language == language && !saved.complete
        ? saved
        : Transcript(language: language);
    try {
      if (arg.durationMs <= 0) {
        throw const TranscribeException(TranscribeFailure.failed);
      }
      if (transcribeNeedsModel && !await whisperModelReady()) {
        if (wifiOnly && !await onWifi()) {
          throw const TranscribeException(TranscribeFailure.model);
        }
        state = TranscriptState(TranscriptPhase.downloading, transcript: saved);
        await downloadWhisperModel((v) => state = TranscriptState(
            TranscriptPhase.downloading,
            transcript: saved,
            progress: v));
      }
      final engine = ref.read(chunkTranscriberProvider);
      final files = ref.read(fileStorageServiceProvider);
      while (!_cancel) {
        final next = t.nextChunk(arg.durationMs);
        if (next == null) break;
        state = TranscriptState(TranscriptPhase.running,
            transcript: t, progress: t.progress(arg.durationMs));
        final segs = await engine(arg.path, next.$1, next.$2, language);
        t = t.withChunk(next.$2, segs, durationMs: arg.durationMs);
        await files.writeText(
            transcriptPathFor(arg.path), jsonEncode(t.toJson()));
      }
      state = TranscriptState(TranscriptPhase.idle,
          transcript: t, progress: t.progress(arg.durationMs));
      if (t.complete) unawaited(releaseWhisperModel());
    } on TranscribeException catch (e) {
      state = TranscriptState(TranscriptPhase.idle,
          transcript: t.doneMs > 0 ? t : saved, failure: e.failure);
    } catch (_) {
      state = TranscriptState(TranscriptPhase.idle,
          transcript: t.doneMs > 0 ? t : saved,
          failure: TranscribeFailure.failed);
    } finally {
      _busy = false;
    }
  }

  /// Run again after a failure, in the language that was last used.
  Future<void> retry() => start(_language, wifiOnly: false);
}
