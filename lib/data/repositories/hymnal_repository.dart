import '../local/json_loader.dart';
import '../models/hymn.dart';
import '../models/language_pack.dart';

abstract class HymnalRepository {
  Future<List<Hymn>> getHymns();
  Future<LanguagePack> getLanguagePack(String languageCode);
  Future<List<String>> getOrder(String languageCode);
}

class HymnalRepositoryImpl implements HymnalRepository {
  final JsonLoader _jsonLoader;

  HymnalRepositoryImpl(this._jsonLoader);

  @override
  Future<List<Hymn>> getHymns() async {
    final data = await _jsonLoader.loadJsonList('assets/hymnal/core.json');
    return data.map((e) => Hymn.fromJson(e)).toList();
  }

  @override
  Future<LanguagePack> getLanguagePack(String languageCode) async {
    final data = await _jsonLoader
        .loadJson('assets/hymnal/languages/$languageCode.json');
    return LanguagePack.fromJson(data);
  }

  @override
  Future<List<String>> getOrder(String languageCode) async {
    final data = await _jsonLoader
        .loadJsonList('assets/hymnal/orders/$languageCode.json');
    return data.map((e) => e.toString()).toList();
  }
}
