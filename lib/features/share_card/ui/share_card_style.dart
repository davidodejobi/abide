import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';

/// A look for a shareable card (Figma M4-04): the road crop on top (or none),
/// and the panel colours beneath. A card is an image that leaves the app, so
/// its colours are fixed to the preset and do not follow the app theme.
class ShareCardStyle {
  const ShareCardStyle({
    required this.id,
    required this.label,
    required this.tone,
    this.roadAsset,
  });

  final String id;
  final String label;

  /// Colour set for the panel and text.
  final LumColors tone;

  /// Baked road scene shown across the top, or null for a plain card.
  final String? roadAsset;

  static const List<ShareCardStyle> presets = [
    ShareCardStyle(
      id: 'day',
      label: NotesStrings.dayRoad,
      tone: LumColors.light,
      roadAsset: 'assets/images/road/bg_light.png',
    ),
    ShareCardStyle(
      id: 'night',
      label: NotesStrings.nightRoad,
      tone: LumColors.dark,
      roadAsset: 'assets/images/road/bg_evening_dark.png',
    ),
    ShareCardStyle(
      id: 'plain',
      label: NotesStrings.plain,
      tone: LumColors.light,
    ),
  ];
}

/// The shapes a card exports as (Figma M4-05): a tall status card or a square.
enum ShareCardFormat {
  status(9 / 16, NotesStrings.formatStatus),
  square(1, NotesStrings.formatSquare);

  const ShareCardFormat(this.aspect, this.label);

  final double aspect;
  final String label;
}
