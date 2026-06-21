import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/onboarding/ui/widgets/typewriter_text.dart';

// These cover the behavior layered on top of the typewriter for the
// onboarding flow: a one-shot "typing started" signal that drives the SFX
// loop, and a visible indicator that shows while typing and disappears when
// the line completes.
void main() {
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  testWidgets('onTypingStart fires exactly once after startDelay',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(host(TypewriterText(
      text: 'hello',
      style: const TextStyle(fontSize: 16),
      perCharacter: const Duration(milliseconds: 20),
      startDelay: const Duration(milliseconds: 50),
      onTypingStart: () => calls++,
    )));

    // Not yet — still waiting on startDelay.
    expect(calls, 0);
    await tester.pump(const Duration(milliseconds: 60));
    expect(calls, 1);

    // Pump well past the full type duration; still only one call.
    await tester.pump(const Duration(milliseconds: 500));
    expect(calls, 1);
  });

  testWidgets('renders the text on completion and fires onComplete',
      (tester) async {
    var done = false;
    await tester.pumpWidget(host(TypewriterText(
      text: 'abide',
      style: const TextStyle(fontSize: 16),
      perCharacter: const Duration(milliseconds: 10),
      onComplete: () => done = true,
    )));

    await tester.pump(const Duration(milliseconds: 250));
    expect(find.textContaining('abide'), findsOneWidget);
    expect(done, isTrue);
  });

  testWidgets('three ink dots appear while typing and vanish on completion',
      (tester) async {
    await tester.pumpWidget(host(TypewriterText(
      text: 'kaabo',
      style: const TextStyle(fontSize: 16),
      perCharacter: const Duration(milliseconds: 30),
    )));

    // Mid-stream: dots are mounted as three Container circles inside a Row.
    await tester.pump(const Duration(milliseconds: 30));
    final midDots = _countCircleContainers(tester);
    expect(midDots, 3);

    // After completion the dots are gone (no steady cursor configured).
    await tester.pump(const Duration(milliseconds: 400));
    final endDots = _countCircleContainers(tester);
    expect(endDots, 0);
  });

  testWidgets('keepCursorWhenDone keeps a blinking | after typing finishes',
      (tester) async {
    await tester.pumpWidget(host(TypewriterText(
      text: 'amen',
      style: const TextStyle(fontSize: 16),
      perCharacter: const Duration(milliseconds: 10),
      keepCursorWhenDone: true,
    )));

    // Past the typing window.
    await tester.pump(const Duration(milliseconds: 200));
    // The cursor renders as a literal '|' character in a Text widget.
    expect(find.text('|'), findsOneWidget);
  });
}

int _countCircleContainers(WidgetTester tester) {
  var count = 0;
  for (final element in find.byType(Container).evaluate()) {
    final container = element.widget as Container;
    final decoration = container.decoration;
    if (decoration is BoxDecoration && decoration.shape == BoxShape.circle) {
      count++;
    }
  }
  return count;
}
