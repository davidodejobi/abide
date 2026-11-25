import 'sync_remote.dart';

/// In-process stand-in for the server, used by tests. Mimics the real contract:
/// last-write-wins by `updatedAt`, tombstones kept, a monotonic cursor.
class InMemorySyncRemote implements SyncRemote {
  final _rows = <String, Map<String, (int, SyncRecord)>>{};
  var _seq = 0;

  /// Flip to false to simulate being offline: every call throws.
  bool online = true;

  @override
  Future<void> push(List<SyncRecord> records) async {
    if (!online) throw StateError('offline');
    for (final r in records) {
      final table = _rows.putIfAbsent(r.entity, () => {});
      final existing = table[r.rowId]?.$2;
      // Ties go to the incoming write; a stale write is dropped.
      if (existing == null || !r.updatedAt.isBefore(existing.updatedAt)) {
        table[r.rowId] = (++_seq, r);
      }
    }
  }

  @override
  Future<SyncPage> pull(String entity, String? cursor) async {
    if (!online) throw StateError('offline');
    final after = int.tryParse(cursor ?? '') ?? 0;
    final changed = (_rows[entity]?.values ?? const <(int, SyncRecord)>[])
        .where((e) => e.$1 > after)
        .toList()
      ..sort((a, b) => a.$1.compareTo(b.$1));
    if (changed.isEmpty) return SyncPage(const [], cursor);
    return SyncPage([for (final e in changed) e.$2], '${changed.last.$1}');
  }

  /// Test helper: current server copy of a row.
  SyncRecord? get(String entity, String rowId) => _rows[entity]?[rowId]?.$2;
}
