import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/app_theme.dart';
import 'package:openbaptisthymnal/features/daily/domain/road_landmarks.dart';
import 'package:openbaptisthymnal/features/daily/providers/landmark_download_provider.dart';
import 'package:openbaptisthymnal/features/daily/ui/road_ahead_page.dart';
import 'package:openbaptisthymnal/features/daily/ui/road_ahead_strings.dart';
import 'package:openbaptisthymnal/features/daily/ui/widgets/road_parade.dart';

import '../../../support/pump_app.dart';

const _models = '''{"landmarks":{
 "altar":{"title":"Stone altar","bytes":2000000,"sha256":"aa","bundled":false},
 "ark":{"title":"Ark","bytes":2800000,"sha256":"bb","bundled":false},
 "well":{"title":"Well","bytes":1,"sha256":"cc","bundled":true}}}''';
const _days = '''{"plan":"p","days":[
 {"day":1,"landmark":"altar","story":"s1","ref":"r","spans":[["GEN",1,1]],"title":"The first altar"},
 {"day":2,"landmark":"ark","story":"s2","ref":"r","spans":[["GEN",6,6]],"title":"Noah's ark"},
 {"day":3,"landmark":"well","story":"s3","ref":"r","spans":[["GEN",24,24]],"title":"A well"}]}''';

class _Fake extends LandmarkDownloadNotifier {
  _Fake(this.initial);
  final LandmarkDownloadState initial;
  static final calls = <String>[];
  @override
  LandmarkDownloadState build() => initial;
  @override
  Future<void> refresh() async {}
  @override
  Future<void> start() async => calls.add('start');
  @override
  Future<void> remove() async => calls.add('remove');
}

void main() {
  setUp(_Fake.calls.clear);

  Future<void> pump(WidgetTester t, LandmarkDownloadState s,
      {bool reduce = false}) async {
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final cat = parseLandmarkCatalog(_models, _days);
    await t.pumpWidget(ProviderScope(
      overrides: [
        landmarkCatalogProvider.overrideWith((_) async => cat),
        remoteLandmarkModelsProvider.overrideWith((_) async =>
            [for (final m in cat.models.values) if (!m.bundled) m]),
        landmarkDownloadProvider.overrideWith(() => _Fake(s)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (c, w) => MediaQuery(
            data: MediaQuery.of(c).copyWith(disableAnimations: reduce),
            child: w!),
        home: const RoadAheadPage(),
      ),
    ));
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 100));
  }

  testWidgets('not downloaded: copy, real counts and Download all',
      (t) async {
    await pump(t, const LandmarkDownloadState());
    expect(find.text(RoadAheadStrings.title), findsOneWidget);
    expect(find.text(RoadAheadStrings.toDownload(2)), findsOneWidget);
    expect(find.text(RoadAheadStrings.included(1)), findsOneWidget);
    expect(find.text('4.8 MB'), findsOneWidget);
    expect(find.text(RoadAheadStrings.wifi), findsOneWidget);
    expect(find.text(RoadAheadStrings.caption('The first altar', 1)),
        findsOneWidget);
    await t.tap(find.text(RoadAheadStrings.download));
    expect(_Fake.calls, ['start']);
    await t.flushTimers();
  });

  testWidgets('downloading: progress and counts, no button', (t) async {
    await pump(
        t,
        const LandmarkDownloadState(
            status: LandmarkDownloadStatus.downloading,
            doneFiles: 1,
            totalFiles: 2,
            doneBytes: 2000000,
            totalBytes: 4800000,
            doneArts: {'altar'}));
    expect(find.text(RoadAheadStrings.progress(1, 2)), findsOneWidget);
    expect(find.text(RoadAheadStrings.megabytes('2.0 MB', '4.8 MB')),
        findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text(RoadAheadStrings.download), findsNothing);
    await t.flushTimers();
  });

  testWidgets('done: All set and Remove downloads with the size', (t) async {
    await pump(
        t,
        const LandmarkDownloadState(
            status: LandmarkDownloadStatus.done,
            doneFiles: 2,
            totalFiles: 2,
            doneBytes: 4800000,
            totalBytes: 4800000));
    expect(find.text(RoadAheadStrings.doneTitle), findsOneWidget);
    expect(find.text(RoadAheadStrings.allSet), findsOneWidget);
    await t.tap(find.text(RoadAheadStrings.remove('4.8 MB')));
    expect(_Fake.calls, ['remove']);
    await t.flushTimers();
  });

  testWidgets('failed: message and Try again', (t) async {
    await pump(t, const LandmarkDownloadState(
        status: LandmarkDownloadStatus.failed, totalFiles: 2));
    expect(find.text(RoadAheadStrings.failed), findsOneWidget);
    await t.tap(find.text(RoadAheadStrings.retry));
    expect(_Fake.calls, ['start']);
    await t.flushTimers();
  });

  testWidgets('reduce motion: a still grid, no moving parade', (t) async {
    await pump(t, const LandmarkDownloadState(), reduce: true);
    expect(find.byType(Image), findsNWidgets(3));
    expect(find.text(RoadAheadStrings.caption('The first altar', 1)),
        findsNothing);
    expect(
        find.descendant(
            of: find.byType(RoadParade), matching: find.byType(CustomPaint)),
        findsNothing);
    expect(t.binding.transientCallbackCount, 0);
    await t.flushTimers();
  });

  test('the parade lists each landmark once, in reading order', () {
    final items = paradeItems(parseLandmarkCatalog(_models, _days));
    expect(items.map((i) => i.art), ['altar', 'ark', 'well']);
    expect(items[1].day, 2);
  });
}
