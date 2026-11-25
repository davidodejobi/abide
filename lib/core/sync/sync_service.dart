import 'package:drift/drift.dart';

import '../storage/database/app_database.dart';
import 'sync_remote.dart';
import 'sync_triggers.dart';

/// Columns that stay device-local (the folders table is not synced, so a
/// folder id from another device would break the foreign key).
const _localOnly = {
  'notes': {'folder_id'},
};

/// Column holding each entity's last-write-wins clock.
String _clock(String entity) => switch (entity) {
      'reading_days' || 'plan_day_progress' => 'completed_at',
      _ => 'updated_at',
    };

DateTime _fromSeconds(Object? v) =>
    DateTime.fromMillisecondsSinceEpoch((v as int) * 1000);

/// Offline-first sync. Drift stays the source of truth; a local write is queued
/// by triggers in `sync_outbox`, [sync] pushes the queue then pulls what changed
/// on the server. Per row, the later `updatedAt` wins. Every step is idempotent,
/// so a crash or retry at any point is safe.
class SyncService {
  SyncService({
    required AppDatabase db,
    required SyncRemote remote,
    bool Function()? enabled,
  })  : _db = db,
        _remote = remote,
        _enabled = enabled ?? (() => true);

  final AppDatabase _db;
  final SyncRemote _remote;

  /// The single gate (e.g. consent / under-13 local-only). When false nothing
  /// leaves or enters the device.
  final bool Function() _enabled;

  bool get enabled => _enabled();

  Future<void>? _inFlight;
  bool _again = false;

  /// Push then pull. Returns true on success, false when disabled, offline or
  /// failed (the outbox keeps everything for the next run). Overlapping calls
  /// coalesce into one follow-up run.
  Future<bool> sync() async {
    if (!enabled) return false;
    if (_inFlight != null) {
      _again = true;
      await _inFlight;
      return true;
    }
    var ok = true;
    do {
      _again = false;
      final run = _run();
      _inFlight = run.then((v) => ok = v);
      await _inFlight;
      _inFlight = null;
    } while (_again && ok);
    return ok;
  }

  Future<bool> _run() async {
    try {
      // Pull first: if a local edit is about to lose to a newer server copy we
      // must see that before pushing, or the server would drop the push and the
      // local text would vanish without a conflict copy.
      await _pull();
      await _push();
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- push -----------------------------------------------------------------

  Future<void> _push() async {
    while (true) {
      final queued = await _db
          .customSelect('SELECT * FROM sync_outbox ORDER BY seq LIMIT 200')
          .get();
      if (queued.isEmpty) return;

      final records = <SyncRecord>[];
      for (final q in queued) {
        final entity = q.read<String>('entity');
        final rowId = q.read<String>('row_id');
        final queuedAt = _fromSeconds(q.read<int>('queued_at'));
        final row =
            q.read<String>('op') == 'upsert' ? await _row(entity, rowId) : null;
        if (row == null) {
          // Deleted (or deleted since it was queued): send a tombstone.
          records.add(SyncRecord(
            entity: entity,
            rowId: rowId,
            updatedAt: queuedAt,
            deleted: true,
          ));
        } else {
          records.add(SyncRecord(
            entity: entity,
            rowId: rowId,
            updatedAt: _fromSeconds(row[_clock(entity)]),
            payload: {
              for (final e in row.entries)
                if (!(_localOnly[entity]?.contains(e.key) ?? false))
                  e.key: e.value,
            },
          ));
        }
      }
      await _remote.push(records);

      // Clear only what was sent; a row rewritten meanwhile has a newer seq and
      // stays queued.
      await _db.transaction(() async {
        for (final q in queued) {
          await _db.customStatement(
            'DELETE FROM sync_outbox WHERE entity = ? AND row_id = ? AND seq = ?',
            [
              q.read<String>('entity'),
              q.read<String>('row_id'),
              q.read<int>('seq')
            ],
          );
        }
      });
    }
  }

  // --- pull -----------------------------------------------------------------

  Future<void> _pull() async {
    for (final entity in syncedEntities.keys) {
      while (true) {
        final cursor = await _state('cursor:$entity');
        final page = await _remote.pull(entity, cursor);
        if (page.records.isEmpty) break;
        final copies = <Map<String, Object?>>[];
        await _db.transaction(() async {
          await _setState('applying', '1');
          try {
            for (final r in page.records) {
              await _apply(r, copies);
            }
          } finally {
            await _setState('applying', '0');
          }
          if (page.cursor != null) {
            await _setState('cursor:$entity', page.cursor!);
          }
        });
        // Outside the quiet window on purpose: copies are new local rows that
        // must be pushed.
        for (final c in copies) {
          await _insert('notes', c);
        }
        if (page.cursor == cursor) break;
      }
    }
  }

  Future<void> _apply(SyncRecord r, List<Map<String, Object?>> copies) async {
    final entity = r.entity;
    final keyCol = syncedEntities[entity];
    if (keyCol == null) return;
    final local = await _row(entity, r.rowId);
    final pending = (await _db.customSelect(
      'SELECT queued_at FROM sync_outbox WHERE entity = ? AND row_id = ?',
      variables: [Variable<String>(entity), Variable<String>(r.rowId)],
    ).get())
        .firstOrNull;

    final localTime = local != null
        ? _fromSeconds(local[_clock(entity)])
        : pending != null
            ? _fromSeconds(pending.read<int>('queued_at'))
            : null;

    if (pending != null) {
      // Unsent local change: keep it unless the server copy is strictly newer.
      if (localTime != null && !r.updatedAt.isAfter(localTime)) return;
      await _db.customStatement(
        'DELETE FROM sync_outbox WHERE entity = ? AND row_id = ?',
        [entity, r.rowId],
      );
      // The local edit is about to lose. For notes, keep its text as a copy so
      // nothing typed is ever dropped.
      if (entity == 'notes' && local != null && !r.deleted) {
        final differs = local['title'] != r.payload['title'] ||
            local['content_markdown'] != r.payload['content_markdown'];
        if (differs && local['is_deleted'] == 0) {
          copies.add({
            ...local,
            'id': '${r.rowId}~conflict~${local['updated_at']}',
            'title': 'Conflict copy: ${local['title']}',
            'folder_id': null,
          });
        }
      }
    } else if (local != null) {
      final newer = r.deleted
          ? !r.updatedAt.isBefore(localTime!)
          : r.updatedAt.isAfter(localTime!);
      if (!newer) return;
    }

    if (r.deleted) {
      await _db.customStatement(
        'DELETE FROM $entity WHERE $keyCol = ?',
        [r.rowId],
      );
      return;
    }
    final payload = {...r.payload};
    if (entity == 'bible_annotations' && payload['note_id'] != null) {
      if (await _row('notes', payload['note_id'] as String) == null) {
        payload['note_id'] = null;
      }
    }
    await _insert(entity, payload);
  }

  /// Insert-or-update by primary key (an upsert, not REPLACE, so triggers such
  /// as the notes search index keep working). Unknown columns from a newer app
  /// version and device-local columns are ignored.
  Future<void> _insert(String entity, Map<String, Object?> values) async {
    final keyCol = syncedEntities[entity]!;
    final known = (await _db.customSelect('PRAGMA table_info($entity)').get())
        .map((r) => r.read<String>('name'))
        .toSet();
    final cols = [
      for (final k in values.keys)
        if (known.contains(k) && !(_localOnly[entity]?.contains(k) ?? false)) k,
    ];
    final updates = cols
        .where((c) => c != keyCol && c != 'created_at')
        .map((c) => '$c = excluded.$c');
    await _db.customStatement(
      'INSERT INTO $entity (${cols.join(', ')}) '
      'VALUES (${List.filled(cols.length, '?').join(', ')}) '
      'ON CONFLICT($keyCol) DO UPDATE SET ${updates.join(', ')}',
      [for (final c in cols) values[c]],
    );
  }

  // --- helpers --------------------------------------------------------------

  Future<Map<String, Object?>?> _row(String entity, String rowId) async {
    final rows = await _db.customSelect(
      'SELECT * FROM $entity WHERE ${syncedEntities[entity]} = ?',
      variables: [Variable<String>(rowId)],
    ).get();
    return rows.isEmpty ? null : rows.first.data;
  }

  Future<String?> _state(String key) async {
    final rows = await _db.customSelect(
      'SELECT value FROM sync_state WHERE key = ?',
      variables: [Variable<String>(key)],
    ).get();
    return rows.isEmpty ? null : rows.first.read<String>('value');
  }

  Future<void> _setState(String key, String value) => _db.customStatement(
        'INSERT INTO sync_state(key, value) VALUES (?, ?) '
        'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
        [key, value],
      );
}
