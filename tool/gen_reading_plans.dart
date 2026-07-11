// Regenerates the reading plans in assets/plans/.
//
//   dart run tool/gen_reading_plans.dart
//
// The output is committed. This script is the *only* way it should change: the
// plans are deterministic, so a regeneration on unchanged inputs must produce a
// byte-identical file, and any diff is a real change worth reviewing.
//
// Plans are generated rather than transcribed from a published one on purpose.
// A schedule of chapter references is fact and carries no copyright, but copying
// somebody's particular schedule invites an argument we have no reason to have.
//
// The book/chapter/verse structure comes from the KJV manifest. Any edition
// would do -- all of them index the same 66 books and 1,189 chapters -- and the
// plans reference books by canonical USFM code, so one plan drives every
// translation in the app.

import 'dart:convert';
import 'dart:io';

import 'package:openbaptisthymnal/features/bible/domain/book_codes.dart';
import 'package:openbaptisthymnal/features/bible/model/bible_manifest.dart';
import 'package:openbaptisthymnal/features/daily/domain/plan_generator.dart';
import 'package:openbaptisthymnal/features/daily/domain/reading_plan.dart';

const _manifestPath = 'assets/bible/en-kjv/manifest.json';
const _outputDir = 'assets/plans';

void main() {
  final manifest = BibleManifest.fromJson(
    jsonDecode(File(_manifestPath).readAsStringSync()) as Map<String, dynamic>,
  );

  final specs = <_PlanSpec>[
    _PlanSpec(
      id: 'bible-in-a-year',
      title: 'The Bible in a Year',
      description:
          'Every book, cover to cover, in 365 days. About 85 verses a day.',
      days: 365,
      books: (b) => true,
    ),
    _PlanSpec(
      id: 'nt-90',
      title: 'The New Testament in 90 Days',
      description:
          'Matthew to Revelation in three months. A good first plan.',
      days: 90,
      books: (b) => !isOldTestament(b.ordinal),
    ),
    _PlanSpec(
      id: 'psalms-30',
      title: '30 Days in the Psalms',
      description: 'The whole psalter in a month, five psalms a day.',
      days: 30,
      books: (b) => b.code == 'PSA',
    ),
  ];

  Directory(_outputDir).createSync(recursive: true);

  for (final spec in specs) {
    final books = manifest.books.where(spec.books).toList(growable: false);
    final plan = ReadingPlan(
      id: spec.id,
      title: spec.title,
      description: spec.description,
      days: generateVerseBalancedDays(books: books, days: spec.days),
    );

    final file = File('$_outputDir/${spec.id}.json');
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(plan.toJson())}\n',
    );

    final chapters = books.fold<int>(
      0,
      (sum, b) => sum + b.chapterCount,
    );
    stdout.writeln(
      'wrote ${file.path}  '
      '(${plan.dayCount} days, ${books.length} books, $chapters chapters)',
    );
  }
}

class _PlanSpec {
  const _PlanSpec({
    required this.id,
    required this.title,
    required this.description,
    required this.days,
    required this.books,
  });

  final String id;
  final String title;
  final String description;
  final int days;
  final bool Function(BibleBookInfo) books;
}
