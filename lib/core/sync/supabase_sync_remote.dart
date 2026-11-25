import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'sync_remote.dart';

/// Supabase implementation, mapped onto the reader tables in abide-backend
/// (migration 23). Local entity -> remote table:
///
///   notes              -> u_notes            (title, body_md)
///   bible_annotations  -> u_highlights       (highlights only, one verse each)
///   plan_day_progress  -> u_reading_progress (plan_key '<plan>@<year>')
///   reading_days       -> u_reading_progress (plan_key 'days@<year>', day_index
///                                             = day of year)
///   plan_subscriptions -> u_settings         (key 'plan:<planId>')
///
/// The server does last-write-wins on client_updated_at and stamps updated_at,
/// which is the pull cursor. Deletes are tombstones (deleted_at). user_id is
/// never sent: the column default fills it.
///
/// Known gaps: note created_at, a reading day's `source`, highlight note links,
/// verse ranges and non-highlight annotations have no remote column and stay
/// device-local.
class SupabaseSyncRemote implements SyncRemote {
  SupabaseSyncRemote(this._client);

  final SupabaseClient _client;

  static const _pageSize = 500;
  static const _uuid = Uuid();
  // Fixed namespace so every device derives the same uuid for a highlight.
  static const _ns = '6f1c2b0e-5a4d-4c6a-9d3e-0a7b1c2d3e4f';

  bool _userReady = false;

  // u_notes.title is capped at 300 characters.
  static String _clip(String s) => s.length <= 300 ? s : s.substring(0, 300);

  Future<void> _ensureUser() async {
    if (_userReady) return;
    await _client.rpc('ensure_app_user');
    _userReady = true;
  }

  // --- time helpers (local dates are unix seconds) ---------------------------

  static String _iso(Object? seconds) =>
      DateTime.fromMillisecondsSinceEpoch((seconds as int) * 1000, isUtc: true)
          .toIso8601String();

  static int _secs(Object? iso) =>
      DateTime.parse(iso as String).millisecondsSinceEpoch ~/ 1000;

  static String _dateKey(int year, int dayOfYear) {
    final d = DateTime.utc(year).add(Duration(days: dayOfYear - 1));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  static int _dayOfYear(String dateKey) {
    final p = dateKey.split('-').map(int.parse).toList();
    return DateTime.utc(p[0], p[1], p[2])
            .difference(DateTime.utc(p[0]))
            .inDays +
        1;
  }

  /// `JHN.3.16` -> (JHN, 3, 16), or null.
  static (String, int, int)? _parseVerse(String ref) {
    final p = ref.split('.');
    if (p.length != 3) return null;
    final c = int.tryParse(p[1]), v = int.tryParse(p[2]);
    if (c == null || v == null || c < 1 || v < 1 || p[0].isEmpty) return null;
    return (p[0], c, v);
  }

  static String _highlightLocalId(String book, int c, int v) =>
      'highlight:$book.$c.$v';

  // --- push ------------------------------------------------------------------

  @override
  Future<void> push(List<SyncRecord> records) async {
    await _ensureUser();
    final upserts = <String, List<Map<String, Object?>>>{};
    final conflict = <String, String>{};

    void up(String table, String onConflict, Map<String, Object?> row) {
      upserts.putIfAbsent(table, () => []).add(row);
      conflict[table] = onConflict;
    }

    for (final r in records) {
      final stamp = r.updatedAt.toUtc().toIso8601String();
      if (r.deleted) {
        await _tombstone(r, stamp);
        continue;
      }
      final p = r.payload;
      switch (r.entity) {
        case 'notes':
          if (!Uuid.isValidUUID(fromString: r.rowId)) break; // not syncable
          up('u_notes', 'id', {
            'id': r.rowId,
            'title': _clip(p['title'] as String),
            'body_md': p['content_markdown'],
            'client_updated_at': stamp,
            'deleted_at': p['is_deleted'] == 1 ? stamp : null,
          });
        case 'bible_annotations':
          final v = p['kind'] == 'highlight'
              ? _parseVerse(p['verse_ref'] as String)
              : null;
          if (v == null) break; // only single-verse highlights have a home
          up('u_highlights', 'id', {
            'id': _uuid.v5(_ns, _highlightLocalId(v.$1, v.$2, v.$3)),
            'translation': '*', // local highlights are edition-independent
            'book': v.$1,
            'chapter': v.$2,
            'verse_start': v.$3,
            'verse_end': v.$3,
            'color': p['color'] ?? 'yellow',
            'client_updated_at': stamp,
            'deleted_at': p['is_deleted'] == 1 ? stamp : null,
          });
        case 'plan_day_progress':
          final done = DateTime.parse(_iso(p['completed_at']));
          up('u_reading_progress', 'user_id,plan_key,day_index', {
            'plan_key': '${p['plan_id']}@${done.year}',
            'day_index': p['day_index'],
            'completed_at': _iso(p['completed_at']),
            'client_updated_at': stamp,
            'deleted_at': null,
          });
        case 'reading_days':
          final key = p['date_key'] as String;
          up('u_reading_progress', 'user_id,plan_key,day_index', {
            'plan_key': 'days@${key.substring(0, 4)}',
            'day_index': _dayOfYear(key),
            'completed_at': _iso(p['completed_at']),
            'client_updated_at': stamp,
            'deleted_at': null,
          });
        case 'plan_subscriptions':
          up('u_settings', 'user_id,key', {
            'key': 'plan:${p['plan_id']}',
            'value': {
              'start_date_key': p['start_date_key'],
              'is_active': p['is_active'] == 1,
            },
            'client_updated_at': stamp,
            'deleted_at': null,
          });
      }
    }

    for (final e in upserts.entries) {
      await _client.from(e.key).upsert(e.value, onConflict: conflict[e.key]);
    }
  }

  Future<void> _tombstone(SyncRecord r, String stamp) async {
    final patch = {'deleted_at': stamp, 'client_updated_at': stamp};
    switch (r.entity) {
      case 'notes':
        if (!Uuid.isValidUUID(fromString: r.rowId)) return;
        await _client.from('u_notes').update(patch).eq('id', r.rowId);
      case 'bible_annotations':
        final v = _parseVerse(r.rowId.replaceFirst('highlight:', ''));
        if (v == null) return;
        await _client
            .from('u_highlights')
            .update(patch)
            .eq('id', _uuid.v5(_ns, _highlightLocalId(v.$1, v.$2, v.$3)));
      case 'plan_day_progress':
        final i = r.rowId.lastIndexOf(':');
        await _client
            .from('u_reading_progress')
            .update(patch)
            .like('plan_key', '${r.rowId.substring(0, i)}@%')
            .eq('day_index', int.parse(r.rowId.substring(i + 1)));
      case 'reading_days':
        await _client
            .from('u_reading_progress')
            .update(patch)
            .eq('plan_key', 'days@${r.rowId.substring(0, 4)}')
            .eq('day_index', _dayOfYear(r.rowId));
      case 'plan_subscriptions':
        await _client
            .from('u_settings')
            .update(patch)
            .eq('key', 'plan:${r.rowId}');
    }
  }

  // --- pull ------------------------------------------------------------------

  @override
  Future<SyncPage> pull(String entity, String? cursor) async {
    await _ensureUser();
    final table = switch (entity) {
      'notes' => 'u_notes',
      'bible_annotations' => 'u_highlights',
      'plan_subscriptions' => 'u_settings',
      _ => 'u_reading_progress',
    };
    var q = _client.from(table).select();
    if (entity == 'reading_days') q = q.like('plan_key', 'days@%');
    if (entity == 'plan_day_progress') q = q.not('plan_key', 'like', 'days@%');
    if (entity == 'plan_subscriptions') q = q.like('key', 'plan:%');
    // >= with idempotent applies, as the backend contract advises, so rows that
    // share a timestamp across a page boundary are never skipped.
    if (cursor != null) q = q.gte('updated_at', cursor);
    final rows = await q.order('updated_at').limit(_pageSize);

    final out = <SyncRecord>[];
    for (final r in rows) {
      final rec = _toRecord(entity, r);
      if (rec != null) out.add(rec);
    }
    if (rows.isEmpty) return SyncPage(const [], cursor);
    final next = rows.last['updated_at'] as String;
    // A full page of identical timestamps would loop forever on >=; the
    // service stops when the cursor does not advance.
    return SyncPage(next == cursor ? const [] : out, next);
  }

  SyncRecord? _toRecord(String entity, Map<String, dynamic> r) {
    final updated = DateTime.parse(r['client_updated_at'] as String);
    final deleted = r['deleted_at'] != null;
    final tomb = SyncRecord(
      entity: entity,
      rowId: '',
      updatedAt: updated,
      deleted: true,
    );
    SyncRecord rec(String id, Map<String, Object?> payload) => SyncRecord(
          entity: entity,
          rowId: id,
          updatedAt: updated,
          deleted: deleted,
          payload: deleted ? const {} : payload,
        );
    final stamp = updated.millisecondsSinceEpoch ~/ 1000;

    switch (entity) {
      case 'notes':
        // Soft delete locally: keep the row, flag it.
        return SyncRecord(
          entity: entity,
          rowId: r['id'] as String,
          updatedAt: updated,
          payload: {
            'id': r['id'],
            'title': r['title'],
            'content_markdown': r['body_md'],
            'created_at': stamp,
            'updated_at': stamp,
            'is_deleted': deleted ? 1 : 0,
          },
        );
      case 'bible_annotations':
        final id = _highlightLocalId(
          r['book'] as String,
          r['chapter'] as int,
          r['verse_start'] as int,
        );
        return SyncRecord(
          entity: entity,
          rowId: id,
          updatedAt: updated,
          payload: {
            'id': id,
            'verse_ref': id.substring('highlight:'.length),
            'kind': 'highlight',
            'color': r['color'],
            'updated_at': stamp,
            'is_deleted': deleted ? 1 : 0,
          },
        );
      case 'plan_day_progress':
        final key = r['plan_key'] as String;
        final plan = key.substring(0, key.lastIndexOf('@'));
        final day = r['day_index'] as int;
        return rec('$plan:$day', {
          'id': '$plan:$day',
          'plan_id': plan,
          'day_index': day,
          'completed_at': _secs(r['completed_at']),
        });
      case 'reading_days':
        final year = int.parse((r['plan_key'] as String).substring(5, 9));
        final key = _dateKey(year, r['day_index'] as int);
        return rec(key, {
          'date_key': key,
          'source': 'synced',
          'completed_at': _secs(r['completed_at']),
        });
      case 'plan_subscriptions':
        final plan = (r['key'] as String).substring('plan:'.length);
        final v = Map<String, Object?>.from(r['value'] as Map);
        return rec(plan, {
          'plan_id': plan,
          'start_date_key': v['start_date_key'],
          'is_active': v['is_active'] == true ? 1 : 0,
          'updated_at': stamp,
        });
    }
    return tomb;
  }
}
