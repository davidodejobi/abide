import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';

/// A text field with a hand-drawn wobbly underline and the doodle marker font.
/// Ink follows the theme so it works in light and dark.
class HandDrawnField extends StatelessWidget {
  const HandDrawnField({
    super.key,
    required this.controller,
    this.hintText,
    this.onSubmitted,
    this.autofocus = true,
    this.color,
  });

  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? Theme.of(context).colorScheme.onSurface;
    final hintColor = ink.withValues(alpha: 0.35);

    return CustomPaint(
      painter: _UnderlinePainter(color: ink),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          autofocus: autofocus,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.words,
          cursorColor: ink,
          style: AppTextStyles.doodleHeadline(color: ink),
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintText: hintText,
            hintStyle: AppTextStyles.doodleHeadline(color: hintColor),
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
          ),
        ),
      ),
    );
  }
}

class _UnderlinePainter extends CustomPainter {
  _UnderlinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final y = size.height - 2;
    final path = Path()..moveTo(4, y);
    const seg = 24;
    for (var i = 1; i <= seg; i++) {
      final t = i / seg;
      final x = 4 + (size.width - 8) * t;
      final jitter = math.sin(t * 20) * 0.6;
      path.lineTo(x, y + jitter);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _UnderlinePainter old) => old.color != color;
}
