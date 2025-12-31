import '../../data/repositories/hymnal_repository.dart';

class GetHymnsByLanguage {
  final HymnalRepository repository;

  GetHymnsByLanguage(this.repository);

  Future<List<Map<String, dynamic>>> call(String languageCode) async {
    final core = await repository.getHymnalCore();
    final index = await repository.getHymnalIndex();
    final languagePack = await repository.getLanguagePack(languageCode);

    // Get the order for this language, fallback to empty list if not present
    final order = index.orders[languageCode] ?? [];

    final List<Map<String, dynamic>> result = [];

    for (var id in order) {
      final hymn = core.hymns[id];
      final translation = languagePack.hymns[id];
      if (hymn != null && translation != null) {
        result.add({
          'id': id,
          'hymn': hymn,
          'translation': translation,
        });
      }
    }

    return result;
  }
}
