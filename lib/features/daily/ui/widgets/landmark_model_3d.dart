import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart' hide Animation;
import 'package:vector_math/vector_math.dart' as vm;

/// Spike: `--dart-define=LANDMARK_3D=true` swaps the sprite turntable for a
/// real 3D model (flutter_scene on Flutter GPU). Off by default.
const kLandmark3d = bool.fromEnvironment('LANDMARK_3D');

/// A glb landmark spun by [turns] (the same controller that drives the sprite
/// sheet, so idle turn, whoosh and drag inertia carry over). Shows [fallback]
/// until the model is ready, and for good if 3D init fails.
class LandmarkModel3d extends StatefulWidget {
  const LandmarkModel3d({
    super.key,
    required this.art,
    required this.turns,
    required this.fallback,
  });

  final String art;
  final Animation<double> turns;
  final Widget fallback;

  @override
  State<LandmarkModel3d> createState() => _LandmarkModel3dState();
}

class _LandmarkModel3dState extends State<LandmarkModel3d> {
  final _scene = Scene();
  Node? _model;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sw = Stopwatch()..start();
    try {
      await Scene.initializeStaticResources();
      final m = await Node.fromGlbAsset('assets/landmarks3d/${widget.art}.glb');
      _scene
        ..add(m)
        // Warm key light from the upper left, like the Blender sun.
        ..directionalLight = DirectionalLight(
          direction: vm.Vector3(-.4, -1, -.6),
          intensity: 2.2,
          color: vm.Vector3(1, .95, .85),
        );
      debugPrint('landmark3d ${widget.art} ready in ${sw.elapsedMilliseconds}ms');
      if (mounted) setState(() => _model = m);
    } catch (e) {
      debugPrint('landmark3d failed, keeping sprite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _model;
    if (m == null) return widget.fallback;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _ScenePainter(_scene, m, widget.turns),
        size: Size.infinite,
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.scene, this.model, this.turns) : super(repaint: turns);
  final Scene scene;
  final Node model;
  final Animation<double> turns;

  // ponytail: fixed camera tuned on the ark, per-model framing when all 37 go 3D.
  static final _cam = PerspectiveCamera(
    position: vm.Vector3(0, 4.6, 7.4),
    target: vm.Vector3(0, 1.7, 0),
  );

  @override
  void paint(Canvas canvas, Size size) {
    model.localTransform = vm.Matrix4.rotationY(turns.value * 2 * math.pi);
    scene.render(_cam, canvas, viewport: Offset.zero & size);
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.model != model;
}
