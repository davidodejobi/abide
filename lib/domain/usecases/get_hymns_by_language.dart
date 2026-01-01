import 'package:open_baptist_hymnal/data/models/language_pack.dart';

import '../../data/repositories/hymnal_repository.dart';

class GetHymnsByLanguage {
  final HymnalRepository repository;

  GetHymnsByLanguage(this.repository);

  Future<List<HymnTranslation>> call(String languageCode) async {
    final core = await repository.getHymnalCore();
    final index = await repository.getHymnalIndex();
    final languagePack = await repository.getLanguagePack(languageCode);
    // Get the order for this language, fallback to empty list if not present
    final order = index.orders[languageCode] ?? [];

    final List<HymnTranslation> result = [];

    for (var id in order) {
      final hymn = core.hymns[id];
      final translation = languagePack.hymns[id];
      if (hymn != null && translation != null) {
        result.add(HymnTranslation(
          lyrics: translation.lyrics,
          title: translation.title,
          number: translation.number,
          id: id,
        ));
      }
    }

    return result;
  }
}
