import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/audio/audio_quality.dart';

void main() {
  group('AudioQuality.fromName', () {
    test('parses every persisted name back to its enum value', () {
      for (final q in AudioQuality.values) {
        expect(AudioQuality.fromName(q.name), q);
      }
    });

    test('defaults to medium for null or unknown names', () {
      expect(AudioQuality.fromName(null), AudioQuality.medium);
      expect(AudioQuality.fromName('legacy-value'), AudioQuality.medium);
    });

    test('the default (medium) is the clear-voice 128 kbps profile', () {
      expect(AudioQuality.medium.bitRate, 128000);
      expect(AudioQuality.medium.sampleRate, 44100);
    });
  });
}
