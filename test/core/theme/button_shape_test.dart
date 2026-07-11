import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';

/// Every button in the app is an 8px rounded rectangle.
///
/// [FilledButton] had no theme entry at all, so it silently fell back to
/// Material 3's default -- a StadiumBorder pill. Nothing failed and nothing
/// warned; it just quietly looked like it came from a different app, in the
/// Bible picker, the folder and tag pickers, the audio recorder, the share card,
/// and anywhere a FilledButton sat next to an OutlinedButton.
///
/// A default you did not choose is still a decision, and this is the test that
/// makes the next one explicit.
void main() {
  const expected = 8.0;

  BorderRadius radiusOf(OutlinedBorder? shape) {
    expect(
      shape,
      isA<RoundedRectangleBorder>(),
      reason: 'a pill (StadiumBorder) is what this test exists to catch',
    );
    return (shape! as RoundedRectangleBorder).borderRadius as BorderRadius;
  }

  for (final entry in {
    'light': AppTheme.lightTheme,
    'dark': AppTheme.darkTheme,
  }.entries) {
    group('Given the ${entry.key} theme', () {
      final theme = entry.value;

      group('When the button shapes are resolved', () {
        test('Then filled, outlined and elevated all share one radius', () {
          final shapes = <String, OutlinedBorder?>{
            'filled': theme.filledButtonTheme.style?.shape?.resolve({}),
            'outlined': theme.outlinedButtonTheme.style?.shape?.resolve({}),
            'elevated': theme.elevatedButtonTheme.style?.shape?.resolve({}),
          };

          for (final shape in shapes.entries) {
            expect(
              shape.value,
              isNotNull,
              reason: '${shape.key} has no themed shape, so it will fall back '
                  'to the Material default and mismatch the others',
            );
            expect(
              radiusOf(shape.value).topLeft.x,
              expected,
              reason: '${shape.key} button radius',
            );
          }
        });
      });
    });
  }
}
