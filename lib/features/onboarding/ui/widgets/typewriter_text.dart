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
  });

  final String text;
  final TextStyle style;
  final Duration perCharacter;
  final Duration startDelay;
  final bool showCursorWhileTyping;
  final bool keepCursorWhenDone;
  final TextAlign textAlign;
  final VoidCallback? onComplete;

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
    if (mounted) _typeController.forward();
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

  bool get _cursorVisible {
    if (_done) return widget.keepCursorWhenDone;
    return widget.showCursorWhileTyping;
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.text.substring(0, _charCount.value);
    final cursorColor = widget.style.color ?? Theme.of(context).colorScheme.onSurface;

    return AnimatedBuilder(
      animation: _cursorController,
      builder: (context, _) {
        final showCursor =
            _cursorVisible && _cursorController.value < 0.5;
        return Text.rich(
          TextSpan(
            text: visible,
            style: widget.style,
            children: [
              TextSpan(
                text: '|',
                style: widget.style.copyWith(
                  color: showCursor ? cursorColor : Colors.transparent,
                ),
              ),
            ],
          ),
          textAlign: widget.textAlign,
        );
      },
    );
  }
}
