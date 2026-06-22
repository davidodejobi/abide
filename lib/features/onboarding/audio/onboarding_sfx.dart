import 'dart:developer' as developer;

import 'package:audioplayers/audioplayers.dart';

/// One-stop sound-effects service for the onboarding flow.
///
/// Drop audio files into `assets/audio/onboarding/` with the filenames declared
/// below. If a file is missing the call quietly no-ops — the visual flow keeps
/// running so we can ship code before audio is finalized.
class OnboardingSfx {
  OnboardingSfx();

  static const _basePath = 'audio/onboarding';

  // Filenames the screens reference. Match these when adding files to
  // assets/audio/onboarding/.
  static const _welcomeChime = '$_basePath/welcome_chime.mp3';
  static const _penTick = '$_basePath/pen_tick.mp3';
  static const _revealWhoosh = '$_basePath/reveal_whoosh.mp3';
  static const _paperTap = '$_basePath/paper_tap.mp3';
  static const _pencilLoop = '$_basePath/pencil_draw_loop.mp3';
  static const _dayBloom = '$_basePath/day_bloom.mp3';
  static const _nightBloom = '$_basePath/night_bloom.mp3';
  static const _pageTurn = '$_basePath/page_turn.mp3';

  // Mix levels — kept low so SFX sit gently under the piano bed.
  static const double _volChime = 0.28;
  static const double _volTick = 0.09;
  static const double _volWhoosh = 0.16;
  static const double _volTap = 0.20;
  static const double _volPencil = 0.22;
  static const double _volBloom = 0.28;
  static const double _volPage = 0.16;

  // One dedicated player per overlapping sound so they can stack cleanly.
  final AudioPlayer _chimePlayer = AudioPlayer();
  final AudioPlayer _tickPlayer = AudioPlayer();
  final AudioPlayer _whooshPlayer = AudioPlayer();
  final AudioPlayer _tapPlayer = AudioPlayer();
  final AudioPlayer _pencilPlayer = AudioPlayer();
  final AudioPlayer _bloomPlayer = AudioPlayer();
  final AudioPlayer _pagePlayer = AudioPlayer();

  Future<void> _safePlay(
    AudioPlayer player,
    String asset, {
    required double volume,
    bool loop = false,
  }) async {
    try {
      await player.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
        ),
        android: AudioContextAndroid(
          usageType: AndroidUsageType.media,
        ),
      ));
      await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
      await player.setVolume(volume);
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (e, st) {
      developer.log(
        'SFX playback failed: $asset — $e',
        name: 'onboarding',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> welcomeChime() =>
      _safePlay(_chimePlayer, _welcomeChime, volume: _volChime);

  /// Resolve chime at the end of onboarding. Same file, slightly higher pitch
  /// when the platform supports it; otherwise just replays the chime.
  Future<void> resolveChime() async {
    try {
      await _chimePlayer.setPlaybackRate(1.12);
    } catch (_) {}
    await _safePlay(_chimePlayer, _welcomeChime, volume: _volChime);
  }

  /// Start the typewriter tick loop. Call when a TypewriterText begins typing
  /// and pair with [penTickStop] when it finishes.
  Future<void> penTickStart() =>
      _safePlay(_tickPlayer, _penTick, volume: _volTick, loop: true);

  Future<void> penTickStop() async {
    try {
      await _tickPlayer.stop();
    } catch (_) {}
  }

  Future<void> revealWhoosh() =>
      _safePlay(_whooshPlayer, _revealWhoosh, volume: _volWhoosh);

  Future<void> paperTap() =>
      _safePlay(_tapPlayer, _paperTap, volume: _volTap);

  /// Start the pencil scratch loop under a hand-drawn stroke.
  Future<void> pencilDrawStart() =>
      _safePlay(_pencilPlayer, _pencilLoop, volume: _volPencil, loop: true);

  Future<void> pencilDrawStop() async {
    try {
      await _pencilPlayer.stop();
    } catch (_) {}
  }

  Future<void> dayBloom() =>
      _safePlay(_bloomPlayer, _dayBloom, volume: _volBloom);

  Future<void> nightBloom() =>
      _safePlay(_bloomPlayer, _nightBloom, volume: _volBloom);

  Future<void> pageTurn() =>
      _safePlay(_pagePlayer, _pageTurn, volume: _volPage);

  Future<void> dispose() async {
    await Future.wait([
      _chimePlayer.dispose(),
      _tickPlayer.dispose(),
      _whooshPlayer.dispose(),
      _tapPlayer.dispose(),
      _pencilPlayer.dispose(),
      _bloomPlayer.dispose(),
      _pagePlayer.dispose(),
    ]);
  }
}
