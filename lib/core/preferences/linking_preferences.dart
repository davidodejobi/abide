import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/core/storage/storage_service.dart';

/// What edition `[[bible:...]]` and `[[hymn:...]]` links open when the link
/// itself does not pin one. Both fields are nullable: `null` means "follow
/// the user's current reading position", which is the default the resolvers
/// already fall back to.
class LinkingPreferences {
  const LinkingPreferences({
    this.defaultBibleEditionId,
    this.defaultHymnEditionId,
  });

  /// Stable id of the Bible edition (e.g. `en-kjv`, `yo-bmy`) or null.
  final String? defaultBibleEditionId;

  /// Stable id of the hymn edition (today a language code like `en` or `yo`;
  /// later a hymnal-language pair) or null.
  final String? defaultHymnEditionId;

  LinkingPreferences copyWith({
    String? defaultBibleEditionId,
    String? defaultHymnEditionId,
    bool clearBible = false,
    bool clearHymn = false,
  }) {
    return LinkingPreferences(
      defaultBibleEditionId: clearBible
          ? null
          : (defaultBibleEditionId ?? this.defaultBibleEditionId),
      defaultHymnEditionId: clearHymn
          ? null
          : (defaultHymnEditionId ?? this.defaultHymnEditionId),
    );
  }
}

final linkingPreferencesProvider =
    NotifierProvider<LinkingPreferencesNotifier, LinkingPreferences>(
  LinkingPreferencesNotifier.new,
);

class LinkingPreferencesNotifier extends Notifier<LinkingPreferences> {
  @override
  LinkingPreferences build() {
    final storage = ref.read(storageServiceProvider);
    return LinkingPreferences(
      defaultBibleEditionId: storage.getDefaultBibleLinkEdition(),
      defaultHymnEditionId: storage.getDefaultHymnLinkEdition(),
    );
  }

  StorageService get _storage => ref.read(storageServiceProvider);

  /// Pin a default Bible edition for unpinned `[[bible:...]]` links.
  /// Pass `null` to clear and fall back to the current reading position.
  Future<void> setDefaultBibleEdition(String? editionId) async {
    await _storage.saveDefaultBibleLinkEdition(editionId);
    state = state.copyWith(
      defaultBibleEditionId: editionId,
      clearBible: editionId == null,
    );
  }

  /// Pin a default hymn edition for unpinned `[[hymn:...]]` links.
  /// Pass `null` to clear and fall back to the current reading language.
  Future<void> setDefaultHymnEdition(String? editionId) async {
    await _storage.saveDefaultHymnLinkEdition(editionId);
    state = state.copyWith(
      defaultHymnEditionId: editionId,
      clearHymn: editionId == null,
    );
  }
}
