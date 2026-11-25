import 'package:drift/drift.dart';

/// User notes. Markdown is the source of truth; everything else (links, search
/// index, attachments) is derived from [contentMarkdown] on save.
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get contentMarkdown => text().withDefault(const Constant(''))();
  TextColumn get folderId => text().nullable().references(Folders, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Optional single-level buckets (e.g. "Sermons"). No deep nesting is used,
/// but [parentId] keeps the door open without a future migration.
class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get parentId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class NoteTags extends Table {
  TextColumn get noteId => text().references(Notes, #id)();
  TextColumn get tagId => text().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {noteId, tagId};
}

/// Outgoing links parsed from a note's markdown. [targetType] is one of
/// note|hymn|bible; [targetKey] holds the note id, hymn id, or OSIS verse ref.
class NoteLinks extends Table {
  TextColumn get id => text()();
  TextColumn get sourceNoteId => text().references(Notes, #id)();
  TextColumn get targetType => text()();
  TextColumn get targetKey => text()();
  TextColumn get rawToken => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Image/audio files stored on disk, indexed here. [transcript] is populated
/// later by on-device transcription and then feeds full-text search.
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text().references(Notes, #id)();
  TextColumn get kind => text()();
  TextColumn get relativePath => text()();
  IntColumn get durationMs => integer().nullable()();
  TextColumn get transcript => text().nullable()();
  DateTimeColumn get transcribedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per day the user completed a devotion. The streak is *derived* from
/// these rows and never stored as a counter -- see `features/daily/domain/
/// streak.dart` for why a stored count is a lie waiting to happen.
///
/// [dateKey] is the primary key, so marking the same day done twice is a no-op
/// by construction rather than by remembering to check first.
class ReadingDays extends Table {
  /// Local calendar day, `YYYY-MM-DD`. A date key, not a timestamp: the streak
  /// asks a calendar question ("did they read yesterday"), and 24-hour
  /// arithmetic answers it wrong on the two days a year the clock jumps.
  TextColumn get dateKey => text()();

  /// What earned the day: `plan` | `chapter` | `altar`. `altar` is unused today
  /// and deliberately allowed for -- Family Altar plugs into this same streak
  /// engine later, and a string column means it does so without a migration.
  TextColumn get source => text()();

  DateTimeColumn get completedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {dateKey};
}

/// The plan a user is following. One row per plan they have ever started, so
/// switching plans and coming back does not lose where they were.
class PlanSubscriptions extends Table {
  /// Slug from `assets/plans/<id>.json`, e.g. `bible-in-a-year`.
  TextColumn get planId => text()();

  /// The day the plan began. Day N of the plan is [startDateKey] + (N - 1), so
  /// "which day am I on" is calendar arithmetic rather than a stored cursor
  /// that can drift out of step with the completed rows.
  TextColumn get startDateKey => text()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Last-write-wins clock for sync. Rows from before v5 read as the epoch, so
  /// any real edit (on any device) beats them.
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(const CustomExpression('0'))();

  @override
  Set<Column> get primaryKey => {planId};
}

/// One row per completed day *of a plan*, which is not the same thing as a
/// completed calendar day: someone catching up reads three plan days in one
/// sitting, and someone who reads a chapter outside their plan earns the
/// calendar day without advancing the plan.
class PlanDayProgress extends Table {
  /// Deterministic: `<planId>:<dayIndex>`. Makes "mark this day read"
  /// idempotent under insertOnConflictUpdate with no read-modify-write.
  TextColumn get id => text()();

  TextColumn get planId => text()();

  /// 1-based, matching `PlanDay.dayIndex` in the JSON. An off-by-one here does
  /// not crash -- it silently credits the wrong day.
  IntColumn get dayIndex => integer()();

  DateTimeColumn get completedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Thin annotation layer keyed by a canonical OSIS verse ref. Bible text itself
/// stays read-only JSON; only highlights and verse notes live here.
class BibleAnnotations extends Table {
  TextColumn get id => text()();
  TextColumn get verseRef => text()();
  TextColumn get kind => text()();
  TextColumn get color => text().nullable()();
  TextColumn get noteId => text().nullable().references(Notes, #id)();
  TextColumn get inlineText => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local changes not yet pushed. Filled by SQLite triggers (see
/// `core/sync/sync_triggers.dart`), so every writer is covered without touching
/// the DAOs. One row per (entity, row): later writes replace earlier ones.
class SyncOutbox extends Table {
  TextColumn get entity => text()();
  TextColumn get rowId => text()();

  /// `upsert` | `delete`.
  TextColumn get op => text()();

  /// Bumped on every write to the row; push only clears the exact [seq] it sent.
  IntColumn get seq => integer()();

  /// Unix seconds. Doubles as the tombstone time of a hard delete.
  IntColumn get queuedAt => integer()();

  @override
  Set<Column> get primaryKey => {entity, rowId};
}

/// Small key/value store for sync: per-entity pull cursors and the `applying`
/// flag that keeps pulled rows out of the outbox.
class SyncState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
