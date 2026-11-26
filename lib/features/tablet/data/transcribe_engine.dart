import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:flutter/services.dart';
import 'package:openbaptisthymnal/features/tablet/domain/transcript.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

/// Why a chunk could not be transcribed. The UI maps each to its own state.
enum TranscribeFailure { denied, unsupported, model, failed }

class TranscribeException implements Exception {
  const TranscribeException(this.failure);
  final TranscribeFailure failure;
}

/// Transcribes `[startMs, endMs)` of the audio at [path]. Segment times are
/// relative to the whole file.
typedef ChunkTranscriber = Future<List<TranscriptSegment>> Function(
    String path, int startMs, int endMs, String language);

const _iosChannel = MethodChannel('lumway/transcribe');

/// iOS: Apple's on-device Speech (see ios/Runner/TranscribePlugin.swift).
Future<List<TranscriptSegment>> transcribeChunkIos(
    String path, int startMs, int endMs, String language) async {
  try {
    final raw = await _iosChannel
        .invokeListMethod<Map<Object?, Object?>>('transcribe', {
      'path': path,
      'startMs': startMs,
      'endMs': endMs,
      'language': language,
    });
    return [
      for (final m in raw ?? const <Map<Object?, Object?>>[])
        TranscriptSegment(
            m['startMs'] as int, m['endMs'] as int, m['text'] as String),
    ];
  } on PlatformException catch (e) {
    throw TranscribeException(switch (e.code) {
      'denied' => TranscribeFailure.denied,
      'unsupported' => TranscribeFailure.unsupported,
      _ => TranscribeFailure.failed,
    });
  }
}

// ---- Android: whisper.cpp small, downloaded on demand --------------------

const whisperModelBytes = 190085487;
const whisperModelUrl =
    'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small-q5_1.bin';

/// Needs a model download first (Android only; iOS uses the system engine).
bool get transcribeNeedsModel => Platform.isAndroid;

Future<File> _modelFile() async => File(p.join(
    (await getApplicationSupportDirectory()).path, 'ggml-small-q5_1.bin'));

Future<bool> whisperModelReady() async => (await _modelFile()).existsSync();

Future<bool> onWifi() async {
  final c = await Connectivity().checkConnectivity();
  return c.contains(ConnectivityResult.wifi) ||
      c.contains(ConnectivityResult.ethernet);
}

/// Downloads the model next to the app's other support files, reporting 0..1.
/// Written to `.part` and renamed only when the byte count matches, so a
/// dropped connection never leaves a model that looks installed.
Future<void> downloadWhisperModel(void Function(double) onProgress) async {
  final file = await _modelFile();
  final part = File('${file.path}.part');
  final client = HttpClient();
  try {
    final res = await (await client.getUrl(Uri.parse(whisperModelUrl))).close();
    if (res.statusCode != 200) {
      throw const TranscribeException(TranscribeFailure.model);
    }
    final total = res.contentLength > 0 ? res.contentLength : whisperModelBytes;
    final sink = part.openWrite();
    var got = 0;
    try {
      await for (final b in res) {
        sink.add(b);
        got += b.length;
        onProgress((got / total).clamp(0.0, 1.0));
      }
    } finally {
      await sink.close();
    }
    if (got != total) throw const TranscribeException(TranscribeFailure.model);
    await part.rename(file.path);
  } on TranscribeException {
    rethrow;
  } catch (_) {
    throw const TranscribeException(TranscribeFailure.model);
  } finally {
    client.close(force: true);
    if (part.existsSync()) part.deleteSync();
  }
}

final _noise = RegExp(r'^[\[(].*[\])]$');

Future<List<TranscriptSegment>> transcribeChunkWhisper(
    String path, int startMs, int endMs, String language) async {
  if (!await whisperModelReady()) {
    throw const TranscribeException(TranscribeFailure.model);
  }
  final tmp = await getTemporaryDirectory();
  final wav = p.join(
      tmp.path, 'chunk_${startMs}_${p.basenameWithoutExtension(path)}.wav');
  try {
    // ffmpeg cuts the slice (16 kHz mono, what whisper reads) out of the
    // recording so only this chunk is held in memory.
    final s = startMs / 1000, d = (endMs - startMs) / 1000;
    final cut = await FFmpegKit.execute(
        '-y -ss $s -t $d -i "$path" -ar 16000 -ac 1 -c:a pcm_s16le "$wav"');
    if (!ReturnCode.isSuccess(await cut.getReturnCode())) {
      throw const TranscribeException(TranscribeFailure.failed);
    }
    final res = await const Whisper(model: WhisperModel.small).transcribe(
      transcribeRequest: TranscribeRequest(
        audio: wav,
        language: language,
        threads: 4,
        suppressNonSpeechTokens: true,
        keepModelLoaded: true,
      ),
      modelPath: (await _modelFile()).path,
    );
    return [
      for (final seg in res.segments ?? const <WhisperTranscribeSegment>[])
        if (seg.text.trim().isNotEmpty && !_noise.hasMatch(seg.text.trim()))
          TranscriptSegment(startMs + seg.fromTs.inMilliseconds,
              startMs + seg.toTs.inMilliseconds, seg.text.trim()),
    ];
  } on TranscribeException {
    rethrow;
  } catch (_) {
    throw const TranscribeException(TranscribeFailure.failed);
  } finally {
    for (final f in [wav, '$wav.wav']) {
      final file = File(f);
      if (file.existsSync()) file.deleteSync();
    }
  }
}

/// Frees the model parked in memory once a transcript is finished.
Future<void> releaseWhisperModel() async {
  if (Platform.isAndroid) {
    try {
      await const Whisper(model: WhisperModel.small).releaseModel();
    } catch (_) {}
  }
}

ChunkTranscriber platformChunkTranscriber() =>
    Platform.isIOS ? transcribeChunkIos : transcribeChunkWhisper;
