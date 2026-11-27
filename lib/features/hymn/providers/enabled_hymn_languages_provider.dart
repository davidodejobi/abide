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
    final saved = prefs.getStringList(_prefsKey)?.toSet() ?? {};
    final enabled = kHymnPacks.where(saved.contains).toList();
    if (enabled.isNotEmpty) return enabled;

    // First read. The onboarding reading language is saved into
    // languageProvider, so it covers 'yo' picked in onboarding.
    final usesYoruba = ref.read(languageProvider) == 'yo' ||
        PlatformDispatcher.instance.locale.languageCode == 'yo' ||
        ref.read(favoritesProvider).any((k) => k.startsWith('yo:'));
    return usesYoruba ? ['en', 'yo'] : ['en'];
  }

  /// Turns [code] on or off. The last language on can't be turned off. If the
  /// selected song language goes off, the selection moves to the first on.
  Future<void> setEnabled(String code, bool on) async {
    if (!kHymnPacks.contains(code)) return;
    final next = kHymnPacks
        .where((c) => c == code ? on : state.contains(c))
        .toList();
    if (next.isEmpty) return;
    state = next;
    if (!next.contains(ref.read(languageProvider))) {
      ref.read(languageProvider.notifier).state = next.first;
    }
    await ref.read(sharedPreferencesProvider).setStringList(_prefsKey, next);
  }
}
