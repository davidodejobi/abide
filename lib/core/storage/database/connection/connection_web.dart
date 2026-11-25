import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

/// Web: sqlite3.wasm + drift_worker.js live in web/. Storage is OPFS when the
/// COOP/COEP headers are present (see web/_headers), IndexedDB otherwise.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'abide_notes',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    if (result.missingFeatures.isNotEmpty) {
      debugPrint('Drift web: ${result.chosenImplementation}, '
          'missing ${result.missingFeatures}');
    }
    return result.resolvedExecutor;
  });
}
