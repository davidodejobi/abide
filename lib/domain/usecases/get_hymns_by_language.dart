import '../../data/repositories/hymnal_repository.dart';

class GetHymnsByLanguage {
  final HymnalRepository repository;

  GetHymnsByLanguage(this.repository);

  Future<List<Map<String, dynamic>>> call(String languageCode) async {
    final hymns = await repository.getHymns();
    final languagePack = await repository.getLanguagePack(languageCode);
    final order = await repository.getOrder(languageCode);

    final List<Map<String, dynamic>> result = [];

    for (var id in order) {
      final hymn = hymns.firstWhere((h) => h.id == id);
      final translation = languagePack.hymns[id];
      if (translation != null) {
        result.add({
          'hymn': hymn,
          'translation': translation,
        });
      }
    }

    return result;
  }
}
