import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/features/bible/domain/highlight_palette.dart';

/// Maps the persisted highlight keys onto the Lumway highlight tokens, so the
/// swatches follow light and dark mode. The keys in the database never change.
Color highlightColorFor(LumColors c, HighlightColor h) => switch (h) {
      HighlightColor.yellow => c.highlightSun,
      HighlightColor.green => c.highlightLeaf,
      HighlightColor.blue => c.highlightSky,
      HighlightColor.pink => c.highlightRose,
      HighlightColor.purple => c.highlightLilac,
    };
