import 'package:openbaptisthymnal/core/utils/json_loader.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_core.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymnal_index.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';

abstract class HymnalRepository {
  Future<HymnalCore> getHymnalCore();
  Future<HymnalIndex> getHymnalIndex();
  Future<LanguagePack> getLanguagePack(String languageCode);
}

class HymnalRepositoryImpl implements HymnalRepository {
  final JsonLoader _jsonLoader;

  HymnalRepositoryImpl(this._jsonLoader);

  @override
  Future<HymnalCore> getHymnalCore() async {
    final data = await _jsonLoader.loadJson('assets/hymnal/core.json');
    return HymnalCore.fromJson(data);
  }

  @override
  Future<HymnalIndex> getHymnalIndex() async {
    final data = await _jsonLoader.loadJson('assets/hymnal/index.json');
    return HymnalIndex.fromJson(data);
  }

  @override
  Future<LanguagePack> getLanguagePack(String languageCode) async {
    final data = await _jsonLoader
        .loadJson('assets/hymnal/languages/$languageCode.json');
    return LanguagePack.fromJson(data);
  }
}
