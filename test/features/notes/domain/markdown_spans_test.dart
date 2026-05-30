import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/notes/domain/markdown_spans.dart';

void main() {
  group('computeMarkdownRuns', () {
    test('empty text yields no runs', () {
      expect(computeMarkdownRuns(''), isEmpty);
    });

    test('plain text is a single plain run', () {
      final runs = computeMarkdownRuns('hello world');
      expect(runs, hasLength(1));
      expect(runs.single.type, MarkdownRunType.plain);
      expect(runs.single.start, 0);
      expect(runs.single.end, 11);
    });

    test('runs are contiguous and cover the whole string', () {
      const text = 'a **b** c [[d]] e';
      final runs = computeMarkdownRuns(text);
      expect(runs.first.start, 0);
      expect(runs.last.end, text.length);
      for (var i = 1; i < runs.length; i++) {
        expect(runs[i].start, runs[i - 1].end);
      }
    });

    test('detects a bold run', () {
      final runs = computeMarkdownRuns('say **hi** ok');
      final bold = runs.firstWhere((r) => r.type == MarkdownRunType.bold);
      expect('say **hi** ok'.substring(bold.start, bold.end), '**hi**');
    });

    test('detects an italic run but not bold markers', () {
      final runs = computeMarkdownRuns('a *one* b');
      final italics = runs.where((r) => r.type == MarkdownRunType.italic);
      expect(italics, hasLength(1));
      expect('a *one* b'.substring(italics.first.start, italics.first.end),
          '*one*');
    });

    test('bold wins over italic for ** markers', () {
      final runs = computeMarkdownRuns('**strong**');
      expect(runs.where((r) => r.type == MarkdownRunType.bold), hasLength(1));
      expect(runs.where((r) => r.type == MarkdownRunType.italic), isEmpty);
    });

    test('detects a link run and captures inner token', () {
      final runs = computeMarkdownRuns('go [[hymn:hymn_0001]] now');
      final link = runs.firstWhere((r) => r.type == MarkdownRunType.link);
      expect(link.linkInner, 'hymn:hymn_0001');
    });

    test('detects a heading line', () {
      final runs = computeMarkdownRuns('# Title\nbody');
      final heading = runs.firstWhere((r) => r.type == MarkdownRunType.heading);
      expect('# Title\nbody'.substring(heading.start, heading.end), '# Title');
    });

    test('mixes multiple styles in order', () {
      final runs = computeMarkdownRuns('**b** then [[Note]] and *i*');
      expect(
        runs.map((r) => r.type).where((t) => t != MarkdownRunType.plain),
        [MarkdownRunType.bold, MarkdownRunType.link, MarkdownRunType.italic],
      );
    });
  });
}
