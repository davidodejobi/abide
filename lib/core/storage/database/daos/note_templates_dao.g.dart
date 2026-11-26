// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_templates_dao.dart';

// ignore_for_file: type=lint
mixin _$NoteTemplatesDaoMixin on DatabaseAccessor<AppDatabase> {
  $NoteTemplatesTable get noteTemplates => attachedDatabase.noteTemplates;
  NoteTemplatesDaoManager get managers => NoteTemplatesDaoManager(this);
}

class NoteTemplatesDaoManager {
  final _$NoteTemplatesDaoMixin _db;
  NoteTemplatesDaoManager(this._db);
  $$NoteTemplatesTableTableManager get noteTemplates =>
      $$NoteTemplatesTableTableManager(_db.attachedDatabase, _db.noteTemplates);
}
