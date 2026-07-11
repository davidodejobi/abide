import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openbaptisthymnal/core/router/app_router.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/core/utils/time_greeting.dart';
import 'package:openbaptisthymnal/features/onboarding/providers/onboarding_provider.dart';

import '../domain/date_key.dart';
import '../providers/daily_providers.dart';
import 'widgets/plan_picker_sheet.dart';
import 'widgets/streak_header.dart';
import 'widgets/todays_reading_card.dart';

/// The Today tab: the app's answer to "why would I open this tomorrow?".
///
/// Everything else in Abide is a destination the user has to remember to visit.
/// This is the one screen that asks for something small and gives something
/// back for it, so there is a reason to come again -- the streak and the plan
/// are the reason, and step 4's notification is what carries that reason
/// outside the app, where it can actually reach someone.
@RoutePage()
class TodayTabScreen extends ConsumerStatefulWidget {
  const TodayTabScreen({super.key});

  @override
  ConsumerState<TodayTabScreen> createState() => _TodayTabScreenState();
}

class _TodayTabScreenState extends ConsumerState<TodayTabScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final name = ref.watch(userNameProvider);
    final greeting = TimeGreeting.now();
    final streak = ref.watch(streakProvider);
    final reading = ref.watch(todaysReadingProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name == null
                      ? greeting.greeting
                      : '${greeting.greeting}, $name',
                  style: AppTextStyles.headlineLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                // The date, not a devotional aside. TimeGreeting.accent ("he
                // gives his beloved sleep") reads as a fortune cookie under a
                // name, and a line that says nothing is worse than no line. A
                // date is short, is true, and is the one thing a tab called
                // Today should be willing to state.
                Text(
                  formatToday(DateTime.now()),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverPadding(
          // 120 clears the floating nav bar, matching the other tabs.
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              StreakHeader(
                streak: streak,
                onTap: () => context.router.push(const StreakRoute()),
              ),
              const SizedBox(height: 16),

              // Three states, deliberately distinct. "No plan yet" and "plan
              // finished" both have no passage to show, but telling someone who
              // just read the Bible in a year to "choose a plan" would be a
              // small insult.
              reading.when(
                loading: () => const _CardPlaceholder(),
                error: (e, _) => const _CardPlaceholder(
                  message: "Today's reading couldn't be loaded.",
                ),
                data: (data) => data == null
                    ? _NoPlanCard(onChoose: () => _choosePlan(context))
                    : TodaysReadingCard(
                        reading: data,
                        onChangePlan: () => _choosePlan(context),
                      ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _choosePlan(BuildContext context) {
    return showPlanPickerSheet(context);
  }
}

/// Shown before a plan is picked. The whole screen has one job at this point,
/// so it says one thing and offers one button.
class _NoPlanCard extends StatelessWidget {
  const _NoPlanCard({required this.onChoose});

  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start a reading plan',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A little each day. Pick one and today has a place to begin.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onChoose,
              child: const Text('Choose a plan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardPlaceholder extends StatelessWidget {
  const _CardPlaceholder({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: message == null
          ? const CircularProgressIndicator.adaptive()
          : Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
    );
  }
}
