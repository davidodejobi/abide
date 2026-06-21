import 'package:flutter/material.dart';

/// Reveals [text] one character at a time, like a typewriter, with an optional
/// blinking cursor. Calls [onComplete] once the full text has been typed.
///
/// Screens chain several of these via [onComplete] to type lines in sequence.
class TypewriterText extends StatefulWidget {
  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.perCharacter = const Duration(milliseconds: 45),
    this.startDelay = Duration.zero,
    this.showCursorWhileTyping = true,
    this.keepCursorWhenDone = false,
    this.textAlign = TextAlign.start,
    this.onComplete,
    this.onTypingStart,
  });

  final String text;
  final TextStyle style;
  final Duration perCharacter;
  final Duration startDelay;
  final bool showCursorWhileTyping;
  final bool keepCursorWhenDone;
  final TextAlign textAlign;
  final VoidCallback? onComplete;

  /// Fires once when typing begins (after [startDelay]). Use to start a
  /// looping typewriter SFX; pair with [onComplete] to stop it.
  final VoidCallback? onTypingStart;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with TickerProviderStateMixin {
  late final AnimationController _typeController;
  late final Animation<int> _charCount;
  late final AnimationController _cursorController;
  bool _done = false;

  @override
  void initState() {
    super.initState();

    _typeController = AnimationController(
      vsync: this,
      duration: widget.perCharacter * widget.text.length,
    );
    _charCount = StepTween(begin: 0, end: widget.text.length)
        .animate(_typeController)
      ..addListener(_onTick);

    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _typeController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_done) {
        _done = true;
        widget.onComplete?.call();
        if (mounted) setState(() {});
      }
    });

    _start();
  }

  Future<void> _start() async {
    if (widget.startDelay > Duration.zero) {
      await Future.delayed(widget.startDelay);
    }
    if (!mounted) return;
    widget.onTypingStart?.call();
    _typeController.forward();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _charCount.removeListener(_onTick);
    _typeController.dispose();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.text.substring(0, _charCount.value);
    final inkColor =
        widget.style.color ?? Theme.of(context).colorScheme.onSurface;

    return AnimatedBuilder(
      animation: _cursorController,
      builder: (context, _) {
        final indicator = _buildTrailingIndicator(inkColor);
        return Text.rich(
          TextSpan(
            text: visible,
            style: widget.style,
            children: [
              if (indicator != null)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: indicator,
                ),
            ],
          ),
          textAlign: widget.textAlign,
        );
      },
    );
  }

  /// While typing — three small bouncing dots in the current ink color.
  /// When done — optional steady `|` cursor if [keepCursorWhenDone].
  Widget? _buildTrailingIndicator(Color inkColor) {
    if (!_done && widget.showCursorWhileTyping) {
      return _TypingDots(
        animation: _cursorController,
        color: inkColor,
        fontSize: widget.style.fontSize ?? 16,
      );
    }
    if (_done && widget.keepCursorWhenDone) {
      final showCursor = _cursorController.value < 0.5;
      return Text(
        '|',
        style: widget.style.copyWith(
          color: showCursor ? inkColor : Colors.transparent,
        ),
      );
    }
    return null;
  }
}

/// Three small ink dots that pulse in sequence — the "is typing" indicator.
/// Driven by the same 1.1s cursor controller so it stays in sync with the
/// blink heartbeat already on screen.
class _TypingDots extends StatelessWidget {
  const _TypingDots({
    required this.animation,
    required this.color,
    required this.fontSize,
  });

  final Animation<double> animation;
  final Color color;
  final double fontSize;

  static const int _count = 3;
  static const double _stagger = 0.18; // phase offset per dot, in [0,1]

  @override
  Widget build(BuildContext context) {
    // Scale dot size + spacing to the host text size so it reads as part of
    // the line in both headline and body styles.
    final dotSize = (fontSize * 0.22).clamp(4.0, 9.0);
    final gap = dotSize * 0.55;
    final leading = fontSize * 0.30;

    final t = animation.value;
    final children = <Widget>[SizedBox(width: leading)];
    for (var i = 0; i < _count; i++) {
      // Per-dot phase in [0,1).
      final phase = (((t - i * _stagger) % 1.0) + 1.0) % 1.0;
      // Triangle wave 0->1->0 over the cycle, then ease.
      final tri = 1 - (phase - 0.5).abs() * 2;
      final eased = Curves.easeInOut.transform(tri.clamp(0.0, 1.0));
      final opacity = 0.25 + 0.75 * eased;
      final scale = 0.75 + 0.35 * eased;
      children.add(
        Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
      if (i != _count - 1) children.add(SizedBox(width: gap));
    }

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}
