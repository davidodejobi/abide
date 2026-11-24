import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

import '../daily_strings.dart';

enum RoadMood { day, evening }

/// The road hero (Figma `Road scene`, Hero size). The hills, sky and road are a
/// baked 3x raster of the Figma vectors (`assets/images/road/bg_*`); the stops,
/// traveller and current-stop glow are placed on top so the day numbers and the
/// traveller's position come from real plan progress.
///
/// [currentDay] is the stop that glows: today's reading by day, tomorrow's in
/// the evening. The traveller stands on the stop just behind it. Decorative:
/// the screen's own text carries the meaning, so this is excluded from
/// semantics.
class RoadScene extends StatelessWidget {
  const RoadScene({
    super.key,
    required this.width,
    required this.mood,
    required this.currentDay,
    required this.totalDays,
    this.showTomorrowTag = false,
  });

  final double width;
  final RoadMood mood;

  /// Day number at the glowing stop; null when the plan is finished.
  final int? currentDay;
  final int totalDays;
  final bool showTomorrowTag;

  static const double designWidth = 390;
  static const double designHeight = 560;

  // Slot rects on the 390 x 560 scene: x, y, width, height (Figma Stop 1..6).
  static const _slots = [
    Rect.fromLTWH(227, 367, 146, 109),
    Rect.fromLTWH(50, 309, 119, 89),
    Rect.fromLTWH(218, 248, 104, 78),
    Rect.fromLTWH(103, 208, 76, 57),
    Rect.fromLTWH(218, 180, 54, 41),
    Rect.fromLTWH(158, 162, 44, 33),
  ];

  // Source stop widths of the three baked stop images (Figma instances).
  static const _doneW = 119.0, _currentW = 104.0, _upcomingW = 76.0;

  static double heightFor(double width) => width * designHeight / designWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final k = width / designWidth;
    final tone = dark ? 'dark' : 'light';
    final evening = mood == RoadMood.evening;
    final bg = evening ? 'bg_evening_$tone' : 'bg_$tone';

    // Slot index (1-based) of the glowing stop: 3 by day, 4 in the evening
    // (the traveller rests on slot 3, tomorrow's stop is one up the road).
    final curSlot = evening ? 4 : 3;
    final base = currentDay ?? (totalDays + 1);

    Widget stop(int slot) {
      final r = _slots[slot - 1];
      final num = base + (slot - curSlot);
      final isCurrent = slot == curSlot && currentDay != null && num <= totalDays;
      final isDone = slot < curSlot && num >= 1;
      final kind = isCurrent ? 'current' : (isDone ? 'done' : 'upcoming');
      final srcW = switch (kind) {
        'current' => _currentW,
        'done' => _doneW,
        _ => _upcomingW,
      };
      final s = r.width / srcW * k;
      final label = !isDone && num >= 1 && num <= totalDays &&
              (isCurrent || (slot > curSlot && slot <= curSlot + 2))
          ? '$num'
          : null;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: r.left * k - 20 * s,
            top: r.top * k - 14 * s,
            width: 160 * s,
            height: 120 * s,
            child: Image.asset('assets/images/road/stop_${kind}_$tone.png',
                fit: BoxFit.fill, filterQuality: FilterQuality.medium),
          ),
          if (label != null)
            Positioned(
              left: r.left * k,
              width: r.width * k,
              top: (r.top + r.height * (isCurrent ? 0.2 : 0.18)) * k,
              height: r.height * 0.4 * k,
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: LumText.roadDisplayStat28.copyWith(
                    fontSize: (r.width * 0.2 * k).clamp(8, 40).toDouble(),
                    height: 1,
                    color: isCurrent ? c.sceneStopOnCurrent : c.sceneStopOnUpcoming,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // The traveller stands one stop behind the glowing one.
    final tSlot = _slots[curSlot - 2];
    final travW = tSlot.width * 0.47 * k;
    final tBottom = (tSlot.top + tSlot.width * 0.38) * k;
    final cx = (tSlot.left + tSlot.width / 2) * k;
    final resting = evening;
    final t = travW / (resting ? 48 : 56);
    final travImg = resting ? 'traveller_resting_$tone' : 'traveller_walking_$tone';

    final tomorrowSlot = _slots[curSlot - 1];

    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: heightFor(width),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Image.asset('assets/images/road/$bg.png',
                  fit: BoxFit.fill, filterQuality: FilterQuality.medium),
            ),
            for (final s in [6, 5, 4, 3, 2, 1]) Positioned.fill(child: stop(s)),
            Positioned(
              left: cx - (resting ? 36 : 40) * t,
              top: tBottom - (resting ? 85 : 97.6) * t,
              width: 80 * t,
              height: 110 * t,
              child: Image.asset('assets/images/road/$travImg.png',
                  fit: BoxFit.fill, filterQuality: FilterQuality.medium),
            ),
            if (showTomorrowTag && currentDay != null && currentDay! <= totalDays)
              Positioned(
                left: (tomorrowSlot.left + tomorrowSlot.width / 2) * k - 38,
                top: (tomorrowSlot.top - 26) * k,
                width: 76,
                height: 23,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.scenePanel,
                    borderRadius: BorderRadius.circular(LumRadius.full),
                    border: Border.all(color: c.borderSubtle),
                  ),
                  child: Center(
                    child: Text(
                      DailyStrings.tomorrow,
                      textScaler: TextScaler.noScaling,
                      style: LumText.caption.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
