import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/features/daily/domain/world_company.dart';
import 'package:openbaptisthymnal/features/daily/ui/widgets/world_company_line.dart';

class _Src implements WorldCompanySource {
  _Src(this.readers);
  final int? readers;
  @override
  Future<WorldCompany?> load(String planKey, int dayIndex) async =>
      readers == null ? null : WorldCompany(readersOnDay: readers);
}

class _NullCount implements WorldCompanySource {
  @override
  Future<WorldCompany?> load(String planKey, int dayIndex) async =>
      const WorldCompany();
}

Future<void> _pump(WidgetTester t, int? readers,
    {bool finished = false, bool reduce = false}) async {
  await t.pumpWidget(ProviderScope(
    overrides: [worldCompanySourceProvider.overrideWithValue(_Src(readers))],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(disableAnimations: reduce),
          child: child!),
      home: Scaffold(
          body: WorldCompanyLine(planKey: 'p', day: 12, finished: finished)),
    ),
  ));
  await t.pump();
  await t.pump(const Duration(seconds: 1));
}

void main() {
  test('release builds default to no data; fake only in debug or by flag', () {
    expect(pickWorldCompanySource(debug: false, fakeFlag: false),
        isA<NoWorldCompanySource>());
    expect(pickWorldCompanySource(debug: true, fakeFlag: false),
        isA<FakeWorldCompanySource>());
    expect(pickWorldCompanySource(debug: false, fakeFlag: true),
        isA<FakeWorldCompanySource>());
  });

  test('formats counts by locale', () {
    expect(formatCount(2481, const Locale('en')), '2,481');
    expect(formatCount(1204000, const Locale('en')), '1,204,000');
    expect(formatCount(2481, const Locale('de')), '2.481');
    expect(formatCount(2481, const Locale('fr')), '2 481');
    expect(formatCount(87, const Locale('en')), '87');
  });

  test('dots are capped, deterministic and absent for tiny counts', () {
    expect(companionSpots(3, 12), isEmpty);
    expect(companionSpots(10000000, 12).length, 12);
    expect(companionSpots(2481, 12), companionSpots(2481, 12));
    expect(companionSpots(2481, 12), isNot(companionSpots(2481, 13)));
  });

  testWidgets('hidden when the source returns null', (t) async {
    await _pump(t, null);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('shows the formatted count for the day', (t) async {
    await _pump(t, 2481);
    expect(find.text('2,481 people read Day 12 today'), findsOneWidget);
  });

  testWidgets('a held-back (null) count reads as a few', (t) async {
    await t.pumpWidget(ProviderScope(
      overrides: [
        worldCompanySourceProvider.overrideWithValue(_NullCount())
      ],
      child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: WorldCompanyLine(planKey: 'p', day: 12))),
    ));
    await t.pump();
    await t.pump();
    expect(find.text('A few people read Day 12 today'), findsOneWidget);
  });

  testWidgets('small counts read as a few', (t) async {
    await _pump(t, 3);
    expect(find.text('A few people read Day 12 today'), findsOneWidget);
  });

  testWidgets('finish moment names others, not you', (t) async {
    await _pump(t, 1205, finished: true);
    expect(find.text('You and 1,204 others finished Day 12'), findsOneWidget);
  });

  testWidgets('finish moment shows at once under reduced motion', (t) async {
    await _pump(t, 1205, finished: true, reduce: true);
    expect(find.text('You and 1,204 others finished Day 12'), findsOneWidget);
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
  });
}
