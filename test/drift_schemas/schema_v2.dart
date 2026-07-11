// dart format width=80
// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';

class Folders extends Table with TableInfo<Folders, FoldersData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Folders(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, name, parentId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoldersData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoldersData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
    );
  }

  @override
  Folders createAlias(String alias) {
    return Folders(attachedDatabase, alias);
  }
}

class FoldersData extends DataClass implements Insertable<FoldersData> {
  final String id;
  final String name;
  final String? parentId;
  const FoldersData({required this.id, required this.name, this.parentId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    return map;
  }

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      id: Value(id),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
    );
  }

  factory FoldersData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoldersData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
    };
  }

  FoldersData copyWith(
          {String? id,
          String? name,
          Value<String?> parentId = const Value.absent()}) =>
      FoldersData(
        id: id ?? this.id,
        name: name ?? this.name,
        parentId: parentId.present ? parentId.value : this.parentId,
      );
  FoldersData copyWithCompanion(FoldersCompanion data) {
    return FoldersData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoldersData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, parentId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoldersData &&
          other.id == this.id &&
          other.name == this.name &&
          other.parentId == this.parentId);
}

class FoldersCompanion extends UpdateCompanion<FoldersData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<int> rowid;
  const FoldersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoldersCompanion.insert({
    required String id,
    required String name,
    this.parentId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<FoldersData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoldersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? parentId,
      Value<int>? rowid}) {
    return FoldersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Notes extends Table with TableInfo<Notes, NotesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Notes(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('\'\''));
  late final GeneratedColumn<String> contentMarkdown = GeneratedColumn<String>(
      'content_markdown', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('\'\''));
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
      'folder_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES folders (id)'));
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, contentMarkdown, folderId, createdAt, updatedAt, isDeleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotesData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      contentMarkdown: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}content_markdown'])!,
      folderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  Notes createAlias(String alias) {
    return Notes(attachedDatabase, alias);
  }
}

class NotesData extends DataClass implements Insertable<NotesData> {
  final String id;
  final String title;
  final String contentMarkdown;
  final String? folderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  const NotesData(
      {required this.id,
      required this.title,
      required this.contentMarkdown,
      this.folderId,
      required this.createdAt,
      required this.updatedAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['content_markdown'] = Variable<String>(contentMarkdown);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      title: Value(title),
      contentMarkdown: Value(contentMarkdown),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory NotesData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotesData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      contentMarkdown: serializer.fromJson<String>(json['contentMarkdown']),
      folderId: serializer.fromJson<String?>(json['folderId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'contentMarkdown': serializer.toJson<String>(contentMarkdown),
      'folderId': serializer.toJson<String?>(folderId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  NotesData copyWith(
          {String? id,
          String? title,
          String? contentMarkdown,
          Value<String?> folderId = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? isDeleted}) =>
      NotesData(
        id: id ?? this.id,
        title: title ?? this.title,
        contentMarkdown: contentMarkdown ?? this.contentMarkdown,
        folderId: folderId.present ? folderId.value : this.folderId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  NotesData copyWithCompanion(NotesCompanion data) {
    return NotesData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      contentMarkdown: data.contentMarkdown.present
          ? data.contentMarkdown.value
          : this.contentMarkdown,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotesData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('contentMarkdown: $contentMarkdown, ')
          ..write('folderId: $folderId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, title, contentMarkdown, folderId, createdAt, updatedAt, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotesData &&
          other.id == this.id &&
          other.title == this.title &&
          other.contentMarkdown == this.contentMarkdown &&
          other.folderId == this.folderId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class NotesCompanion extends UpdateCompanion<NotesData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> contentMarkdown;
  final Value<String?> folderId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.contentMarkdown = const Value.absent(),
    this.folderId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    this.contentMarkdown = const Value.absent(),
    this.folderId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<NotesData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? contentMarkdown,
    Expression<String>? folderId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (contentMarkdown != null) 'content_markdown': contentMarkdown,
      if (folderId != null) 'folder_id': folderId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? contentMarkdown,
      Value<String?>? folderId,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? isDeleted,
      Value<int>? rowid}) {
    return NotesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      contentMarkdown: contentMarkdown ?? this.contentMarkdown,
      folderId: folderId ?? this.folderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (contentMarkdown.present) {
      map['content_markdown'] = Variable<String>(contentMarkdown.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('contentMarkdown: $contentMarkdown, ')
          ..write('folderId: $folderId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Tags extends Table with TableInfo<Tags, TagsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Tags(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagsData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  Tags createAlias(String alias) {
    return Tags(attachedDatabase, alias);
  }
}

class TagsData extends DataClass implements Insertable<TagsData> {
  final String id;
  final String name;
  const TagsData({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory TagsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagsData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  TagsData copyWith({String? id, String? name}) => TagsData(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  TagsData copyWithCompanion(TagsCompanion data) {
    return TagsData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagsData(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagsData && other.id == this.id && other.name == this.name);
}

class TagsCompanion extends UpdateCompanion<TagsData> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String name,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<TagsData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith(
      {Value<String>? id, Value<String>? name, Value<int>? rowid}) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class NoteTags extends Table with TableInfo<NoteTags, NoteTagsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  NoteTags(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
      'note_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES notes (id)'));
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
      'tag_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES tags (id)'));
  @override
  List<GeneratedColumn> get $columns => [noteId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_tags';
  @override
  Set<GeneratedColumn> get $primaryKey => {noteId, tagId};
  @override
  NoteTagsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteTagsData(
      noteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_id'])!,
      tagId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag_id'])!,
    );
  }

  @override
  NoteTags createAlias(String alias) {
    return NoteTags(attachedDatabase, alias);
  }
}

class NoteTagsData extends DataClass implements Insertable<NoteTagsData> {
  final String noteId;
  final String tagId;
  const NoteTagsData({required this.noteId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['note_id'] = Variable<String>(noteId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  NoteTagsCompanion toCompanion(bool nullToAbsent) {
    return NoteTagsCompanion(
      noteId: Value(noteId),
      tagId: Value(tagId),
    );
  }

  factory NoteTagsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteTagsData(
      noteId: serializer.fromJson<String>(json['noteId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'noteId': serializer.toJson<String>(noteId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  NoteTagsData copyWith({String? noteId, String? tagId}) => NoteTagsData(
        noteId: noteId ?? this.noteId,
        tagId: tagId ?? this.tagId,
      );
  NoteTagsData copyWithCompanion(NoteTagsCompanion data) {
    return NoteTagsData(
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteTagsData(')
          ..write('noteId: $noteId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(noteId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteTagsData &&
          other.noteId == this.noteId &&
          other.tagId == this.tagId);
}

class NoteTagsCompanion extends UpdateCompanion<NoteTagsData> {
  final Value<String> noteId;
  final Value<String> tagId;
  final Value<int> rowid;
  const NoteTagsCompanion({
    this.noteId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteTagsCompanion.insert({
    required String noteId,
    required String tagId,
    this.rowid = const Value.absent(),
  })  : noteId = Value(noteId),
        tagId = Value(tagId);
  static Insertable<NoteTagsData> custom({
    Expression<String>? noteId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (noteId != null) 'note_id': noteId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteTagsCompanion copyWith(
      {Value<String>? noteId, Value<String>? tagId, Value<int>? rowid}) {
    return NoteTagsCompanion(
      noteId: noteId ?? this.noteId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteTagsCompanion(')
          ..write('noteId: $noteId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class NoteLinks extends Table with TableInfo<NoteLinks, NoteLinksData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  NoteLinks(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> sourceNoteId = GeneratedColumn<String>(
      'source_note_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES notes (id)'));
  late final GeneratedColumn<String> targetType = GeneratedColumn<String>(
      'target_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> targetKey = GeneratedColumn<String>(
      'target_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> rawToken = GeneratedColumn<String>(
      'raw_token', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, sourceNoteId, targetType, targetKey, rawToken];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_links';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteLinksData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteLinksData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sourceNoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_note_id'])!,
      targetType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_type'])!,
      targetKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_key'])!,
      rawToken: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}raw_token'])!,
    );
  }

  @override
  NoteLinks createAlias(String alias) {
    return NoteLinks(attachedDatabase, alias);
  }
}

class NoteLinksData extends DataClass implements Insertable<NoteLinksData> {
  final String id;
  final String sourceNoteId;
  final String targetType;
  final String targetKey;
  final String rawToken;
  const NoteLinksData(
      {required this.id,
      required this.sourceNoteId,
      required this.targetType,
      required this.targetKey,
      required this.rawToken});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_note_id'] = Variable<String>(sourceNoteId);
    map['target_type'] = Variable<String>(targetType);
    map['target_key'] = Variable<String>(targetKey);
    map['raw_token'] = Variable<String>(rawToken);
    return map;
  }

  NoteLinksCompanion toCompanion(bool nullToAbsent) {
    return NoteLinksCompanion(
      id: Value(id),
      sourceNoteId: Value(sourceNoteId),
      targetType: Value(targetType),
      targetKey: Value(targetKey),
      rawToken: Value(rawToken),
    );
  }

  factory NoteLinksData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteLinksData(
      id: serializer.fromJson<String>(json['id']),
      sourceNoteId: serializer.fromJson<String>(json['sourceNoteId']),
      targetType: serializer.fromJson<String>(json['targetType']),
      targetKey: serializer.fromJson<String>(json['targetKey']),
      rawToken: serializer.fromJson<String>(json['rawToken']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceNoteId': serializer.toJson<String>(sourceNoteId),
      'targetType': serializer.toJson<String>(targetType),
      'targetKey': serializer.toJson<String>(targetKey),
      'rawToken': serializer.toJson<String>(rawToken),
    };
  }

  NoteLinksData copyWith(
          {String? id,
          String? sourceNoteId,
          String? targetType,
          String? targetKey,
          String? rawToken}) =>
      NoteLinksData(
        id: id ?? this.id,
        sourceNoteId: sourceNoteId ?? this.sourceNoteId,
        targetType: targetType ?? this.targetType,
        targetKey: targetKey ?? this.targetKey,
        rawToken: rawToken ?? this.rawToken,
      );
  NoteLinksData copyWithCompanion(NoteLinksCompanion data) {
    return NoteLinksData(
      id: data.id.present ? data.id.value : this.id,
      sourceNoteId: data.sourceNoteId.present
          ? data.sourceNoteId.value
          : this.sourceNoteId,
      targetType:
          data.targetType.present ? data.targetType.value : this.targetType,
      targetKey: data.targetKey.present ? data.targetKey.value : this.targetKey,
      rawToken: data.rawToken.present ? data.rawToken.value : this.rawToken,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteLinksData(')
          ..write('id: $id, ')
          ..write('sourceNoteId: $sourceNoteId, ')
          ..write('targetType: $targetType, ')
          ..write('targetKey: $targetKey, ')
          ..write('rawToken: $rawToken')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sourceNoteId, targetType, targetKey, rawToken);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteLinksData &&
          other.id == this.id &&
          other.sourceNoteId == this.sourceNoteId &&
          other.targetType == this.targetType &&
          other.targetKey == this.targetKey &&
          other.rawToken == this.rawToken);
}

class NoteLinksCompanion extends UpdateCompanion<NoteLinksData> {
  final Value<String> id;
  final Value<String> sourceNoteId;
  final Value<String> targetType;
  final Value<String> targetKey;
  final Value<String> rawToken;
  final Value<int> rowid;
  const NoteLinksCompanion({
    this.id = const Value.absent(),
    this.sourceNoteId = const Value.absent(),
    this.targetType = const Value.absent(),
    this.targetKey = const Value.absent(),
    this.rawToken = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteLinksCompanion.insert({
    required String id,
    required String sourceNoteId,
    required String targetType,
    required String targetKey,
    required String rawToken,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sourceNoteId = Value(sourceNoteId),
        targetType = Value(targetType),
        targetKey = Value(targetKey),
        rawToken = Value(rawToken);
  static Insertable<NoteLinksData> custom({
    Expression<String>? id,
    Expression<String>? sourceNoteId,
    Expression<String>? targetType,
    Expression<String>? targetKey,
    Expression<String>? rawToken,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceNoteId != null) 'source_note_id': sourceNoteId,
      if (targetType != null) 'target_type': targetType,
      if (targetKey != null) 'target_key': targetKey,
      if (rawToken != null) 'raw_token': rawToken,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteLinksCompanion copyWith(
      {Value<String>? id,
      Value<String>? sourceNoteId,
      Value<String>? targetType,
      Value<String>? targetKey,
      Value<String>? rawToken,
      Value<int>? rowid}) {
    return NoteLinksCompanion(
      id: id ?? this.id,
      sourceNoteId: sourceNoteId ?? this.sourceNoteId,
      targetType: targetType ?? this.targetType,
      targetKey: targetKey ?? this.targetKey,
      rawToken: rawToken ?? this.rawToken,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceNoteId.present) {
      map['source_note_id'] = Variable<String>(sourceNoteId.value);
    }
    if (targetType.present) {
      map['target_type'] = Variable<String>(targetType.value);
    }
    if (targetKey.present) {
      map['target_key'] = Variable<String>(targetKey.value);
    }
    if (rawToken.present) {
      map['raw_token'] = Variable<String>(rawToken.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteLinksCompanion(')
          ..write('id: $id, ')
          ..write('sourceNoteId: $sourceNoteId, ')
          ..write('targetType: $targetType, ')
          ..write('targetKey: $targetKey, ')
          ..write('rawToken: $rawToken, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Attachments extends Table with TableInfo<Attachments, AttachmentsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Attachments(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
      'note_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES notes (id)'));
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
      'relative_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  late final GeneratedColumn<String> transcript = GeneratedColumn<String>(
      'transcript', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> transcribedAt =
      GeneratedColumn<DateTime>('transcribed_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        noteId,
        kind,
        relativePath,
        durationMs,
        transcript,
        transcribedAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttachmentsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentsData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      noteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      relativePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}relative_path'])!,
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms']),
      transcript: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transcript']),
      transcribedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}transcribed_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  Attachments createAlias(String alias) {
    return Attachments(attachedDatabase, alias);
  }
}

class AttachmentsData extends DataClass implements Insertable<AttachmentsData> {
  final String id;
  final String noteId;
  final String kind;
  final String relativePath;
  final int? durationMs;
  final String? transcript;
  final DateTime? transcribedAt;
  final DateTime createdAt;
  const AttachmentsData(
      {required this.id,
      required this.noteId,
      required this.kind,
      required this.relativePath,
      this.durationMs,
      this.transcript,
      this.transcribedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['note_id'] = Variable<String>(noteId);
    map['kind'] = Variable<String>(kind);
    map['relative_path'] = Variable<String>(relativePath);
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || transcript != null) {
      map['transcript'] = Variable<String>(transcript);
    }
    if (!nullToAbsent || transcribedAt != null) {
      map['transcribed_at'] = Variable<DateTime>(transcribedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      noteId: Value(noteId),
      kind: Value(kind),
      relativePath: Value(relativePath),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      transcript: transcript == null && nullToAbsent
          ? const Value.absent()
          : Value(transcript),
      transcribedAt: transcribedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(transcribedAt),
      createdAt: Value(createdAt),
    );
  }

  factory AttachmentsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttachmentsData(
      id: serializer.fromJson<String>(json['id']),
      noteId: serializer.fromJson<String>(json['noteId']),
      kind: serializer.fromJson<String>(json['kind']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      transcript: serializer.fromJson<String?>(json['transcript']),
      transcribedAt: serializer.fromJson<DateTime?>(json['transcribedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'noteId': serializer.toJson<String>(noteId),
      'kind': serializer.toJson<String>(kind),
      'relativePath': serializer.toJson<String>(relativePath),
      'durationMs': serializer.toJson<int?>(durationMs),
      'transcript': serializer.toJson<String?>(transcript),
      'transcribedAt': serializer.toJson<DateTime?>(transcribedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AttachmentsData copyWith(
          {String? id,
          String? noteId,
          String? kind,
          String? relativePath,
          Value<int?> durationMs = const Value.absent(),
          Value<String?> transcript = const Value.absent(),
          Value<DateTime?> transcribedAt = const Value.absent(),
          DateTime? createdAt}) =>
      AttachmentsData(
        id: id ?? this.id,
        noteId: noteId ?? this.noteId,
        kind: kind ?? this.kind,
        relativePath: relativePath ?? this.relativePath,
        durationMs: durationMs.present ? durationMs.value : this.durationMs,
        transcript: transcript.present ? transcript.value : this.transcript,
        transcribedAt:
            transcribedAt.present ? transcribedAt.value : this.transcribedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  AttachmentsData copyWithCompanion(AttachmentsCompanion data) {
    return AttachmentsData(
      id: data.id.present ? data.id.value : this.id,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      kind: data.kind.present ? data.kind.value : this.kind,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      transcript:
          data.transcript.present ? data.transcript.value : this.transcript,
      transcribedAt: data.transcribedAt.present
          ? data.transcribedAt.value
          : this.transcribedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsData(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('kind: $kind, ')
          ..write('relativePath: $relativePath, ')
          ..write('durationMs: $durationMs, ')
          ..write('transcript: $transcript, ')
          ..write('transcribedAt: $transcribedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, noteId, kind, relativePath, durationMs,
      transcript, transcribedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttachmentsData &&
          other.id == this.id &&
          other.noteId == this.noteId &&
          other.kind == this.kind &&
          other.relativePath == this.relativePath &&
          other.durationMs == this.durationMs &&
          other.transcript == this.transcript &&
          other.transcribedAt == this.transcribedAt &&
          other.createdAt == this.createdAt);
}

class AttachmentsCompanion extends UpdateCompanion<AttachmentsData> {
  final Value<String> id;
  final Value<String> noteId;
  final Value<String> kind;
  final Value<String> relativePath;
  final Value<int?> durationMs;
  final Value<String?> transcript;
  final Value<DateTime?> transcribedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.kind = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.transcript = const Value.absent(),
    this.transcribedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String id,
    required String noteId,
    required String kind,
    required String relativePath,
    this.durationMs = const Value.absent(),
    this.transcript = const Value.absent(),
    this.transcribedAt = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        noteId = Value(noteId),
        kind = Value(kind),
        relativePath = Value(relativePath),
        createdAt = Value(createdAt);
  static Insertable<AttachmentsData> custom({
    Expression<String>? id,
    Expression<String>? noteId,
    Expression<String>? kind,
    Expression<String>? relativePath,
    Expression<int>? durationMs,
    Expression<String>? transcript,
    Expression<DateTime>? transcribedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (noteId != null) 'note_id': noteId,
      if (kind != null) 'kind': kind,
      if (relativePath != null) 'relative_path': relativePath,
      if (durationMs != null) 'duration_ms': durationMs,
      if (transcript != null) 'transcript': transcript,
      if (transcribedAt != null) 'transcribed_at': transcribedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? noteId,
      Value<String>? kind,
      Value<String>? relativePath,
      Value<int?>? durationMs,
      Value<String?>? transcript,
      Value<DateTime?>? transcribedAt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      kind: kind ?? this.kind,
      relativePath: relativePath ?? this.relativePath,
      durationMs: durationMs ?? this.durationMs,
      transcript: transcript ?? this.transcript,
      transcribedAt: transcribedAt ?? this.transcribedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (transcript.present) {
      map['transcript'] = Variable<String>(transcript.value);
    }
    if (transcribedAt.present) {
      map['transcribed_at'] = Variable<DateTime>(transcribedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('kind: $kind, ')
          ..write('relativePath: $relativePath, ')
          ..write('durationMs: $durationMs, ')
          ..write('transcript: $transcript, ')
          ..write('transcribedAt: $transcribedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class BibleAnnotations extends Table
    with TableInfo<BibleAnnotations, BibleAnnotationsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  BibleAnnotations(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> verseRef = GeneratedColumn<String>(
      'verse_ref', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
      'note_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES notes (id)'));
  late final GeneratedColumn<String> inlineText = GeneratedColumn<String>(
      'inline_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, verseRef, kind, color, noteId, inlineText, updatedAt, isDeleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bible_annotations';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BibleAnnotationsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BibleAnnotationsData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      verseRef: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}verse_ref'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      noteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_id']),
      inlineText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}inline_text']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  BibleAnnotations createAlias(String alias) {
    return BibleAnnotations(attachedDatabase, alias);
  }
}

class BibleAnnotationsData extends DataClass
    implements Insertable<BibleAnnotationsData> {
  final String id;
  final String verseRef;
  final String kind;
  final String? color;
  final String? noteId;
  final String? inlineText;
  final DateTime updatedAt;
  final bool isDeleted;
  const BibleAnnotationsData(
      {required this.id,
      required this.verseRef,
      required this.kind,
      this.color,
      this.noteId,
      this.inlineText,
      required this.updatedAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['verse_ref'] = Variable<String>(verseRef);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || noteId != null) {
      map['note_id'] = Variable<String>(noteId);
    }
    if (!nullToAbsent || inlineText != null) {
      map['inline_text'] = Variable<String>(inlineText);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  BibleAnnotationsCompanion toCompanion(bool nullToAbsent) {
    return BibleAnnotationsCompanion(
      id: Value(id),
      verseRef: Value(verseRef),
      kind: Value(kind),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      noteId:
          noteId == null && nullToAbsent ? const Value.absent() : Value(noteId),
      inlineText: inlineText == null && nullToAbsent
          ? const Value.absent()
          : Value(inlineText),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory BibleAnnotationsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BibleAnnotationsData(
      id: serializer.fromJson<String>(json['id']),
      verseRef: serializer.fromJson<String>(json['verseRef']),
      kind: serializer.fromJson<String>(json['kind']),
      color: serializer.fromJson<String?>(json['color']),
      noteId: serializer.fromJson<String?>(json['noteId']),
      inlineText: serializer.fromJson<String?>(json['inlineText']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'verseRef': serializer.toJson<String>(verseRef),
      'kind': serializer.toJson<String>(kind),
      'color': serializer.toJson<String?>(color),
      'noteId': serializer.toJson<String?>(noteId),
      'inlineText': serializer.toJson<String?>(inlineText),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  BibleAnnotationsData copyWith(
          {String? id,
          String? verseRef,
          String? kind,
          Value<String?> color = const Value.absent(),
          Value<String?> noteId = const Value.absent(),
          Value<String?> inlineText = const Value.absent(),
          DateTime? updatedAt,
          bool? isDeleted}) =>
      BibleAnnotationsData(
        id: id ?? this.id,
        verseRef: verseRef ?? this.verseRef,
        kind: kind ?? this.kind,
        color: color.present ? color.value : this.color,
        noteId: noteId.present ? noteId.value : this.noteId,
        inlineText: inlineText.present ? inlineText.value : this.inlineText,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  BibleAnnotationsData copyWithCompanion(BibleAnnotationsCompanion data) {
    return BibleAnnotationsData(
      id: data.id.present ? data.id.value : this.id,
      verseRef: data.verseRef.present ? data.verseRef.value : this.verseRef,
      kind: data.kind.present ? data.kind.value : this.kind,
      color: data.color.present ? data.color.value : this.color,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      inlineText:
          data.inlineText.present ? data.inlineText.value : this.inlineText,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BibleAnnotationsData(')
          ..write('id: $id, ')
          ..write('verseRef: $verseRef, ')
          ..write('kind: $kind, ')
          ..write('color: $color, ')
          ..write('noteId: $noteId, ')
          ..write('inlineText: $inlineText, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, verseRef, kind, color, noteId, inlineText, updatedAt, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BibleAnnotationsData &&
          other.id == this.id &&
          other.verseRef == this.verseRef &&
          other.kind == this.kind &&
          other.color == this.color &&
          other.noteId == this.noteId &&
          other.inlineText == this.inlineText &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class BibleAnnotationsCompanion extends UpdateCompanion<BibleAnnotationsData> {
  final Value<String> id;
  final Value<String> verseRef;
  final Value<String> kind;
  final Value<String?> color;
  final Value<String?> noteId;
  final Value<String?> inlineText;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const BibleAnnotationsCompanion({
    this.id = const Value.absent(),
    this.verseRef = const Value.absent(),
    this.kind = const Value.absent(),
    this.color = const Value.absent(),
    this.noteId = const Value.absent(),
    this.inlineText = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BibleAnnotationsCompanion.insert({
    required String id,
    required String verseRef,
    required String kind,
    this.color = const Value.absent(),
    this.noteId = const Value.absent(),
    this.inlineText = const Value.absent(),
    required DateTime updatedAt,
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        verseRef = Value(verseRef),
        kind = Value(kind),
        updatedAt = Value(updatedAt);
  static Insertable<BibleAnnotationsData> custom({
    Expression<String>? id,
    Expression<String>? verseRef,
    Expression<String>? kind,
    Expression<String>? color,
    Expression<String>? noteId,
    Expression<String>? inlineText,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (verseRef != null) 'verse_ref': verseRef,
      if (kind != null) 'kind': kind,
      if (color != null) 'color': color,
      if (noteId != null) 'note_id': noteId,
      if (inlineText != null) 'inline_text': inlineText,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BibleAnnotationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? verseRef,
      Value<String>? kind,
      Value<String?>? color,
      Value<String?>? noteId,
      Value<String?>? inlineText,
      Value<DateTime>? updatedAt,
      Value<bool>? isDeleted,
      Value<int>? rowid}) {
    return BibleAnnotationsCompanion(
      id: id ?? this.id,
      verseRef: verseRef ?? this.verseRef,
      kind: kind ?? this.kind,
      color: color ?? this.color,
      noteId: noteId ?? this.noteId,
      inlineText: inlineText ?? this.inlineText,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (verseRef.present) {
      map['verse_ref'] = Variable<String>(verseRef.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (inlineText.present) {
      map['inline_text'] = Variable<String>(inlineText.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BibleAnnotationsCompanion(')
          ..write('id: $id, ')
          ..write('verseRef: $verseRef, ')
          ..write('kind: $kind, ')
          ..write('color: $color, ')
          ..write('noteId: $noteId, ')
          ..write('inlineText: $inlineText, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DatabaseAtV2 extends GeneratedDatabase {
  DatabaseAtV2(QueryExecutor e) : super(e);
  late final Folders folders = Folders(this);
  late final Notes notes = Notes(this);
  late final Tags tags = Tags(this);
  late final NoteTags noteTags = NoteTags(this);
  late final NoteLinks noteLinks = NoteLinks(this);
  late final Attachments attachments = Attachments(this);
  late final BibleAnnotations bibleAnnotations = BibleAnnotations(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        folders,
        notes,
        tags,
        noteTags,
        noteLinks,
        attachments,
        bibleAnnotations
      ];
  @override
  int get schemaVersion => 2;
}
