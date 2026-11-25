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
