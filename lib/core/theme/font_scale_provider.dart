import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/core/theme/font_scale.dart';

/// Tracks the reader's chosen lyric font size, persisted across launches.
/// Mirrors [themeModeProvider]'s plain-Notifier pattern.
final fontScaleProvider =
    NotifierProvider<FontScaleNotifier, FontScale>(FontScaleNotifier.new);

class FontScaleNotifier extends Notifier<FontScale> {
  @override
  FontScale build() {
    return ref.read(storageServiceProvider).getFontScale();
  }

  void setScale(FontScale scale) {
    state = scale;
    ref.read(storageServiceProvider).saveFontScale(scale);
  }
}
