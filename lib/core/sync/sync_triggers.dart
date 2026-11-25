import '../storage/database/app_database.dart';

/// Synced tables: entity name (also the remote table suffix) -> key column.
/// Reading progress, notes and highlights only. Order matters on pull: notes
/// before the annotations that may point at them.
const syncedEntities = <String, String>{
  'notes': 'id',
  'bible_annotations': 'id',
  'reading_days': 'date_key',
  'plan_subscriptions': 'plan_id',
  'plan_day_progress': 'id',
};

/// Writes are queued only while sync is on or paused (`sync_enabled` = 1 or
/// 'paused': paused keeps queueing so nothing is lost) and not while a
/// pull is being applied. With sync off the outbox therefore never grows; the
/// whole database is queued in one go when sync is switched on.
const _quiet = "COALESCE((SELECT value FROM sync_state WHERE key = 'applying'),"
    " '0') = '0' AND COALESCE((SELECT value FROM sync_state WHERE key = "
    "'sync_enabled'), '0') IN ('1', 'paused')";

String _enqueue(String entity, String keyExpr, String op) =>
    'INSERT INTO sync_outbox(entity, row_id, op, seq, queued_at) '
    "VALUES ('$entity', $keyExpr, '$op', "
    '(SELECT COALESCE(MAX(seq), 0) + 1 FROM sync_outbox), '
    "CAST(strftime('%s', 'now') AS INTEGER)) "
    // An upsert clause, not OR REPLACE: the outer statement's own conflict mode
    // (drift's insertOnConflictUpdate) overrides OR REPLACE inside a trigger.
    'ON CONFLICT(entity, row_id) DO UPDATE SET op = excluded.op, '
    'seq = excluded.seq, queued_at = excluded.queued_at';

/// Triggers that record every local write in `sync_outbox`. Drift's schema model
/// cannot see them (same as the FTS triggers), so they are created by hand in
/// onCreate and the v5 upgrade. Writes made while `applying` is set (pulled
/// rows) are skipped, otherwise a pull would echo straight back as a push.
Future<void> createSyncTriggers(AppDatabase db) async {
  // MAX(seq) runs on every queued write; keep it an index lookup.
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS sync_outbox_seq ON sync_outbox(seq)',
  );
  for (final e in syncedEntities.entries) {
    final t = e.key, k = e.value;
    await db.customStatement(
      'CREATE TRIGGER IF NOT EXISTS sync_${t}_ai AFTER INSERT ON $t '
      'WHEN $_quiet BEGIN ${_enqueue(t, 'new.$k', 'upsert')}; END',
    );
    await db.customStatement(
      'CREATE TRIGGER IF NOT EXISTS sync_${t}_au AFTER UPDATE ON $t '
      'WHEN $_quiet BEGIN ${_enqueue(t, 'new.$k', 'upsert')}; END',
    );
    await db.customStatement(
      'CREATE TRIGGER IF NOT EXISTS sync_${t}_ad AFTER DELETE ON $t '
      'WHEN $_quiet BEGIN ${_enqueue(t, 'old.$k', 'delete')}; END',
    );
  }
}

/// Queues every existing row (upgrade path), so pre-sync data reaches the server.
Future<void> backfillSyncOutbox(AppDatabase db) async {
  for (final e in syncedEntities.entries) {
    await db.customStatement(
      'INSERT OR REPLACE INTO sync_outbox(entity, row_id, op, seq, queued_at) '
      "SELECT '${e.key}', ${e.value}, 'upsert', "
      '(SELECT COALESCE(MAX(seq), 0) FROM sync_outbox) + ROW_NUMBER() OVER (), '
      "CAST(strftime('%s', 'now') AS INTEGER) FROM ${e.key}",
    );
  }
}
