import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/features/hymn/providers/favorites_provider.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';

/// Every hymn pack bundled in assets/hymnal/languages. Adding a pack later is
/// one more code here (plus its name in HymnStrings.languageName).
const kHymnPacks = ['en', 'yo'];

const _prefsKey = 'hymn_languages_enabled';

/// The hymn languages the person turned on, in pack order. Opt-in: English
/// only until they add more, except that anyone already using Yorùbá keeps it.
final enabledHymnLanguagesProvider =
    NotifierProvider<EnabledHymnLanguagesNotifier, List<String>>(
        EnabledHymnLanguagesNotifier.new);

class EnabledHymnLanguagesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    // Opening a hymn in a language that is off (a note link, an old
    // favourite) turns that language on, so Songs never shows a hidden one.
    ref.listen<String>(languageProvider, (_, lang) {
      if (kHymnPacks.contains(lang) && !state.contains(lang)) {
        setEnabled(lang, true);
      }
    });
    final saved = prefs.getStringList(_prefsKey)?.toSet() ?? {};
    final enabled = kHymnPacks.where(saved.contains).toList();
    if (enabled.isNotEmpty) return enabled;

    // First read. The onboarding reading language is saved into
    // languageProvider, so it covers 'yo' picked in onboarding.
    final usesYoruba = ref.read(languageProvider) == 'yo' ||
        PlatformDispatcher.instance.locale.languageCode == 'yo' ||
        ref.read(favoritesProvider).any((k) => k.startsWith('yo:'));
    final initial = usesYoruba ? ['en', 'yo'] : ['en'];
    // Save it now, or a later relaunch would recompute and drop Yorùbá.
    prefs.setStringList(_prefsKey, initial);
    return initial;
  }

  /// Turns [code] on or off. The last language on, and the language the
  /// Songs tab is showing, can't be turned off (switching it under an open
  /// hymn page would show a different song with the same id).
  Future<void> setEnabled(String code, bool on) async {
    if (!kHymnPacks.contains(code)) return;
    if (!on && code == ref.read(languageProvider)) return;
    final next = kHymnPacks
        .where((c) => c == code ? on : state.contains(c))
        .toList();
    if (next.isEmpty) return;
    state = next;
    await ref.read(sharedPreferencesProvider).setStringList(_prefsKey, next);
  }
}
