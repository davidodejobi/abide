import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _themeKey = 'theme_mode';

  /// Save theme mode
  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeKey, mode.name);
  }

  /// Get theme mode
  ThemeMode getThemeMode() {
    final modeName = _prefs.getString(_themeKey);
    if (modeName == null) return ThemeMode.system;

    return ThemeMode.values.firstWhere(
      (e) => e.name == modeName,
      orElse: () => ThemeMode.system,
    );
  }
}
