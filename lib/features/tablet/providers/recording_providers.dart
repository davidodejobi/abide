import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';

const _consentKey = 'notes_recording_consent_seen';

/// Whether the one-time recording privacy note has been accepted.
final recordingConsentProvider =
    NotifierProvider<RecordingConsentNotifier, bool>(
  RecordingConsentNotifier.new,
);

class RecordingConsentNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(_consentKey) ?? false;

  Future<void> accept() async {
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(_consentKey, true);
  }
}

/// Audio focus between the pinned player and the in-note audio block, which
/// own separate players: whichever starts calls the other's stop.
// ponytail: two global slots; a shared audio service if a third player appears.
VoidCallback? stopBlockAudio;
VoidCallback? stopPinnedAudio;

class NotePlayback {
  const NotePlayback({
    this.path,
    this.loaded = false,
    this.playing = false,
    this.positionMs = 0,
    this.durationMs = 0,
    this.speed = 100,
  });

  final String? path; // the clip this state belongs to
  final bool loaded;
  final bool playing;
  final int positionMs;
  final int durationMs;
  final int speed; // percent

  NotePlayback copyWith({
    bool? loaded,
    bool? playing,
    int? positionMs,
    int? durationMs,
    int? speed,
  }) =>
      NotePlayback(
        loaded: loaded ?? this.loaded,
        playing: playing ?? this.playing,
        positionMs: positionMs ?? this.positionMs,
        durationMs: durationMs ?? this.durationMs,
        speed: speed ?? this.speed,
      );
}

/// Drives the pinned player bar and `t:` links for the open note's recording.
final notePlaybackProvider =
    NotifierProvider<NotePlaybackNotifier, NotePlayback>(
  NotePlaybackNotifier.new,
);

class NotePlaybackNotifier extends Notifier<NotePlayback> {
  PlayerController? _player;
  String? _path;
  final _subs = <StreamSubscription<Object?>>[];

  @override
  NotePlayback build() {
    ref.onDispose(release);
    return const NotePlayback();
  }

  /// Points the player at [path]; the native player is only created on the
  /// first play or seek. A no-op when [path] is already the loaded clip.
  void load(String path, {int durationMs = 0, int speed = 100}) {
    if (_path == path) return;
    release();
    _path = path;
    state = NotePlayback(
        path: path, durationMs: durationMs, speed: speed, loaded: true);
  }

  /// Releases only when [path] is the clip this editor loaded, so one note
  /// closing never kills the player another note is using.
  void releaseIf(String? path) {
    if (path != null && _path == path) {
      release();
      state = const NotePlayback();
    }
  }

  Future<PlayerController?> _ready() async {
    final path = _path;
    if (path == null) return null;
    var p = _player;
    if (p == null) {
      p = _player = PlayerController();
      await p.preparePlayer(path: path, shouldExtractWaveform: false);
      _subs
        ..add(p.onCurrentDurationChanged.listen((ms) {
          state = state.copyWith(positionMs: ms);
        }))
        ..add(p.onCompletion.listen((_) {
          state = state.copyWith(playing: false);
          // A finished clip must be prepared again before the next play.
          p?.preparePlayer(path: path, shouldExtractWaveform: false);
        }));
      if (state.durationMs == 0 && p.maxDuration > 0) {
        state = state.copyWith(durationMs: p.maxDuration);
      }
    }
    return p;
  }

  bool _busy = false;

  Future<void> toggle() async {
    if (_busy) return;
    _busy = true;
    try {
      final p = await _ready();
      if (p == null) return;
      if (state.playing) {
        await p.pausePlayer();
        state = state.copyWith(playing: false);
        return;
      }
      stopBlockAudio?.call();
      stopBlockAudio = null;
      stopPinnedAudio = pause;
      await p.startPlayer();
      await p.setRate(state.speed / 100);
      state = state.copyWith(playing: true);
    } catch (_) {
      // Unplayable file: stay at rest.
    } finally {
      _busy = false;
    }
  }

  Future<void> pause() async {
    try {
      await _player?.pausePlayer();
    } catch (_) {}
    state = state.copyWith(playing: false);
  }

  Future<void> seekTo(int ms) async {
    try {
      final p = await _ready();
      if (p == null) return;
      final max = state.durationMs > 0 ? state.durationMs : p.maxDuration;
      final to = max > 0 ? ms.clamp(0, max) : ms < 0 ? 0 : ms;
      await p.seekTo(to);
      state = state.copyWith(positionMs: to);
    } catch (_) {}
  }

  Future<void> skip(int deltaMs) => seekTo(state.positionMs + deltaMs);

  /// A tapped `t:` link: jump there and play.
  Future<void> seekAndPlay(int seconds) async {
    await seekTo(seconds * 1000);
    if (!state.playing) await toggle();
  }

  Future<void> setSpeed(int percent) async {
    state = state.copyWith(speed: percent);
    if (state.playing) await _player?.setRate(percent / 100);
  }

  /// Stops and forgets the loaded clip. Does not touch [state] (it is also the
  /// provider's dispose hook); [releaseIf] resets it.
  void release() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    if (stopPinnedAudio == pause) stopPinnedAudio = null;
    _player?.dispose();
    _player = null;
    _path = null;
  }
}
