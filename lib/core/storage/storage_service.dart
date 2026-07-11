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
  static const String _seededReleaseNotesKey = 'seeded_release_note_ids';
  static const String _defaultBibleLinkEditionKey = 'default_bible_link_edition';
  static const String _defaultHymnLinkEditionKey = 'default_hymn_link_edition';

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

  /// Release notes already dropped into the user's tablets, by release id.
  ///
  /// This list is the ONLY thing that decides whether a release note is created,
  /// and it is written the moment one is. That is what makes a deleted note stay
  /// deleted: the app never asks "is the note still there?", so tidying it away
  /// cannot bring it back on the next launch.
  List<String> getSeededReleaseNoteIds() {
    return _prefs.getStringList(_seededReleaseNotesKey) ?? const [];
  }

  Future<void> saveSeededReleaseNoteIds(List<String> ids) async {
    await _prefs.setStringList(_seededReleaseNotesKey, ids);
  }

  /// The user's preferred Bible edition to open when tapping a `[[bible:...]]`
  /// link that doesn't pin one. `null` means "follow my current reading
  /// position", which is what almost everyone wants.
  String? getDefaultBibleLinkEdition() {
    final value = _prefs.getString(_defaultBibleLinkEditionKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> saveDefaultBibleLinkEdition(String? editionId) async {
    if (editionId == null || editionId.isEmpty) {
      await _prefs.remove(_defaultBibleLinkEditionKey);
    } else {
      await _prefs.setString(_defaultBibleLinkEditionKey, editionId);
    }
  }

  /// The user's preferred hymn edition (today: a language code like `en` or
  /// `yo`; later: a hymnal-language pair) to open when tapping a `[[hymn:...]]`
  /// link that doesn't pin one. `null` means "follow my current reading
  /// language".
  String? getDefaultHymnLinkEdition() {
    final value = _prefs.getString(_defaultHymnLinkEditionKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> saveDefaultHymnLinkEdition(String? editionId) async {
    if (editionId == null || editionId.isEmpty) {
      await _prefs.remove(_defaultHymnLinkEditionKey);
    } else {
      await _prefs.setString(_defaultHymnLinkEditionKey, editionId);
    }
  }
}
