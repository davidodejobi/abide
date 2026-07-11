import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';

/// Provider that tracks the current theme mode
final themeModeProvider =
    NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final storage = ref.read(storageServiceProvider);
    return storage.getThemeMode();
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    ref.read(storageServiceProvider).saveThemeMode(mode);
  }
}

/// Extension to get display name for ThemeMode
extension ThemeModeExtension on ThemeMode {
  String get displayName {
    switch (this) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  IconData get icon {
    switch (this) {
      case ThemeMode.light:
        return PhosphorIcons.sun();
      case ThemeMode.dark:
        return PhosphorIcons.moon();
      case ThemeMode.system:
        return PhosphorIcons.circleHalf();
    }
  }
}
