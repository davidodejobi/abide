import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/tablet/providers/recording_providers.dart';

void main() {
  test('copyWith keeps the clip path so the bar and transcript match it', () {
    const s = NotePlayback(path: '/a.m4a', loaded: true);
    final next = s.copyWith(positionMs: 1500, playing: true);
    expect(next.path, '/a.m4a');
    expect(next.positionMs, 1500);
  });
}
