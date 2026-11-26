import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

import '../../domain/road_landmarks.dart';
import '../../providers/landmark_download_provider.dart';
import '../road_ahead_strings.dart';

/// One stop of the parade: a landmark in the order the year meets it.
class ParadeItem {
  const ParadeItem(this.art, this.title, this.day, this.bundled);
  final String art, title;
  final int day;
  final bool bundled;
}

/// Each landmark of the catalog once, in reading order (first day it stands).
List<ParadeItem> paradeItems(LandmarkCatalog cat) {
  final seen = <String>{};
  final out = <ParadeItem>[];
  for (final d in cat.days) {
    for (final (art, title) in [(d.art, d.title), if (d.also != null) (d.also!, d.title)]) {
      final m = cat.models[art];
      if (m != null && seen.add(art)) out.add(ParadeItem(art, title, d.day, m.bundled));
    }
  }
  return out;
}

/// The parade wired to the download state, so the road-ahead page and the
/// onboarding step show the same thing.
class RoadAheadHero extends ConsumerWidget {
  const RoadAheadHero({super.key, this.height = 240});
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = ref.watch(landmarkCatalogProvider).valueOrNull;
    if (cat == null) return SizedBox(height: height);
    final s = ref.watch(landmarkDownloadProvider);
    final downloading = s.status == LandmarkDownloadStatus.downloading;
    return RoadParade(
      items: paradeItems(cat),
      litArts: s.doneArts,
      dimUnlit: downloading,
      celebrate: s.status == LandmarkDownloadStatus.done,
      height: height,
    );
  }
}

/// Landmark sprites travelling a gently curving road, a few at a time, with
/// the one in the middle named underneath. One controller drives a single
/// painter, so only the caption ever rebuilds. With reduced motion it is a
/// still grid instead.
///
/// Bundled models and those in [litArts] are in full colour; while [dimUnlit]
/// the rest are greyed, so a download visibly lights the road up.
class RoadParade extends StatefulWidget {
  const RoadParade({
    super.key,
    required this.items,
    this.litArts = const {},
    this.dimUnlit = false,
    this.celebrate = false,
    this.height = 240,
  });

  final List<ParadeItem> items;
  final Set<String> litArts;
  final bool dimUnlit, celebrate;
  final double height;

  @override
  State<RoadParade> createState() => _RoadParadeState();
}

class _RoadParadeState extends State<RoadParade>
    with SingleTickerProviderStateMixin {
  static const _dir = 'assets/images/road/living';
  static const _secsPerItem = 2.4;
  static const _gridCount = 12;

  late final AnimationController _c = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: (widget.items.length * _secsPerItem * 1000)
              .round()
              .clamp(1000, 1 << 30)));
  final _images = <String, ui.Image>{};
  final _loading = <String>{};
  final _centre = ValueNotifier<int>(0);
  int _version = 0, _base = -1;
  bool _reduce = false;

  int get _n => widget.items.length;
  double get _pos => _c.value * _n;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onTick);
    _ensure(0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.disableAnimationsOf(context);
    if (_reduce || _n == 0) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  void _onTick() {
    final b = _pos.floor();
    if (b != _base) {
      _base = b;
      _centre.value = _pos.round() % _n;
      _ensure(b);
    } else if (_pos.round() % _n != _centre.value) {
      _centre.value = _pos.round() % _n;
    }
  }

  /// Decodes the sprites near [at] small, and frees the ones left behind.
  void _ensure(int at) {
    if (_n == 0) return;
    final want = <String>{
      for (var k = -3; k <= 5; k++) widget.items[(at + k) % _n].art,
    };
    for (final a in _images.keys.toList()) {
      if (!want.contains(a)) {
        _images.remove(a)?.dispose();
        _version++;
      }
    }
    for (final a in want) {
      if (_images.containsKey(a) || !_loading.add(a)) continue;
      unawaited(_decode(a));
    }
  }

  Future<void> _decode(String art) async {
    try {
      final data = await rootBundle.load('$_dir/lm_$art.webp');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
          targetWidth: 220);
      final img = (await codec.getNextFrame()).image;
      codec.dispose();
      if (!mounted) return img.dispose();
      _images[art]?.dispose();
      _images[art] = img;
      _version++;
      if (!_c.isAnimating && mounted) setState(() {});
    } catch (_) {
      // A missing sprite is just a gap in the parade.
    } finally {
      _loading.remove(art);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _centre.dispose();
    for (final i in _images.values) {
      i.dispose();
    }
    _images.clear();
    super.dispose();
  }

  bool _lit(ParadeItem i) =>
      !widget.dimUnlit || i.bundled || widget.litArts.contains(i.art);

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    if (_n == 0) return SizedBox(height: widget.height);
    return Semantics(
      label: RoadAheadStrings.heroLabel(_n),
      image: true,
      excludeSemantics: true,
      child: _reduce ? _grid(c) : _parade(c),
    );
  }

  Widget _grid(LumColors c) {
    final shown = widget.items.take(_gridCount).toList();
    return SizedBox(
      height: widget.height,
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: LumSpace.md,
          runSpacing: LumSpace.md,
          children: [
            for (final i in shown)
              Opacity(
                opacity: _lit(i) ? 1 : .4,
                child: ColorFiltered(
                  colorFilter: _lit(i) ? _none : _grey,
                  child: Image.asset('$_dir/lm_${i.art}.webp',
                      width: 56,
                      height: 56,
                      cacheWidth: 160,
                      excludeFromSemantics: true,
                      errorBuilder: (_, __, ___) =>
                          const SizedBox(width: 56, height: 56)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _parade(LumColors c) {
    return SizedBox(
      height: widget.height,
      child: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: _ParadePainter(
                  controller: _c,
                  items: widget.items,
                  images: _images,
                  version: _version,
                  lit: _lit,
                  litKey: Object.hash(widget.dimUnlit, widget.litArts.length),
                  glow: widget.dimUnlit,
                  celebrate: widget.celebrate,
                  road: c.borderSubtle,
                  glowColor: c.textAccent,
                  spark: c.textAccent,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 28,
            child: ValueListenableBuilder<int>(
              valueListenable: _centre,
              builder: (_, i, __) {
                final it = widget.items[i];
                return AnimatedSwitcher(
                  duration: LumMotion.base,
                  child: Text(
                    RoadAheadStrings.caption(it.title, it.day),
                    key: ValueKey(it.art),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LumText.subheadlineEmphasized
                        .copyWith(color: c.textPrimary),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static const _none = ColorFilter.mode(Color(0x00000000), BlendMode.dst);
  static const _grey = ColorFilter.matrix(<double>[
    .33, .33, .33, 0, 0, //
    .33, .33, .33, 0, 0,
    .33, .33, .33, 0, 0,
    0, 0, 0, 1, 0,
  ]);
}

class _ParadePainter extends CustomPainter {
  _ParadePainter({
    required this.controller,
    required this.items,
    required this.images,
    required this.version,
    required this.lit,
    required this.litKey,
    required this.glow,
    required this.celebrate,
    required this.road,
    required this.glowColor,
    required this.spark,
  }) : super(repaint: controller);

  final AnimationController controller;
  final List<ParadeItem> items;
  final Map<String, ui.Image> images;
  final int version, litKey;
  final bool Function(ParadeItem) lit;
  final bool glow, celebrate;
  final Color road, glowColor, spark;

  static const _reach = 2.6;

  @override
  void paint(Canvas canvas, Size size) {
    final n = items.length;
    final pos = controller.value * n;
    final secs = pos * _RoadParadeState._secsPerItem;
    final w = size.width, h = size.height;
    final spacing = w * .27, floorY = h * .78;

    // The road: one soft curved band under the parade.
    canvas.drawPath(
      Path()
        ..moveTo(-10, floorY + 6)
        ..quadraticBezierTo(w / 2, floorY - h * .16, w + 10, floorY + 6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = road,
    );

    final base = pos.floor();
    // Far ones first so the middle one is drawn on top.
    final ks = [for (var k = -3; k <= 4; k++) k]
      ..sort((a, b) => ((b - pos + base).abs()).compareTo((a - pos + base).abs()));
    for (final k in ks) {
      final p = base + k - pos;
      if (p.abs() > _reach) continue;
      final item = items[(base + k) % n];
      final img = images[item.art];
      if (img == null) continue;
      final near = 1 - (p.abs() / _reach);
      final fade = ((_reach - p.abs()) / .8).clamp(0.0, 1.0);
      final scale = .5 + .5 * near;
      final side = h * .62 * scale;
      final bob = math.sin(secs * 2 + base + k) * 2.5 * near;
      final cx = w / 2 + p * spacing;
      final cy = floorY - (1 - p * p / 9) * h * .06 + bob;
      final dst = Rect.fromCenter(
          center: Offset(cx, cy - side / 2), width: side, height: side);
      final on = lit(item);
      if (on && glow) {
        canvas.drawCircle(
          dst.center,
          side * .62,
          Paint()
            ..shader = ui.Gradient.radial(dst.center, side * .62, [
              glowColor.withValues(alpha: .38 * fade),
              glowColor.withValues(alpha: 0),
            ]),
        );
      }
      paintImage(
          canvas: canvas,
          rect: dst,
          image: img,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          opacity: (on ? 1 : .45) * fade,
          colorFilter: on ? null : _RoadParadeState._grey);
    }

    if (celebrate) {
      final sp = Paint()..color = spark;
      for (var i = 0; i < 14; i++) {
        final a = i * 2.399;
        final r = .18 + .32 * ((i * 37) % 100) / 100;
        final o = Offset(w / 2 + math.cos(a) * w * r * 1.4,
            h * .45 + math.sin(a) * h * r);
        final t = (math.sin(secs * 2.2 + i * 1.7) + 1) / 2;
        final s = 2 + 4 * t;
        sp.color = spark.withValues(alpha: .15 + .75 * t);
        canvas.drawPath(
          Path()
            ..moveTo(o.dx, o.dy - s)
            ..quadraticBezierTo(o.dx, o.dy, o.dx + s, o.dy)
            ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + s)
            ..quadraticBezierTo(o.dx, o.dy, o.dx - s, o.dy)
            ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - s),
          sp,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ParadePainter o) =>
      o.version != version ||
      o.litKey != litKey ||
      o.celebrate != celebrate ||
      o.glow != glow ||
      o.road != road ||
      o.items != items;
}
