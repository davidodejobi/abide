import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/tablet/domain/scripture_reference.dart';

final manifest = BibleManifest.fromJson(
    jsonDecode(File('assets/bible/en-kjv/manifest.json').readAsStringSync())
        as Map<String, dynamic>);

List<String> keys(String t) =>
    findSpokenScriptureReferences(t, manifest).map((r) => r.targetKey).toList();

void main() {
  test('chapter and verse spoken as words around digits', () {
    expect(keys('Turn to John chapter 15 verse 5 today'), ['JHN.15.5']);
    expect(keys('Turn to John 15 verse 5 today'), ['JHN.15.5']);
  });

  test('number words', () {
    expect(keys('John chapter fifteen verse five'), ['JHN.15.5']);
    expect(keys('Mark chapter four verse thirty-five'), ['MRK.4.35']);
    expect(keys('Psalm one hundred nineteen verse one hundred and five'),
        ['PSA.119.105']);
    expect(keys('Psalm one hundred and nineteen verse one hundred and seventy six'),
        ['PSA.119.176']);
  });

  test('verses 5 to 7', () {
    expect(keys('John 15 verses 5 to 7.'), ['JHN.15.5-7']);
    expect(keys('John chapter fifteen verses five to seven'), ['JHN.15.5-7']);
  });

  test('first and second Corinthians', () {
    expect(keys('first Corinthians chapter 13 verse 4'), ['1CO.13.4']);
    expect(keys('Second Corinthians 5 17'), ['2CO.5.17']);
  });

  test('"Romans 8 28" is the verse, not the whole chapter', () {
    expect(keys('Romans 8 28 says it'), ['ROM.8.28']);
  });

  test('offsets point at the spoken words; plain forms still work', () {
    const t = 'See John chapter fifteen verse five, then John 3:16.';
    final refs = findSpokenScriptureReferences(t, manifest);
    expect(refs.map((r) => r.text),
        ['John chapter fifteen verse five', 'John 3:16']);
    expect(refs.map((r) => r.targetKey), ['JHN.15.5', 'JHN.3.16']);
  });

  test('prose and out-of-range stay plain', () {
    expect(keys('Mark my words, one two three'), isEmpty);
    expect(keys('John chapter 15 verse 99'), isEmpty);
    expect(keys('Job well done, chapter five'), isEmpty);
  });
}
