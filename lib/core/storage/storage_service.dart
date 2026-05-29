import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _themeKey = 'theme_mode';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _userNameKey = 'user_name';

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

  /// Mark onboarding as complete (or reset)
  Future<void> saveOnboardingComplete(bool complete) async {
    await _prefs.setBool(_onboardingCompleteKey, complete);
  }

  /// Whether the user has finished onboarding
  bool isOnboardingComplete() {
    return _prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  /// Save the user's chosen name
  Future<void> saveUserName(String name) async {
    await _prefs.setString(_userNameKey, name);
  }

  /// Get the user's chosen name (null if not set)
  String? getUserName() {
    return _prefs.getString(_userNameKey);
  }
}
