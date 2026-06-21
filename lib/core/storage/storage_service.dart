import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/audio/audio_quality.dart';
import 'package:openbaptisthymnal/core/theme/font_scale.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _themeKey = 'theme_mode';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _userNameKey = 'user_name';
  static const String _fontScaleKey = 'font_scale';
  static const String _audioQualityKey = 'audio_quality';
  static const String _welcomeNoteSeededKey = 'welcome_note_seeded';

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

  /// Save the reading font-size preference
  Future<void> saveFontScale(FontScale scale) async {
    await _prefs.setString(_fontScaleKey, scale.name);
  }

  /// Get the reading font-size preference (defaults to medium)
  FontScale getFontScale() {
    return FontScale.fromName(_prefs.getString(_fontScaleKey));
  }

  /// Save the voice-note recording quality preference
  Future<void> saveAudioQuality(AudioQuality quality) async {
    await _prefs.setString(_audioQualityKey, quality.name);
  }

  /// Get the voice-note recording quality preference (defaults to medium)
  AudioQuality getAudioQuality() {
    return AudioQuality.fromName(_prefs.getString(_audioQualityKey));
  }

  /// Mark that the example welcome note has been created for this install.
  /// One-shot idempotency guard so we never re-seed the note on later runs.
  Future<void> saveWelcomeNoteSeeded(bool seeded) async {
    await _prefs.setBool(_welcomeNoteSeededKey, seeded);
  }

  /// Whether the example welcome note has already been seeded.
  bool isWelcomeNoteSeeded() {
    return _prefs.getBool(_welcomeNoteSeededKey) ?? false;
  }
}
