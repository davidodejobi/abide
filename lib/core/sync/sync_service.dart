import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:sqlite3/common.dart' show SqliteException;
import 'package:uuid/uuid.dart';

import '../storage/database/app_database.dart';
import 'sync_remote.dart';
import 'sync_triggers.dart';

final _log = Logger('sync');

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
  bool _locked = false;

  /// For leaving this account: syncs, takes the sync lock, re-checks that the
  /// push queue is empty (a write may have landed meanwhile) and only then runs
  /// [body] with sync held off. Returns false, without running [body], when the
  /// sync failed or anything is still queued.
  Future<bool> flushThenLock(Future<void> Function() body) async {
    if (!await sync()) return false;
    return runExclusive(() async {
      if (!await _outboxEmpty()) return false;
      await body();
      return true;
    });
  }

  Future<bool> _outboxEmpty() async {
    final r = await _db
        .customSelect('SELECT COUNT(*) AS c FROM sync_outbox')
        .getSingle();
    return r.read<int>('c') == 0;
  }

  /// Runs [body] with sync held off (a sync that starts meanwhile returns
  /// false), after any running sync has finished.
  Future<T> runExclusive<T>(Future<T> Function() body) async {
    _locked = true;
    try {
      while (_inFlight != null) {
        await _inFlight;
      }
      return await body();
    } finally {
      _locked = false;
    }
  }

  /// Removes what lives on the server from the phone: synced notes, plain
  /// single-verse highlights, reading days, plan progress and subscriptions,
  /// and all sync bookkeeping (queue, cursors, owner). Local-only data (folders,
  /// tags, templates, verse notes) and app preferences stay. Sync is off afterwards
  /// until the next [sync] turns it back on for the next account.
  Future<void> clearLocalData() async {
    // Notes that sync have uuid ids; anything else never left the phone.
    const synced = "id GLOB '????????-????-????-????-????????????'";
    const ofSynced = "SELECT id FROM notes WHERE $synced";
    await _db.transaction(() async {
      for (final q in const [
        // Rows that hang off the notes being removed (foreign keys are on).
        // Folders, tags and templates themselves stay.
        'DELETE FROM note_tags WHERE note_id IN ($ofSynced)',
        'DELETE FROM note_links WHERE source_note_id IN ($ofSynced)',
        'DELETE FROM attachments WHERE note_id IN ($ofSynced)',
        'UPDATE bible_annotations SET note_id = NULL '
            'WHERE note_id IN ($ofSynced)',
        // Only plain single-verse highlights live on the server; verse notes,
        // ranges and highlights carrying text or a note link stay.
        "DELETE FROM bible_annotations WHERE kind = 'highlight' "
            'AND inline_text IS NULL AND note_id IS NULL '
            "AND verse_ref NOT LIKE '%-%' "
            "AND length(verse_ref) - length(replace(verse_ref, '.', '')) = 2",
        'DELETE FROM notes WHERE $synced',
        'DELETE FROM reading_days',
        'DELETE FROM plan_day_progress',
        'DELETE FROM plan_subscriptions',
        // Last: the writes above fire triggers that queue into the outbox.
        'DELETE FROM sync_outbox',
        'DELETE FROM sync_state',
      ]) {
        await _db.customStatement(q);
      }
    });
    _db.notifyUpdates({
      for (final t in const [
        'notes',
        'note_tags',
        'note_links',
        'attachments',
        'bible_annotations',
        'reading_days',
        'plan_day_progress',
        'plan_subscriptions',
      ])
        TableUpdate(t),
    });
  }

  /// Pull then push. Returns true on success, false when disabled, offline or
  /// failed (the outbox keeps everything for the next run). Overlapping calls
  /// coalesce into one follow-up run.
  Future<bool> sync() async {
    if (_locked) return false;
    if (!enabled) {
      // Paused (consent withdrawn, local-only): nothing leaves the device, but
      // keep queueing so re-enabling pushes without a full re-queue. Only an
      // already-on queue is paused; a never-enabled one stays off.
      if (await _state('sync_enabled') == '1') {
        await _setState('sync_enabled', 'paused');
      }
      return false;
    }
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
    } while (_again && ok && !_locked);
    return ok;
  }

  Future<bool> _run() async {
    try {
      await _prepare();
      // Pull first: if a local edit is about to lose to a newer server copy we
      // must see that before pushing, or the server would drop the push and the
      // local text would vanish without a conflict copy.
      await _pull();
      await _push();
      return true;
    } catch (e, st) {
      _log.warning('sync failed, will retry', e, st);
      return false;
    }
  }

  /// Turns the outbox on and, the first time or when the account changed,
  /// re-queues every local row and forgets the pull cursors (the new account's
  /// server has never seen this data, and its cursors mean nothing here).
  Future<void> _prepare() async {
    final owner = await _remote.identity();
    final flag = await _state('sync_enabled');
    final wasOn = flag == '1' || flag == 'paused';
    final sameOwner = await _state('owner') == owner;
    if (wasOn && sameOwner) {
      if (flag == 'paused') await _setState('sync_enabled', '1');
      return;
    }
    // Signing in to an existing account (new phone, sign-out and back in) lands
    // here: local rows are re-queued into that account (merge, never replace;
    // last write wins per row) and its rows are pulled from a fresh cursor.
    // Nothing local is deleted.
    await _db.transaction(() async {
      await _setState('sync_enabled', '1');
      await _setState('owner', owner);
      await _db.customStatement(
        "DELETE FROM sync_state WHERE key LIKE 'cursor:%'",
      );
      await backfillSyncOutbox(_db);
    });
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
              if (entity == 'plan_day_progress')
                'plan_year': await _planYear(row),
            },
          ));
        }
      }

      try {
        await _remote.push(records);
      } catch (e) {
        if (!_remote.isPermanent(e)) rethrow;
        // One bad record must not block everyone else: retry one by one and
        // drop only the ones the server will never take.
        for (final r in records) {
          try {
            await _remote.push([r]);
          } catch (e) {
            if (!_remote.isPermanent(e)) rethrow;
            _log.severe('dropping unsyncable ${r.entity}/${r.rowId}', e);
          }
        }
      }

      // Clear only what was handled; a row rewritten meanwhile has a newer seq
      // and stays queued.
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

  /// The year the plan run started (from its subscription), so one run keeps
  /// one plan_key even when it crosses New Year. Falls back to the year the day
  /// was completed.
  Future<int> _planYear(Map<String, Object?> progress) async {
    final sub = await _row('plan_subscriptions', progress['plan_id'] as String);
    final start = sub?['start_date_key'] as String?;
    final y = start == null ? null : int.tryParse(start.split('-').first);
    return y ?? _fromSeconds(progress['completed_at']).toUtc().year;
  }

  // --- pull -----------------------------------------------------------------

  Future<void> _pull() async {
    for (final entity in syncedEntities.keys) {
      while (true) {
        final cursor = await _state('cursor:$entity');
        final page = await _remote.pull(entity, cursor);
        if (page.records.isEmpty) break;
        await _db.transaction(() async {
          final copies = <Map<String, Object?>>[];
          await _setState('applying', '1');
          try {
            for (final r in page.records) {
              try {
                await _apply(r, copies);
              } catch (e) {
                // Only a constraint failure means "this row can never be
                // stored here". Anything else (disk, locked, a bug) aborts the
                // page so it is retried instead of silently skipped.
                if (e is! SqliteException || e.resultCode != 19) rethrow;
                _log.severe('skipping ${r.entity}/${r.rowId}', e);
              }
            }
          } finally {
            await _setState('applying', '0');
          }
          // Back outside the quiet window, still in the same transaction:
          // copies are new local rows and the triggers queue them for push.
          for (final c in copies) {
            await _insert('notes', c);
          }
          if (page.cursor != null) {
            await _setState('cursor:$entity', page.cursor!);
          }
        });
        // Raw SQL does not notify drift streams; tell the UI what changed.
        _db.notifyUpdates({TableUpdate(entity)});
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
      // The local edit is about to lose. For notes, keep its text as a copy so
      // nothing typed is ever dropped.
      if (entity == 'notes' && local != null && !r.deleted) {
        final differs = local['title'] != r.payload['title'] ||
            local['content_markdown'] != r.payload['content_markdown'];
        if (differs && local['is_deleted'] == 0) {
          copies.add({
            ...local,
            'id': const Uuid().v4(),
            'title': 'Conflict copy: ${local['title']}',
            'folder_id': null,
          });
        }
      }
    } else if (local != null) {
      // Ties apply: clocks have one-second resolution, so a restore right
      // after a delete shares its timestamp, and the server already ruled the
      // incoming write the winner. Re-applying an identical row is harmless.
      if (r.updatedAt.isBefore(localTime!)) return;
    }

    // The local change leaves the outbox only once the remote one is stored.
    Future<void> settle() async {
      if (pending == null) return;
      await _db.customStatement(
        'DELETE FROM sync_outbox WHERE entity = ? AND row_id = ?',
        [entity, r.rowId],
      );
    }

    if (r.deleted) {
      await _db.customStatement(
        'DELETE FROM $entity WHERE $keyCol = ?',
        [r.rowId],
      );
      await settle();
      return;
    }
    final payload = {...r.payload};
    if (entity == 'bible_annotations' && payload['note_id'] != null) {
      if (await _row('notes', payload['note_id'] as String) == null) {
        payload['note_id'] = null;
      }
    }
    await _insert(entity, payload);
    await settle();
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
