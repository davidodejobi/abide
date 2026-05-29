import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';

/// A hand-drawn, wobbly oval button. The outline draws itself with a pen
/// stroke, then the label fades in. Ink follows the theme (mono in light/dark).
class HandDrawnButton extends StatefulWidget {
  const HandDrawnButton({
    super.key,
    required this.label,
    required this.onTap,
    this.size = const Size(170, 74),
    this.duration = const Duration(milliseconds: 700),
    this.startDelay = Duration.zero,
    this.color,
    this.autoStart = true,
  });

  final String label;
  final VoidCallback onTap;
  final Size size;
  final Duration duration;
  final Duration startDelay;
  final Color? color;
  final bool autoStart;

  @override
  State<HandDrawnButton> createState() => _HandDrawnButtonState();
}

class _HandDrawnButtonState extends State<HandDrawnButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.autoStart) _start();
  }

  Future<void> _start() async {
    if (widget.startDelay > Duration.zero) {
      await Future.delayed(widget.startDelay);
    }
    if (mounted) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.color ?? Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final outline = Curves.easeOut.transform(_controller.value);
            // Label fades in over the last 35% of the draw.
            final labelOpacity =
                ((_controller.value - 0.65) / 0.35).clamp(0.0, 1.0);
            return SizedBox(
              width: widget.size.width,
              height: widget.size.height,
              child: CustomPaint(
                painter: _OvalPainter(progress: outline, color: ink),
                child: Center(
                  child: Opacity(
                    opacity: labelOpacity,
                    child: Text(
                      widget.label,
                      style: AppTextStyles.doodleButton(color: ink),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OvalPainter extends CustomPainter {
  _OvalPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final path = _buildOval(size);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      paint,
    );
  }

  /// A wobbly ellipse with a slight overshoot tail at the top-left, so it reads
  /// like a quick hand-drawn loop rather than a perfect oval.
  Path _buildOval(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rx = size.width / 2 - 6;
    final ry = size.height / 2 - 6;

    final path = Path();
    const segments = 48;
    // Start slightly past the top so the loop closes with a little overshoot.
    const startAngle = -math.pi / 2 - 0.35;
    const sweep = 2 * math.pi + 0.5; // overshoot past the start point

    for (var i = 0; i <= segments; i++) {
      final t = i / segments;
      final angle = startAngle + sweep * t;
      final jitter = math.sin(t * 26) * 0.8 + math.cos(t * 13) * 0.6;
      final x = cx + math.cos(angle) * (rx + jitter);
      final y = cy + math.sin(angle) * (ry + jitter);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _OvalPainter old) =>
      old.progress != progress || old.color != color;
}
