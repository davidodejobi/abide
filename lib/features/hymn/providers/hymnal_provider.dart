import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/core/utils/json_loader.dart';
import 'package:openbaptisthymnal/features/hymn/data/hymnal_repository.dart';

final jsonLoaderProvider = Provider((ref) => JsonLoader());

final hymnalRepositoryProvider = Provider<HymnalRepository>((ref) {
  final loader = ref.watch(jsonLoaderProvider);
  return HymnalRepositoryImpl(loader);
});

/// The song language, persisted. Songs ship in English and Yoruba only, so a
/// first launch is English unless the phone is set to Yoruba.
final languageProvider = StateProvider<String>((ref) {
  final storage = ref.watch(storageServiceProvider);
  // ignore: deprecated_member_use
  ref.listenSelf((_, next) => storage.saveSongLanguage(next));
  return storage.getSongLanguage() ??
      (PlatformDispatcher.instance.locale.languageCode == 'yo' ? 'yo' : 'en');
});
