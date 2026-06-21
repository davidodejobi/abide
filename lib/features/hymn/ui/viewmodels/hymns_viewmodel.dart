import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/features/hymn/domain/get_hymn_for_split_view.dart';
import 'package:openbaptisthymnal/features/hymn/domain/get_hymns_by_language.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/hymnal_provider.dart';

part 'hymns_viewmodel.g.dart';

@riverpod
class HymnsViewModel extends _$HymnsViewModel {
  @override
  FutureOr<List<HymnTranslation>> build() async {
    final languageCode = ref.watch(languageProvider);
    final getHymns = GetHymnsByLanguage(ref.read(hymnalRepositoryProvider));
    return getHymns(languageCode);
  }

  Future<void> changeLanguage(String languageCode) async {
    ref.read(languageProvider.notifier).state = languageCode;
  }
}

@riverpod
Future<Map<String, dynamic>> hymnDetail(Ref ref, String hymnId) async {
  final languages = [ref.watch(languageProvider)];
  final getHymn = GetHymnForSplitView(ref.read(hymnalRepositoryProvider));
  final translations = await getHymn(hymnId, languages);
  return {'translations': translations};
}

@riverpod
Future<Map<String, dynamic>> bilingualHymnDetail(
    Ref ref, String hymnId, List<String> languages) async {
  final getHymn = GetHymnForSplitView(ref.read(hymnalRepositoryProvider));
  final translations = await getHymn(hymnId, languages);
  return {'translations': translations};
}

/// Identifier for [hymnInLanguageProvider] lookups.
class HymnInLanguageKey {
  const HymnInLanguageKey(this.hymnId, this.language);

  final String hymnId;
  final String language;

  @override
  bool operator ==(Object other) =>
      other is HymnInLanguageKey &&
      other.hymnId == hymnId &&
      other.language == language;

  @override
  int get hashCode => Object.hash(hymnId, language);
}

/// Loads a single hymn translation for a specific language. Used by the
/// split-view secondary pane when the user picks a hymn directly.
///
/// Hand-written rather than codegen so the split-view feature isn't blocked on
/// running build_runner.
final hymnInLanguageProvider = FutureProvider.family
    .autoDispose<HymnTranslation?, HymnInLanguageKey>((ref, key) async {
  final pack =
      await ref.read(hymnalRepositoryProvider).getLanguagePack(key.language);
  return pack.hymns[key.hymnId];
});
