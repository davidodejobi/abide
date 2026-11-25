import 'package:openbaptisthymnal/features/hymn/data/hymnal_repository.dart';
import 'package:openbaptisthymnal/features/hymn/domain/hymn_pair_resolver.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';

class GetHymnForSplitView {
  final HymnalRepository repository;
  final HymnPairResolver _pairs;

  GetHymnForSplitView(this.repository) : _pairs = HymnPairResolver(repository);

  /// [hymnId] is an id in [fromLanguage]'s pack. Each language in [languages]
  /// gets that same hymn found by content, and is left out when its pack has
  /// no confirmed version (never a different song with the same id).
  Future<Map<String, HymnTranslation>> call(
    String hymnId,
    List<String> languages, {
    required String fromLanguage,
  }) async {
    final Map<String, HymnTranslation> translations = {};

    for (var lang in languages) {
      final id = await _pairs.idIn(lang, hymnId, fromLanguage: fromLanguage);
      if (id == null) continue;
      final pack = await repository.getLanguagePack(lang);
      final translation = pack.hymns[id];
      if (translation != null) {
        translations[lang] = translation;
      }
    }

    return translations;
  }
}
