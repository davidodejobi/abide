/// One synced row as it travels to and from the server.
class SyncRecord {
  const SyncRecord({
    required this.entity,
    required this.rowId,
    required this.updatedAt,
    this.deleted = false,
    this.payload = const {},
  });

  final String entity;
  final String rowId;

  /// The row's last-write-wins clock (for a hard delete: when it was deleted).
  final DateTime updatedAt;

  /// Tombstone. The server keeps these so deletes reach other devices.
  final bool deleted;

  /// Raw column map (SQL column names). Empty for tombstones.
  final Map<String, Object?> payload;
}

class SyncPage {
  const SyncPage(this.records, this.cursor);

  final List<SyncRecord> records;

  /// Pass back to [SyncRemote.pull] to continue after these records.
  final String? cursor;
}

/// The server side of sync. Everything above this seam is backend-agnostic, so
/// tests run against `InMemorySyncRemote` and production uses Supabase.
abstract class SyncRemote {
  /// Stable id of the account the rows belong to. Sync resets its cursors and
  /// re-queues local data when this changes (sign-out, a different account).
  Future<String> identity();

  /// True when [error] means this record will never be accepted (constraint,
  /// permission or mapping error), as opposed to a transient network failure.
  bool isPermanent(Object error);

  /// Upserts [records]. Must keep the row with the greater `updatedAt` (last
  /// write wins) and be safe to repeat.
  Future<void> push(List<SyncRecord> records);

  /// Records of [entity] changed after [cursor] (null = from the start).
  Future<SyncPage> pull(String entity, String? cursor);
}
