import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:openbaptisthymnal/core/storage/storage_provider.dart';
import 'package:openbaptisthymnal/features/bible/data/bible_downloader.dart';
import 'package:openbaptisthymnal/features/bible/data/sources/local/installed_bible_store.dart';
import 'package:openbaptisthymnal/features/bible/data/sources/remote/bible_catalog_source.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_catalog.dart';
import 'package:openbaptisthymnal/features/bible/providers/bible_providers.dart';

final bibleHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final bibleCatalogSourceProvider = Provider<BibleCatalogSource>((ref) {
  return BibleCatalogSource(
    ref.watch(bibleHttpClientProvider),
    ref.watch(sharedPreferencesProvider),
  );
});

final bibleDownloaderProvider = Provider<BibleDownloader>((ref) {
  return BibleDownloader(
    ref.watch(bibleHttpClientProvider),
    ref.watch(installedBibleStoreProvider),
  );
});

/// The catalog the "Get more Bibles" screen shows.
class BibleCatalogState {
  const BibleCatalogState({
    this.catalog,
    this.loading = false,
    this.failed = false,
    this.fromCache = false,
  });

  final BibleCatalog? catalog;
  final bool loading;

  /// The last refresh failed. With a [catalog] that is the saved copy (offline
  /// banner); without one it is the full error state.
  final bool failed;
  final bool fromCache;
}

final bibleCatalogProvider =
    NotifierProvider<BibleCatalogNotifier, BibleCatalogState>(
  BibleCatalogNotifier.new,
);

class BibleCatalogNotifier extends Notifier<BibleCatalogState> {
  @override
  BibleCatalogState build() {
    final cached = ref.read(bibleCatalogSourceProvider).cached();
    Future.microtask(refresh);
    return BibleCatalogState(
        catalog: cached, loading: true, fromCache: cached != null);
  }

  Future<void> refresh() async {
    state = BibleCatalogState(
        catalog: state.catalog, loading: true, fromCache: state.fromCache);
    try {
      final fresh = await ref.read(bibleCatalogSourceProvider).fetch();
      state = BibleCatalogState(catalog: fresh);
    } catch (_) {
      state = BibleCatalogState(
          catalog: state.catalog, failed: true, fromCache: state.catalog != null);
    }
  }
}

/// Per-edition download status. Absent = idle.
class BibleDownloadStatus {
  const BibleDownloadStatus({this.progress = 0, this.error});

  /// 0..1 while downloading.
  final double progress;

  /// Set when the last attempt failed; the row offers Retry.
  final BibleDownloadError? error;

  bool get active => error == null;
}

enum BibleDownloadError { network, corrupt }

final bibleDownloadsProvider =
    NotifierProvider<BibleDownloadsNotifier, Map<String, BibleDownloadStatus>>(
  BibleDownloadsNotifier.new,
);

class BibleDownloadsNotifier extends Notifier<Map<String, BibleDownloadStatus>> {
  @override
  Map<String, BibleDownloadStatus> build() => const {};

  void _set(String id, BibleDownloadStatus? s) {
    final next = {...state};
    s == null ? next.remove(id) : next[id] = s;
    state = next;
  }

  Future<void> download(BibleCatalogEntry entry) async {
    if (state[entry.id]?.active ?? false) return;
    _set(entry.id, const BibleDownloadStatus());
    try {
      final edition = await ref.read(bibleDownloaderProvider).download(
            entry,
            onProgress: (p) => _set(entry.id, BibleDownloadStatus(progress: p)),
          );
      ref.read(installedBiblesProvider.notifier).add(edition);
      _set(entry.id, null);
    } on BibleHashMismatch {
      _set(entry.id,
          const BibleDownloadStatus(error: BibleDownloadError.corrupt));
    } catch (_) {
      _set(entry.id,
          const BibleDownloadStatus(error: BibleDownloadError.network));
    }
  }

  Future<void> remove(String id) async {
    await ref.read(bibleDownloaderProvider).remove(id);
    ref.read(installedBiblesProvider.notifier).remove(id);
  }
}
