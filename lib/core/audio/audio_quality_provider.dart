import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/audio/audio_quality.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';

/// Tracks the user's chosen voice-note recording quality, persisted across
/// launches. Mirrors [fontScaleProvider]'s plain-Notifier pattern.
final audioQualityProvider =
    NotifierProvider<AudioQualityNotifier, AudioQuality>(
  AudioQualityNotifier.new,
);

class AudioQualityNotifier extends Notifier<AudioQuality> {
  @override
  AudioQuality build() {
    return ref.read(storageServiceProvider).getAudioQuality();
  }

  void setQuality(AudioQuality quality) {
    state = quality;
    ref.read(storageServiceProvider).saveAudioQuality(quality);
  }
}
