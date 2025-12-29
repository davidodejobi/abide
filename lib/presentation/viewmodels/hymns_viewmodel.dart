import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/usecases/get_hymn_for_split_view.dart';
import '../../domain/usecases/get_hymns_by_language.dart';
import '../../providers/hymnal_provider.dart';

part 'hymns_viewmodel.g.dart';

@riverpod
class HymnsViewModel extends _$HymnsViewModel {
  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    final languageCode = ref.watch(languageProvider);
    final getHymns = GetHymnsByLanguage(ref.read(hymnalRepositoryProvider));
    return getHymns(languageCode);
  }

  Future<void> changeLanguage(String languageCode) async {
    ref.read(languageProvider.notifier).state = languageCode;
  }
}

@riverpod
Future<Map<String, dynamic>> hymnDetail(
    HymnDetailRef ref, String hymnId) async {
  final languages = [ref.watch(languageProvider)];
  final getHymn = GetHymnForSplitView(ref.read(hymnalRepositoryProvider));
  final translations = await getHymn(hymnId, languages);
  return {'translations': translations};
}

@riverpod
Future<Map<String, dynamic>> bilingualHymnDetail(
    BilingualHymnDetailRef ref, String hymnId, List<String> languages) async {
  final getHymn = GetHymnForSplitView(ref.read(hymnalRepositoryProvider));
  final translations = await getHymn(hymnId, languages);
  return {'translations': translations};
}
