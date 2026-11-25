import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/widgets/splash_intro.dart';

Widget _app({bool reduceMotion = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: SplashIntro(child: Text('app')),
      ),
    );

void main() {
  tearDown(SplashIntro.debugReset);

  testWidgets('without preload the app shows straight away', (tester) async {
    await tester.pumpWidget(_app());
    expect(find.byType(CustomPaint), findsNothing);
    expect(find.text('app'), findsOneWidget);
  });

  testWidgets('plays over the app, then leaves it alone', (tester) async {
    await SplashIntro.preload();
    await tester.pumpWidget(_app());
    expect(find.byType(CustomPaint), findsWidgets);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(CustomPaint), findsWidgets);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(CustomPaint), findsNothing);
    expect(find.text('app'), findsOneWidget);
  });

  testWidgets(
      'child is mounted once and hidden from semantics only during '
      'the intro', (tester) async {
    final handle = tester.ensureSemantics();
    _inits = 0;
    await SplashIntro.preload();
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SplashIntro(child: _Probe()),
        ),
      ),
    );
    expect(_inits, 1);
    expect(find.bySemanticsLabel('probe'), findsNothing);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(CustomPaint), findsNothing);
    expect(_inits, 1);
    expect(find.bySemanticsLabel('probe'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('reduce motion fades out in 200 ms', (tester) async {
    await SplashIntro.preload();
    await tester.pumpWidget(_app(reduceMotion: true));
    await tester.pump(const Duration(milliseconds: 100));
    final opacity = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacity.opacity, closeTo(.5, .05));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byType(Opacity), findsNothing);
    expect(find.text('app'), findsOneWidget);
  });
}

int _inits = 0;

class _Probe extends StatefulWidget {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    _inits++;
  }

  @override
  Widget build(BuildContext context) =>
      Semantics(label: 'probe', child: const SizedBox());
}
