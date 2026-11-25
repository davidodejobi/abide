import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

/// The streak lamp. The one place the lamp appears; it is lit by the day count,
/// never used as decoration.
class LampIcon extends StatelessWidget {
  const LampIcon({super.key, this.size = 24, this.lit = true});

  final double size;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _LampPainter(
          body: c.lampBody,
          flame: lit ? c.lampFlame : c.lampUnlit,
          core: lit ? c.lampFlameCore : c.lampUnlit,
        ),
      ),
    );
  }
}

class _LampPainter extends CustomPainter {
  _LampPainter({required this.body, required this.flame, required this.core});

  final Color body, flame, core;

  @override
  void paint(Canvas canvas, Size s) {
    final u = s.width / 24;
    // Oil bowl.
    final bowl = Path()
      ..moveTo(3 * u, 15 * u)
      ..quadraticBezierTo(4 * u, 21 * u, 12 * u, 21 * u)
      ..quadraticBezierTo(17 * u, 21 * u, 19 * u, 17 * u)
      ..lineTo(23 * u, 14 * u)
      ..lineTo(18 * u, 14 * u)
      ..quadraticBezierTo(17 * u, 15 * u, 15 * u, 15 * u)
      ..close();
    canvas.drawPath(bowl, Paint()..color = body);
    // Flame.
    final f = Path()
      ..moveTo(5 * u, 13 * u)
      ..cubicTo(1 * u, 9 * u, 4 * u, 4 * u, 5 * u, 2 * u)
      ..cubicTo(8 * u, 5 * u, 9 * u, 10 * u, 5 * u, 13 * u)
      ..close();
    canvas.drawPath(f, Paint()..color = flame);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(5 * u, 10 * u), width: 2.4 * u, height: 4 * u),
      Paint()..color = core,
    );
  }

  @override
  bool shouldRepaint(_LampPainter o) =>
      o.body != body || o.flame != flame || o.core != core;
}
