// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bible_annotations_dao.dart';

// ignore_for_file: type=lint
mixin _$BibleAnnotationsDaoMixin on DatabaseAccessor<AppDatabase> {
  $FoldersTable get folders => attachedDatabase.folders;
  $NotesTable get notes => attachedDatabase.notes;
  $BibleAnnotationsTable get bibleAnnotations =>
      attachedDatabase.bibleAnnotations;
  BibleAnnotationsDaoManager get managers => BibleAnnotationsDaoManager(this);
}

class BibleAnnotationsDaoManager {
  final _$BibleAnnotationsDaoMixin _db;
  BibleAnnotationsDaoManager(this._db);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db.attachedDatabase, _db.folders);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db.attachedDatabase, _db.notes);
  $$BibleAnnotationsTableTableManager get bibleAnnotations =>
      $$BibleAnnotationsTableTableManager(
          _db.attachedDatabase, _db.bibleAnnotations);
}
