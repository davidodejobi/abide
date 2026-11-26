import 'package:openbaptisthymnal/features/bible/data/sources/local/installed_bible_store.dart';

/// Web: no app support directory, so downloads are not offered.
Future<InstalledBibleStore> createInstalledBibleStore() async =>
    const NoopInstalledBibleStore();
