import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/app_database.dart';
import 'package:openbaptisthymnal/core/storage/database/daos/bible_annotations_dao.dart';

void main() {
  late AppDatabase db;
  late BibleAnnotationsDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = BibleAnnotationsDao(db);
  });

  tearDown(() => db.close());

  test('fresh database ships the bible_annotations table', () async {
    // Would throw "no such table" if the schema/createAll didn't include it.
    expect(await dao.watchAnnotationsForChapter('JHN', 3).first, isEmpty);
  });

  test('setHighlight stores an edition-independent verse highlight', () async {
    await dao.setHighlight('JHN.3.16', 'yellow');

    final anns = await dao.watchAnnotationsForChapter('JHN', 3).first;
    expect(anns, hasLength(1));
    expect(anns.single.verseRef, 'JHN.3.16'); // no edition prefix
    expect(anns.single.kind, 'highlight');
    expect(anns.single.color, 'yellow');
  });

  test('recoloring the same verse updates in place, not duplicates', () async {
    await dao.setHighlight('JHN.3.16', 'yellow');
    await dao.setHighlight('JHN.3.16', 'green');

    final anns = await dao.watchAnnotationsForChapter('JHN', 3).first;
    expect(anns, hasLength(1), reason: 'one highlight row per verse');
    expect(anns.single.color, 'green');
  });

  test('removeHighlight deletes the verse highlight', () async {
    await dao.setHighlight('JHN.3.16', 'blue');
    await dao.removeHighlight('JHN.3.16');

    expect(await dao.watchAnnotationsForChapter('JHN', 3).first, isEmpty);
  });

  test('watchAnnotationsForChapter scopes to the exact chapter', () async {
    await dao.setHighlight('JHN.3.16', 'yellow');
    await dao.setHighlight('JHN.30.1', 'green'); // no such chapter, but prefix-y
    await dao.setHighlight('JHN.4.1', 'blue');

    final ch3 = await dao.watchAnnotationsForChapter('JHN', 3).first;
    expect(ch3.map((a) => a.verseRef), ['JHN.3.16'],
        reason: 'JHN.30.1 must not leak into chapter 3');
  });
}
