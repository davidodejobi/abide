import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:openbaptisthymnal/features/tablet/domain/transcript.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Why a run stopped. The UI maps each to its own state.
enum TranscribeFailure {
  denied,
  unsupported,
  model,
  failed,
  cancelled,
  waitingForWifi,
  deviceUnsupported,
}

class TranscribeException implements Exception {
  const TranscribeException(this.failure);
  final TranscribeFailure failure;
}

/// Transcribes `[startMs, endMs)` of the audio at [path]. Segment times are
/// relative to the whole file.
typedef ChunkTranscriber = Future<List<TranscriptSegment>> Function(
    String path, int startMs, int endMs, String language);

/// The real length of the audio, read natively.
typedef DurationProbe = Future<int> Function(String path);

/// One `lumway/transcribe` channel on both platforms: iOS (Swift in
/// AppDelegate.swift) and Android (packages/lumway_whisper).
const _channel = MethodChannel('lumway/transcribe');

// ---- one run at a time -----------------------------------------------------

Future<void> _tail = Future.value();

/// Runs [job] after every earlier job has finished, so only one transcription
/// uses the engine at a time and a second one waits its turn.
Future<T> runSerially<T>(Future<T> Function() job) {
  final done = Completer<T>();
  final prev = _tail;
  _tail = done.future.then((_) {}, onError: (_) {});
  prev.then((_) async {
    try {
      done.complete(await job());
    } catch (e, s) {
      done.completeError(e, s);
    }
  });
  return done.future;
}

// ---- engine calls ------------------------------------------------------------

TranscribeException _mapError(PlatformException e) =>
    TranscribeException(switch (e.code) {
      'denied' => TranscribeFailure.denied,
      'unsupported' => TranscribeFailure.unsupported,
      _ => TranscribeFailure.failed, // includes "unavailable": retryable
    });

Future<int> probeDurationMs(String path) async {
  try {
    return await _channel.invokeMethod<int>('duration', {'path': path}) ?? 0;
  } on PlatformException catch (e) {
    throw _mapError(e);
  }
}

Future<List<TranscriptSegment>> _invokeChunk(String path, int startMs,
    int endMs, String language, Map<String, Object?> extra) async {
  try {
    final raw = await _channel
        .invokeListMethod<Map<Object?, Object?>>('transcribe', {
      'path': path,
      'startMs': startMs,
      'endMs': endMs,
      'language': language,
      ...extra,
    });
    return [
      for (final m in raw ?? const <Map<Object?, Object?>>[])
        TranscriptSegment(
            m['startMs'] as int, m['endMs'] as int, m['text'] as String),
    ];
  } on PlatformException catch (e) {
    throw _mapError(e);
  }
}

/// iOS: Apple's on-device Speech.
Future<List<TranscriptSegment>> transcribeChunkIos(
        String path, int startMs, int endMs, String language) =>
    _invokeChunk(path, startMs, endMs, language, const {});

/// Android: whisper.cpp small, model downloaded on demand.
Future<List<TranscriptSegment>> transcribeChunkWhisper(
    String path, int startMs, int endMs, String language) async {
  if (!await whisperModelReady()) {
    throw const TranscribeException(TranscribeFailure.model);
  }
  return _invokeChunk(path, startMs, endMs, language,
      {'modelPath': (await _modelFile()).path});
}

/// Whether this phone can transcribe on-device: always on iOS (the system
/// engine); on Android a 64-bit processor and at least 3 GB of memory.
Future<bool> transcribeSupported() async {
  if (!Platform.isAndroid) return true;
  try {
    return await _channel.invokeMethod<bool>('supported') ?? false;
  } catch (_) {
    return false;
  }
}

/// Frees what the engine holds (the Android model) once a run ends.
Future<void> releaseEngine() async {
  if (!Platform.isAndroid) return;
  try {
    await _channel.invokeMethod<void>('release');
  } catch (_) {}
}

ChunkTranscriber platformChunkTranscriber() =>
    Platform.isIOS ? transcribeChunkIos : transcribeChunkWhisper;

// ---- Android model -----------------------------------------------------------

const whisperModelBytes = 190085487;
const _modelSha256 =
    'ae85e4a935d7a567bd102fe55afc16bb595bdb618e11b2fc7591bc08120411bb';
// Pinned to a commit of ggerganov/whisper.cpp on Hugging Face, not main.
const whisperModelUrl = 'https://huggingface.co/ggerganov/whisper.cpp/resolve/'
    '5359861c739e955e79d9a303bcbc70fb988958b1/ggml-small-q5_1.bin';

/// Needs a model download first (Android only; iOS uses the system engine).
bool get transcribeNeedsModel => Platform.isAndroid;

Future<File> _modelFile() async => File(p.join(
    (await getApplicationSupportDirectory()).path, 'ggml-small-q5_1.bin'));

bool _modelVerified = false;

Future<bool> _sha256Matches(File f) async =>
    (await sha256.bind(f.openRead()).first).toString() == _modelSha256;

/// True only for a file of the exact length whose SHA-256 matches the pinned
/// one (checked once per launch). A mismatch is deleted.
Future<bool> whisperModelReady() async {
  final file = await _modelFile();
  if (!file.existsSync()) return false;
  if (file.lengthSync() != whisperModelBytes) {
    file.deleteSync();
    _modelVerified = false;
    return false;
  }
  if (_modelVerified) return true;
  if (await _sha256Matches(file)) return _modelVerified = true;
  file.deleteSync();
  return false;
}

Future<bool> onWifi() async {
  final c = await Connectivity().checkConnectivity();
  return c.contains(ConnectivityResult.wifi) ||
      c.contains(ConnectivityResult.ethernet);
}

Future<void>? _download;
bool _downloadCancelled = false;
final _downloadListeners = <void Function(double)>{};

/// Stops the model download in progress (if any).
void cancelModelDownload() => _downloadCancelled = true;

/// Downloads the model, reporting 0..1. One download runs at a time: a second
/// caller joins it. Times out after 30 s without a connection or without data,
/// and stops when [cancelModelDownload] is called.
Future<void> downloadWhisperModel(void Function(double) onProgress) {
  _downloadListeners.add(onProgress);
  return (_download ??= _runDownload().whenComplete(() {
    _download = null;
    _downloadListeners.clear();
  }))
      .whenComplete(() => _downloadListeners.remove(onProgress));
}

Future<void> _runDownload() async {
  _downloadCancelled = false;
  final file = await _modelFile();
  final part = File('${file.path}.part');
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  try {
    final req = await client.getUrl(Uri.parse(whisperModelUrl));
    final res = await req.close().timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw const TranscribeException(TranscribeFailure.model);
    }
    final sink = part.openWrite();
    var got = 0;
    try {
      await for (final b in res.timeout(const Duration(seconds: 30))) {
        if (_downloadCancelled) {
          throw const TranscribeException(TranscribeFailure.cancelled);
        }
        sink.add(b);
        got += b.length;
        final v = (got / whisperModelBytes).clamp(0.0, 1.0);
        for (final l in [..._downloadListeners]) {
          l(v);
        }
      }
    } finally {
      await sink.close();
    }
    if (got != whisperModelBytes || !await _sha256Matches(part)) {
      throw const TranscribeException(TranscribeFailure.model);
    }
    await part.rename(file.path);
    _modelVerified = true;
  } on TranscribeException {
    rethrow;
  } catch (_) {
    throw const TranscribeException(TranscribeFailure.model);
  } finally {
    client.close(force: true);
    if (part.existsSync()) part.deleteSync();
  }
}
