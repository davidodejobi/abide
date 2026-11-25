import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../theme/lum_tokens.dart';

/// The cold-start intro, picking up from the native splash. Its first frame is
/// the native splash exactly: the sun, 160 dp across the ray tips, centred on
/// `bg/page` for the phone's mode (the native mark is a 240 dp canvas with the
/// same sun, see abide-design-work/lumway/icon/make_icon.py, whose geometry the
/// constants below repeat). Then:
///
/// - 0-520 ms: the gold rays turn a few degrees and the core brightens with a
///   soft glow pulse.
/// - 520-800 ms: the mark swells slightly and fades over the page colour (one
///   light haptic as it starts to go).
/// - 800-1200 ms: a circle opens from the core and grows to reveal the app.
///
/// Reduce motion: a 200 ms fade. Plays once per cold launch, over whatever the
/// app shows first (onboarding or Today), and never waits on loading. Without
/// [preload] (tests), it shows the app straight away. No sound.
class SplashIntro extends StatefulWidget {
  const SplashIntro({super.key, required this.child});

  final Widget child;

  static _Art? _art;

  /// Builds the mark's paths before runApp, while the native splash is still
  /// up, so the first frame can draw at once. Not calling it skips the intro.
  static Future<void> preload() async => _art = _Art();

  @visibleForTesting
  static void debugReset() => _art = null;

  @override
  State<SplashIntro> createState() => _SplashIntroState();
}

const _total = Duration(milliseconds: 1200);
const _reduced = Duration(milliseconds: 200);
const _openAtMs = 520.0;

class _SplashIntroState extends State<SplashIntro>
    with SingleTickerProviderStateMixin {
  // Made in initState, not lazily: a skipped intro would otherwise build its
  // ticker in dispose().
  late final AnimationController _c;
  late bool _done = SplashIntro._art == null;
  bool _buzzed = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _total);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_done || _c.isAnimating || _c.isCompleted) return;
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) _c.duration = _reduced;
    _c
      ..addListener(() {
        if (_buzzed || reduce) return;
        if (_c.value * _total.inMilliseconds >= _openAtMs) {
          _buzzed = true;
          HapticFeedback.lightImpact();
        }
      })
      ..forward().whenComplete(() {
        if (mounted) setState(() => _done = true);
      });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The native splash follows the phone's mode, not the in-app theme.
    final page = (MediaQuery.platformBrightnessOf(context) == Brightness.dark
            ? LumColors.dark
            : LumColors.light)
        .bgPage;
    final reduce = MediaQuery.disableAnimationsOf(context);
    // One tree for the whole life of the widget: the child must never be
    // remounted when the intro ends (it holds the router and update gate).
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          excluding: !_done,
          child: ExcludeFocus(excluding: !_done, child: widget.child),
        ),
        if (!_done)
          ExcludeSemantics(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Opacity(
                opacity: reduce ? 1 - _c.value : 1,
                child: CustomPaint(
                  painter: _IntroPainter(
                    art: SplashIntro._art!,
                    ms: reduce ? 0 : _c.value * _total.inMilliseconds,
                    page: page,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Brand art. Geometry is in the icon's unit space, centred on the sun, ray
// tips at r=470 (make_icon.py).
const _gold = Color(0xFFE8B13A);
const _dash = Color(0xFFF0C25A);
const _bronze = Color(0xFFB8862F);
const _core = Color(0xFFFFF4CF);
const _tip = 470.0;
const _coreR = 153.0;

/// Native mark: tips 80 dp from the centre.
const _unit = 80 / _tip;

Path _sector(double r1, double r2, double a1, double a2) {
  double rad(double d) => d * math.pi / 180;
  Offset p(double r, double a) =>
      Offset(r * math.cos(rad(a)), r * math.sin(rad(a)));
  return Path()
    ..moveTo(p(r2, a1).dx, p(r2, a1).dy)
    ..arcTo(Rect.fromCircle(center: Offset.zero, radius: r2), rad(a1),
        rad(a2 - a1), false)
    ..lineTo(p(r1, a2).dx, p(r1, a2).dy)
    ..arcTo(Rect.fromCircle(center: Offset.zero, radius: r1), rad(a2),
        rad(a1 - a2), false)
    ..close();
}

Path _turned(Path p, double deg) =>
    p.transform(Matrix4.rotationZ(deg * math.pi / 180).storage);

class _Art {
  _Art() {
    final tz = Path()
      ..moveTo(262, -58)
      ..lineTo(400, -89)
      ..lineTo(400, 89)
      ..lineTo(262, 58)
      ..close();
    final ray = Path()
      ..moveTo(_tip, 0)
      ..lineTo(250, -68.6)
      ..lineTo(250, 68.6)
      ..close();
    for (var k = 0; k < 6; k++) {
      trapezoids.addPath(_turned(tz, 60.0 * k), Offset.zero);
      rays.addPath(_turned(ray, 90 + 60.0 * k), Offset.zero);
      darkBand.addPath(
          _sector(_coreR, 210, 75 + 60.0 * k, 105 + 60.0 * k), Offset.zero);
      lightBand.addPath(
          _sector(_coreR, 210, -15 + 60.0 * k, 15 + 60.0 * k), Offset.zero);
    }
    for (var k = 0; k < 8; k++) {
      dashes.addPath(
          _sector(227, 277, 45.0 * k - 13, 45.0 * k + 13), Offset.zero);
    }
    ring = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: 302))
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: 210));
  }

  final trapezoids = Path();
  final rays = Path();
  final darkBand = Path();
  final lightBand = Path();
  final dashes = Path();
  late final Path ring;
}

double _span(double ms, double from, double to) =>
    ((ms - from) / (to - from)).clamp(0.0, 1.0);

class _IntroPainter extends CustomPainter {
  _IntroPainter({
    required this.art,
    required this.ms,
    required this.page,
  });

  final _Art art;
  final double ms;
  final Color page;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);

    // Phase 1: the gold rays turn, the core brightens, a soft glow pulses.
    final turn = Curves.easeInOut.transform(_span(ms, 0, _openAtMs));
    final pulse = math.sin(math.pi * _span(ms, 0, _openAtMs));
    // Phase 2: the circle opens from the core; the mark swells and fades.
    final open = Curves.easeInCubic
        .transform(_span(ms, 800, _total.inMilliseconds.toDouble()));
    final swell =
        1 + 0.12 * Curves.easeOut.transform(_span(ms, _openAtMs, 800));
    final fade = 1 - Curves.easeIn.transform(_span(ms, _openAtMs, 800));

    // The page, with a hole growing from the core to the far corner.
    final far =
        math.sqrt(size.width * size.width + size.height * size.height) / 2 + 1;
    final hole = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: centre, radius: far * open));
    canvas.drawPath(hole, Paint()..color = page);
    if (fade <= 0) return;
    // The mark fades over a page-coloured disc, so the app showing through
    // the hole never darkens it. The hole opens once the mark has gone.
    canvas.drawCircle(centre, 450 * _unit * swell, Paint()..color = page);

    canvas
      ..saveLayer(
          Offset.zero & size, Paint()..color = Color.fromRGBO(0, 0, 0, fade))
      ..translate(centre.dx, centre.dy)
      ..scale(_unit * swell);

    // Glow.
    canvas.drawCircle(
      Offset.zero,
      440,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _gold.withValues(alpha: .45),
            _gold.withValues(alpha: .34),
            _gold.withValues(alpha: 0),
          ],
          stops: const [0, .68, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: 440)),
    );
    canvas.drawPath(
      art.trapezoids,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x7AF2D37D), Color(0x5CF2D37D)],
        ).createShader(const Rect.fromLTRB(290, 0, 400, 1)),
    );
    canvas
      ..save()
      ..rotate(10 * turn * math.pi / 180)
      ..drawPath(art.rays, Paint()..color = _gold)
      ..restore();
    canvas
      ..drawPath(art.ring, Paint()..color = _bronze)
      ..drawPath(art.dashes, Paint()..color = _dash);
    final band = Rect.fromCircle(center: Offset.zero, radius: 210);
    Paint bandPaint(Color a, Color b) => Paint()
      ..shader = RadialGradient(colors: [a, b], stops: const [.73, 1])
          .createShader(band);
    canvas
      ..drawPath(art.darkBand,
          bandPaint(const Color(0xFFA68F50), const Color(0xFF856A30)))
      ..drawPath(art.lightBand,
          bandPaint(const Color(0xFFCBB275), const Color(0xFFB39C5D)));

    // Core: brightens and glows.
    if (pulse > 0) {
      canvas.drawCircle(
        Offset.zero,
        _coreR + 40 * pulse,
        Paint()
          ..color = _core.withValues(alpha: .55 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36),
      );
    }
    canvas
      ..drawCircle(Offset.zero, _coreR,
          Paint()..color = Color.lerp(_core, Colors.white, .7 * pulse)!)
      ..restore();
  }

  @override
  bool shouldRepaint(_IntroPainter old) => old.ms != ms || old.page != page;
}
