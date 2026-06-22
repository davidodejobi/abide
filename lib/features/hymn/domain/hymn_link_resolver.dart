import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/preferences/linking_preferences.dart';
import 'package:openbaptisthymnal/features/hymn/providers/hymnal_provider.dart';

/// Where a tablet `[[hymn:...]]` link should open. The hymn id is stable
/// across language packs (the same `hymn_0001` exists in `en` and `yo` today),
/// so the resolver's only job today is picking the language to open in.
///
/// The model is deliberately broader than that: [editionId] holds whatever
/// will identify a hymnal edition in the future (e.g. `baptist-en`,
/// `methodist-en`, `cccc-ig`). Today it's a language code.
class HymnNavigationTarget {
  const HymnNavigationTarget({
    required this.hymnId,
    required this.editionId,
    this.toastMessage,
  });

  final String hymnId;
  final String editionId;
  final String? toastMessage;
}

/// Resolves a `[[hymn:...]]` link to a concrete hymn + edition. Today an
/// "edition" is just a language pack (`en`, `yo`); the resolver is structured
/// to absorb the future hymnal-id axis without changing the link grammar or
/// callers.
class HymnLinkResolver {
  HymnLinkResolver(this._ref);

  final Ref _ref;

  /// Resolves [hymnId] (e.g. `hymn_0001`).
  /// If [editionPin] is a known edition id it wins outright; if it looks
  /// plausible but isn't installed, we fall through to the priority list
  /// below and surface a soft hint.
  ///
  /// Priority for unpinned (or missing-pin) links:
  ///   1. user's default-hymn-edition setting
  ///   2. the user's current reading language
  ///   3. the first known edition
  HymnNavigationTarget? resolve(
    String hymnId, {
    String? editionPin,
  }) {
    if (hymnId.isEmpty) return null;

    final installed = _installedEditions();
    if (installed.isEmpty) return null;

    String chosen;
    String? toast;
    if (editionPin != null) {
      final match = _matchEdition(installed, editionPin);
      if (match != null) {
        chosen = match;
      } else {
        toast = 'That hymnal ($editionPin) isn\'t available yet. '
            'Showing your current language instead.';
        chosen = _pickFallback(installed);
      }
    } else {
      chosen = _pickFallback(installed);
    }

    return HymnNavigationTarget(
      hymnId: hymnId,
      editionId: chosen,
      toastMessage: toast,
    );
  }

  /// The set of hymn editions the app currently ships. Today this is just
  /// the two language packs; when hymnal ids enter the model, return them
  /// here instead. English leads so it acts as the final fallback when no
  /// preference is set.
  List<String> _installedEditions() => const ['en', 'yo'];

  /// The language we open unpinned hymn links in when the user has no
  /// preference set and no current reading position to follow. We
  /// intentionally use English here: a tablet shared between users (or read
  /// months later) opens in the most widely understood pack by default.
  static const _hymnLinkDefault = 'en';

  String? _matchEdition(List<String> installed, String id) {
    final needle = id.toLowerCase();
    for (final e in installed) {
      if (e.toLowerCase() == needle) return e;
    }
    return null;
  }

  String _pickFallback(List<String> installed) {
    final prefs = _ref.read(linkingPreferencesProvider);
    final defaultId = prefs.defaultHymnEditionId;
    final defaulted = _matchEdition(installed, defaultId ?? '');
    if (defaulted != null) return defaulted;

    // When the user has no explicit preference, English wins over the current
    // reading language. Tablet links should be portable: a hymn quoted today
    // should open in the most widely understood pack tomorrow.
    final englishMatch = _matchEdition(installed, _hymnLinkDefault);
    if (englishMatch != null) return englishMatch;

    final reading = _ref.read(languageProvider);
    final readingMatch = _matchEdition(installed, reading);
    if (readingMatch != null) return readingMatch;

    return installed.first;
  }
}

final hymnLinkResolverProvider = Provider<HymnLinkResolver>((ref) {
  return HymnLinkResolver(ref);
});
