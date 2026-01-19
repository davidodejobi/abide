import 'package:openbaptisthymnal/features/hymn/data/hymnal_repository.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';

class GetHymnForSplitView {
  final HymnalRepository repository;

  GetHymnForSplitView(this.repository);

  Future<Map<String, HymnTranslation>> call(
      String hymnId, List<String> languages) async {
    final Map<String, HymnTranslation> translations = {};

    for (var lang in languages) {
      final pack = await repository.getLanguagePack(lang);
      final translation = pack.hymns[hymnId];
      if (translation != null) {
        translations[lang] = translation;
      }
    }

    return translations;
  }
}
