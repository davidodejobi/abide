import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/features/hymn/domain/get_hymn_for_split_view.dart';
import 'package:openbaptisthymnal/features/hymn/domain/get_hymns_by_language.dart';
import 'package:openbaptisthymnal/features/hymn/domain/hymn_pair_resolver.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';

import '../../providers/hymnal_provider.dart';

class HymnsViewModel extends AutoDisposeAsyncNotifier<List<HymnTranslation>> {
  @override
  Future<List<HymnTranslation>> build() async {
    final languageCode = ref.watch(languageProvider);
    final getHymns = GetHymnsByLanguage(ref.read(hymnalRepositoryProvider));
    return getHymns(languageCode);
  }

  Future<void> changeLanguage(String languageCode) async {
    ref.read(languageProvider.notifier).state = languageCode;
  }
}

final hymnsViewModelProvider =
    AsyncNotifierProvider.autoDispose<HymnsViewModel, List<HymnTranslation>>(
        HymnsViewModel.new);

/// Identifier for [hymnInLanguageProvider] lookups.
class HymnInLanguageKey {
  const HymnInLanguageKey(this.hymnId, this.language, {this.idLanguage});

  final String hymnId;
  final String language;

  /// Language whose pack [hymnId] is an id of. Null means [language] itself
  /// (a hymn picked directly from that pack); set it when the id comes from
  /// another pack and the same hymn must be found by content.
  final String? idLanguage;

  @override
  bool operator ==(Object other) =>
      other is HymnInLanguageKey &&
      other.hymnId == hymnId &&
      other.language == language &&
      other.idLanguage == idLanguage;

  @override
  int get hashCode => Object.hash(hymnId, language, idLanguage);
}

/// Loads a single hymn translation for a specific language. Used by the
/// split-view secondary pane when the user picks a hymn directly, or when it
/// opens on the same hymn in the other language (null if no confirmed pair).
///
/// Hand-written rather than codegen so the split-view feature isn't blocked on
/// running build_runner.
final hymnInLanguageProvider = FutureProvider.family
    .autoDispose<HymnTranslation?, HymnInLanguageKey>((ref, key) async {
  final repo = ref.read(hymnalRepositoryProvider);
  final id = await HymnPairResolver(repo).idIn(
    key.language,
    key.hymnId,
    fromLanguage: key.idLanguage ?? key.language,
  );
  if (id == null) return null;
  final pack = await repo.getLanguagePack(key.language);
  return pack.hymns[id];
});

final hymnDetailProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>, String>((ref, hymnId) async {
  final languages = [ref.watch(languageProvider)];
  final getHymn = GetHymnForSplitView(ref.read(hymnalRepositoryProvider));
  final translations =
      await getHymn(hymnId, languages, fromLanguage: languages.first);
  return {'translations': translations};
});
