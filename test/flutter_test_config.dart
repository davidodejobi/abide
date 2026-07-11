import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';

/// Flutter runs this automatically for every test under `test/`, so it wraps
/// the whole suite, not just the goldens.
Future<void> testExecutable(FutureOr<void> Function() testMain) {
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      theme: AppTheme.darkTheme,
      // Platform goldens (real fonts, real shadows) are host-dependent, so a
      // PNG seeded on macOS never matches one rendered on ubuntu. We only keep
      // CI goldens, which force the Ahem font and drop shadows, making the
      // output byte-identical across machines. That is the whole reason goldens
      // can be gated in CI at all.
      //
      // The tradeoff is real and worth stating: the committed PNGs show block
      // text rather than actual glyphs. They catch layout, size, colour and
      // state regressions — not typography.
      platformGoldensConfig: const PlatformGoldensConfig(enabled: false),
      ciGoldensConfig: CiGoldensConfig(
        filePathResolver: (fileName, _) async => '../goldens/$fileName.png',
        // Gradients, icons and anti-aliased curves still drift by a sub-pixel
        // across OS versions. 2% absorbs that; a genuine regression moves far
        // more than 2% of the pixels.
        diffThreshold: 0.02,
      ),
    ),
    run: () async => testMain(),
  );
}
