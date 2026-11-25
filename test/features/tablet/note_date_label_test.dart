import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/tablet/domain/note_date_label.dart';

void main() {
  final now = DateTime(2026, 11, 25, 15, 0); // a Wednesday

  test('today shows a 12 hour time', () {
    expect(noteDateLabel(DateTime(2026, 11, 25, 6, 40), now), 'Today, 6:40');
    expect(noteDateLabel(DateTime(2026, 11, 25, 0, 5), now), 'Today, 12:05');
    expect(noteDateLabel(DateTime(2026, 11, 25, 13, 0), now), 'Today, 1:00');
  });

  test('yesterday, weekday, then date', () {
    expect(noteDateLabel(DateTime(2026, 11, 24, 23, 59), now), 'Yesterday');
    expect(noteDateLabel(DateTime(2026, 11, 22), now), 'Sunday');
    expect(noteDateLabel(DateTime(2026, 11, 18), now), '18 Nov');
    expect(noteDateLabel(DateTime(2025, 3, 2), now), '2 Mar 2025');
  });
}
