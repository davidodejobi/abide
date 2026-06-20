// Recording-quality preference for voice notes. Higher quality means a higher
// AAC bitrate (clearer audio) at the cost of a larger file. The values map
// straight onto the `audio_waveforms` RecorderController's `bitRate`/`sampleRate`.

/// The named recording-quality steps a user can choose between.
enum AudioQuality {
  low(64000, 22050, 'Low', 'Smallest files, ~0.5 MB/min'),
  medium(128000, 44100, 'Medium', 'Clear voice, ~1 MB/min'),
  high(256000, 44100, 'High', 'Best quality, ~2 MB/min');

  const AudioQuality(this.bitRate, this.sampleRate, this.label, this.sizeHint);

  /// AAC bitrate in bits per second, passed to the native recorder.
  final int bitRate;

  /// Sample rate in Hz.
  final int sampleRate;

  /// Human-friendly name shown in settings.
  final String label;

  /// Short note about file size, shown under the selector so users understand
  /// the quality/size trade-off.
  final String sizeHint;

  /// Parse a persisted [name] back to an [AudioQuality], defaulting to [medium]
  /// (the clear-voice profile that fixed the muffled-recording issue).
  static AudioQuality fromName(String? name) {
    return AudioQuality.values.firstWhere(
      (q) => q.name == name,
      orElse: () => AudioQuality.medium,
    );
  }
}
