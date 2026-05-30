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
