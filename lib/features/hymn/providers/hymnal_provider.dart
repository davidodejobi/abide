import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/utils/json_loader.dart';
import 'package:openbaptisthymnal/features/hymn/data/hymnal_repository.dart';

final jsonLoaderProvider = Provider((ref) => JsonLoader());

final hymnalRepositoryProvider = Provider<HymnalRepository>((ref) {
  final loader = ref.watch(jsonLoaderProvider);
  return HymnalRepositoryImpl(loader);
});

final languageProvider = StateProvider<String>((ref) => 'yo');
