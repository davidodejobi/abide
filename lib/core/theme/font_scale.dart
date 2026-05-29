// Reading-text size preference for hymn lyrics. Discrete, labelled steps power
// a snapping slider in the UI; the [scale] multiplies the base lyric font size
// and composes on top of the OS text-scaling setting.

/// The named font-size steps a reader can choose between.
enum FontScale {
  small(0.875, 'Small'),
  medium(1.0, 'Medium'),
  large(1.15, 'Large'),
  extraLarge(1.3, 'Extra Large'),
  huge(1.5, 'Huge');

  const FontScale(this.scale, this.label);

  /// Multiplier applied to the base lyric font size.
  final double scale;

  /// Human-friendly name shown in settings and the size picker.
  final String label;

  /// Parse a persisted [name] back to a [FontScale], defaulting to [medium].
  static FontScale fromName(String? name) {
    return FontScale.values.firstWhere(
      (s) => s.name == name,
      orElse: () => FontScale.medium,
    );
  }
}
