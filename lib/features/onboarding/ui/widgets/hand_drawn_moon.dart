import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A hand-drawn crescent moon with a few sparkle stars that draws itself with a
/// pen-stroke effect. Ink color follows the active theme so it stays monochrome
/// in both light and dark mode. Used for the evening/night onboarding scene.
class HandDrawnMoon extends StatefulWidget {
  const HandDrawnMoon({
    super.key,
    this.size = const Size(220, 150),
    this.duration = const Duration(milliseconds: 1600),
    this.startDelay = Duration.zero,
    this.color,
    this.strokeWidth = 1.5,
  });

  final Size size;
  final Duration duration;
  final Duration startDelay;
  final Color? color;
  final double strokeWidth;

  @override
  State<HandDrawnMoon> createState() => _HandDrawnMoonState();
}

class _HandDrawnMoonState extends State<HandDrawnMoon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _start();
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: widget.size,
        painter: _MoonPainter(
          progress: Curves.easeInOut.transform(_controller.value),
          color: ink,
          strokeWidth: widget.strokeWidth,
        ),
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  _MoonPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final path = _buildPath(size);
    final metrics = path.computeMetrics().toList();
    final totalLength = metrics.fold<double>(0, (sum, m) => sum + m.length);
    final drawLength = totalLength * progress;

    final partial = Path();
    double consumed = 0;
    for (final metric in metrics) {
      if (consumed >= drawLength) break;
      final remaining = drawLength - consumed;
      final take = math.min(metric.length, remaining);
      partial.addPath(metric.extractPath(0, take), Offset.zero);
      consumed += metric.length;
    }
    canvas.drawPath(partial, paint);
  }

  /// Builds the crescent (outer arc + concave inner edge) followed by a few
  /// sparkle stars, so the pen-stroke reveal draws the moon then the stars.
  Path _buildPath(Size size) {
    final path = Path();
    final cx = size.width * 0.5;
    final cy = size.height * 0.46;
    final r = size.width * 0.17;

    const deg = math.pi / 180;
    final topTip =
        Offset(cx + r * math.cos(-50 * deg), cy + r * math.sin(-50 * deg));

    // Outer arc — the long way round through the left side, with light jitter.
    // It begins at the top tip and ends at the bottom tip (angle 50°).
    path.moveTo(topTip.dx, topTip.dy);
    const oSeg = 30;
    const startA = -50 * deg;
    const endA = -310 * deg; // sweep counter-clockwise through 180 (left)
    for (var i = 1; i <= oSeg; i++) {
      final t = i / oSeg;
      final a = startA + (endA - startA) * t;
      final jitter = math.sin(t * 26) * 0.6;
      path.lineTo(cx + math.cos(a) * (r + jitter), cy + math.sin(a) * (r + jitter));
    }

    // Inner edge — a curve back to the top tip, bowing right to carve a crescent.
    final control = Offset(cx + r * 0.30, cy);
    path.quadraticBezierTo(control.dx, control.dy, topTip.dx, topTip.dy);

    // Sparkle stars — each a small "+" of two crossing strokes.
    final stars = <_Star>[
      _Star(Offset(size.width * 0.74, size.height * 0.22), 7),
      _Star(Offset(size.width * 0.82, size.height * 0.52), 5),
      _Star(Offset(size.width * 0.30, size.height * 0.18), 5),
    ];
    for (final star in stars) {
      path.moveTo(star.center.dx, star.center.dy - star.r);
      path.lineTo(star.center.dx, star.center.dy + star.r);
      path.moveTo(star.center.dx - star.r, star.center.dy);
      path.lineTo(star.center.dx + star.r, star.center.dy);
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant _MoonPainter old) =>
      old.progress != progress || old.color != color;
}

class _Star {
  const _Star(this.center, this.r);
  final Offset center;
  final double r;
}
