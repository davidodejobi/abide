import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/storage/database/fts_query.dart';

// Pure builder that turns a user's raw search box input into a safe FTS5 MATCH
// expression: each token is quoted (so punctuation can't inject operators) and
// given a trailing `*` for prefix matching, joined by implicit AND.
void main() {
  test('single token becomes a quoted prefix match', () {
    expect(buildFtsMatchQuery('grace'), '"grace"*');
  });

  test('multiple tokens are AND-joined quoted prefixes', () {
    expect(buildFtsMatchQuery('amazing grace'), '"amazing"* "grace"*');
  });

  test('surrounding and repeated whitespace is collapsed', () {
    expect(buildFtsMatchQuery('   amazing    grace  '), '"amazing"* "grace"*');
  });

  test('empty or whitespace-only input yields an empty expression', () {
    expect(buildFtsMatchQuery(''), '');
    expect(buildFtsMatchQuery('    '), '');
  });

  test('double quotes inside a token are escaped by doubling', () {
    expect(buildFtsMatchQuery('a"b'), '"a""b"*');
  });
}
