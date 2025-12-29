import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/json_loader.dart';
import '../data/repositories/hymnal_repository.dart';

final jsonLoaderProvider = Provider((ref) => JsonLoader());

final hymnalRepositoryProvider = Provider<HymnalRepository>((ref) {
  final loader = ref.watch(jsonLoaderProvider);
  return HymnalRepositoryImpl(loader);
});

final languageProvider = StateProvider<String>((ref) => 'en');
