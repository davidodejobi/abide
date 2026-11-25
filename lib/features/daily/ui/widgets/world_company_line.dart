import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';

import '../../domain/world_company.dart';
import '../daily_strings.dart';

/// "2,481 people read Day 12 today", or once the reader has finished,
/// "You and 1,204 others finished Day 12". Renders nothing without data.
class WorldCompanyLine extends ConsumerWidget {
  const WorldCompanyLine({
    super.key,
    required this.planKey,
    required this.day,
    this.finished = false,
  });

  final String planKey;
  final int day;
  final bool finished;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w =
        ref.watch(worldCompanyProvider((planKey: planKey, day: day))).valueOrNull;
    if (w == null) return const SizedBox.shrink();
    final locale = Localizations.maybeLocaleOf(context) ?? const Locale('en');
    final readers = w.readersOnDay;
    final others = readers == null ? 0 : readers - 1;
    final text = finished
        ? DailyStrings.youAndOthersFinished(
            day, others < worldMinCount ? null : formatCount(others, locale))
        : DailyStrings.peopleReadToday(
            day,
            readers == null || readers < worldMinCount
                ? null
                : formatCount(readers, locale));
    final child = Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(text,
          style: LumText.callout.copyWith(color: context.lum.textSecondary)),
    );
    if (!finished || MediaQuery.disableAnimationsOf(context)) return child;
    // The finish moment fades in gently; reduced motion just shows it.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      builder: (_, v, c) => Opacity(opacity: v, child: c),
      child: child,
    );
  }
}
