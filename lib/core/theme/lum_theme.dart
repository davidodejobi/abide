import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'lum_tokens.dart';

export 'lum_tokens.dart';

/// `context.lum` gives the Lumway colour tokens for the current brightness.
extension LumContext on BuildContext {
  LumColors get lum => Theme.of(this).brightness == Brightness.dark
      ? LumColors.dark
      : LumColors.light;
}

/// Material roles built from the Lumway tokens, so stock widgets on screens
/// not yet rebuilt pick up the new palette.
///
/// Material surfaces (dialogs, sheets, menus, snackbars) must be opaque, so
/// translucent tokens are composited over the page colour first. The see-through
/// tokens (`bgSurface`, `glassFill`) are for the glass nav layer only.
abstract final class LumTheme {
  static ColorScheme colorScheme(Brightness b) {
    final c = b == Brightness.dark ? LumColors.dark : LumColors.light;
    Color solid(Color t) => Color.alphaBlend(t, c.bgPage);
    return ColorScheme(
      brightness: b,
      primary: c.bgPrimary,
      onPrimary: c.textOnPrimary,
      primaryContainer: solid(c.bgPrimaryContainer),
      onPrimaryContainer: c.textOnPrimaryContainer,
      secondary: c.buttonGoldBottom,
      onSecondary: c.buttonOnGold,
      secondaryContainer: solid(c.bgAccentContainer),
      onSecondaryContainer: c.textOnAccentContainer,
      tertiary: c.iconSuccess,
      onTertiary: c.textOnPrimary,
      tertiaryContainer: solid(c.bgSuccessContainer),
      onTertiaryContainer: c.textOnSuccessContainer,
      error: c.bgDanger,
      onError: c.textOnDanger,
      errorContainer: solid(c.bgDangerContainer),
      onErrorContainer: c.textOnDangerContainer,
      surface: c.glassFillOpaque,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.bgPage,
      surfaceContainerLow: c.glassFillOpaque,
      surfaceContainer: c.glassFillOpaque,
      surfaceContainerHigh: solid(c.bgElevated),
      surfaceContainerHighest: solid(c.bgElevated),
      outline: c.borderStrong,
      outlineVariant: c.borderSubtle,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: c.bgInverse,
      onInverseSurface: c.textInverse,
      inversePrimary: c.textAccent,
      surfaceTint: Colors.transparent,
    );
  }

  static const TextTheme textTheme = TextTheme(
    displayLarge: LumText.roadDisplayMedium56,
    displayMedium: LumText.largeTitle,
    displaySmall: LumText.title1,
    headlineLarge: LumText.largeTitle,
    headlineMedium: LumText.title1,
    headlineSmall: LumText.title2,
    titleLarge: LumText.title3,
    titleMedium: LumText.headline,
    titleSmall: LumText.subheadlineEmphasized,
    bodyLarge: LumText.body,
    bodyMedium: LumText.subheadline,
    bodySmall: LumText.footnote,
    labelLarge: LumText.subheadlineEmphasized,
    labelMedium: LumText.footnoteEmphasized,
    labelSmall: LumText.caption,
  );

  /// Adds the bundled OFL font licences to the licences page.
  static void registerFontLicenses() {
    LicenseRegistry.addLicense(() async* {
      for (final (family, file) in const [
        ('Inter', 'Inter'),
        ('Gentium Book Plus', 'GentiumBookPlus'),
        ('Bricolage Grotesque', 'BricolageGrotesque'),
      ]) {
        final text =
            await rootBundle.loadString('assets/fonts/licenses/$file-OFL.txt');
        yield LicenseEntryWithLineBreaks([family], text);
      }
    });
  }
}
