import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';
import 'package:openbaptisthymnal/features/app_update/domain/app_config.dart';
import 'package:openbaptisthymnal/features/app_update/providers/app_update_provider.dart';
import 'package:openbaptisthymnal/features/app_update/ui/app_update_strings.dart';
import 'package:url_launcher/url_launcher.dart';

/// Wraps the whole app (MaterialApp.router `builder`) and puts the forced gate,
/// optional sheet or maintenance state on top of whatever screen is showing.
/// Checks on start and on every resume, without blocking the first frame.
class AppUpdateOverlay extends HookConsumerWidget {
  const AppUpdateOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(() => ref.read(appUpdateProvider.notifier).check());
      return null;
    }, const []);
    // The overlay sits above the Navigator, so it can't use PopScope. Android
    // back is taken here instead: the sheet and maintenance dismiss, the forced
    // gate swallows it. Registered at mount, before the Router's own observer,
    // so it gets the first look.
    useEffect(() {
      final observer = _BackObserver(() {
        final n = ref.read(appUpdateProvider.notifier);
        switch (ref.read(appUpdateProvider).status) {
          case UpdateStatus.none:
            return false;
          case UpdateStatus.forced:
            return true;
          case UpdateStatus.maintenance:
            n.dismissMaintenance();
            return true;
          case UpdateStatus.optional:
            n.dismissOptional();
            return true;
        }
      });
      WidgetsBinding.instance.addObserver(observer);
      return () => WidgetsBinding.instance.removeObserver(observer);
    }, const []);
    useOnAppLifecycleStateChange((_, state) {
      if (state == AppLifecycleState.resumed) {
        ref.read(appUpdateProvider.notifier).check();
      }
    });

    final update = ref.watch(appUpdateProvider);
    final notifier = ref.read(appUpdateProvider.notifier);
    final blocked = update.status != UpdateStatus.none;
    return Stack(
      children: [
        ExcludeSemantics(
          excluding: blocked,
          child: ExcludeFocus(
            excluding: blocked,
            child: IgnorePointer(ignoring: blocked, child: child),
          ),
        ),
        // ponytail: Android uses the same sheet/gate and opens the Play
        // listing. Play Core in-app (flexible) updates are a later upgrade.
        switch (update.status) {
          UpdateStatus.none => const SizedBox.shrink(),
          UpdateStatus.forced => Positioned.fill(child: _Gate(update: update)),
          UpdateStatus.maintenance => Positioned.fill(
              child: _Maintenance(onKeepReading: notifier.dismissMaintenance),
            ),
          UpdateStatus.optional => Positioned.fill(
              child: _Sheet(update: update, onLater: notifier.dismissOptional),
            ),
        },
      ],
    );
  }
}

/// Opens the store; sets [error] to a short message when it can't.
class _BackObserver with WidgetsBindingObserver {
  _BackObserver(this.onBack);
  final bool Function() onBack;

  @override
  Future<bool> didPopRoute() async => onBack();
}

Future<void> _openStore(AppConfig? config, ValueNotifier<String?> error) async {
  var ok = false;
  try {
    ok = await launchUrl(
      Uri.parse(storeUrlFor(config, ios: _isIos)),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {}
  error.value = ok ? null : AppUpdateStrings.storeOpenFailed;
}

Widget _errorText(BuildContext context, String? message) => message == null
    ? const SizedBox.shrink()
    : Padding(
        padding: const EdgeInsets.only(top: LumSpace.md),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: LumText.footnote.copyWith(color: context.lum.textSecondary),
        ),
      );

bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

class _Coin extends StatelessWidget {
  const _Coin(this.size);
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.buttonGoldTop, c.buttonGoldBottom],
        ),
      ),
      child: Icon(Icons.chevron_right_rounded,
          size: size * 0.6, color: c.buttonOnGold),
    );
  }
}

/// Full-screen centred message: coin, title, body, then the actions.
class _Centered extends StatelessWidget {
  const _Centered({
    required this.title,
    required this.body,
    required this.actions,
    this.footnote,
  });

  final String title;
  final String body;
  final List<Widget> actions;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Material(
      color: c.bgPage,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: LumSpace.xl + 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _Coin(72),
                const SizedBox(height: LumSpace.xl),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: LumText.title1.copyWith(color: c.textPrimary),
                ),
                const SizedBox(height: LumSpace.lg),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: LumText.body.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: LumSpace.xl),
                ...actions,
                if (footnote != null) ...[
                  const SizedBox(height: LumSpace.lg),
                  Text(
                    footnote!,
                    textAlign: TextAlign.center,
                    style: LumText.footnote.copyWith(color: c.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Forced update. Opaque and full screen, so nothing underneath can be
/// reached. No dismiss control.
class _Gate extends HookConsumerWidget {
  const _Gate({required this.update});
  final AppUpdateState update;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = useState<String?>(null);
    final config = update.config;
    final at = update.checkedAt;
    final today = DateTime.now();
    final time = at != null &&
            at.year == today.year &&
            at.month == today.month &&
            at.day == today.day
        ? MaterialLocalizations.of(context)
            .formatTimeOfDay(TimeOfDay.fromDateTime(at))
        : null;
    // ponytail: the design also has "Export my notes" here. Left out until
    // notes export exists; the gate only offers the store button for now.
    return _Centered(
      title: AppUpdateStrings.forcedTitle,
      body: AppUpdateStrings.forcedBody,
      actions: [
        LumButton(
          label: _isIos
              ? AppUpdateStrings.openAppStore
              : AppUpdateStrings.openPlayStore,
          onPressed: () => _openStore(config, error),
        ),
        const SizedBox(height: LumSpace.md),
        LumButton(
          label: AppUpdateStrings.checkAgain,
          kind: LumButtonKind.secondary,
          onPressed: () => ref.read(appUpdateProvider.notifier).check(),
        ),
        _errorText(context, error.value),
      ],
      footnote: AppUpdateStrings.forcedFootnote(config?.minVersion ?? '', time),
    );
  }
}

/// Maintenance: reading stays on, so this is dismissible.
class _Maintenance extends StatelessWidget {
  const _Maintenance({required this.onKeepReading});
  final VoidCallback onKeepReading;

  @override
  Widget build(BuildContext context) {
    return _Centered(
      title: AppUpdateStrings.maintenanceTitle,
      body: AppUpdateStrings.maintenanceBody,
      actions: [
        LumButton(
            label: AppUpdateStrings.keepReading, onPressed: onKeepReading),
      ],
      footnote: AppUpdateStrings.maintenanceFootnote,
    );
  }
}

/// Optional update: bottom sheet over a scrim. Tapping the scrim is "Later".
class _Sheet extends HookWidget {
  const _Sheet({required this.update, required this.onLater});
  final AppUpdateState update;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final error = useState<String?>(null);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onLater,
            child: const ColoredBox(color: Color(0x59000000)),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.9),
            child: Material(
              color: c.glassFillOpaque,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(LumRadius.xl),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      LumSize.screenGutter,
                      LumSpace.md,
                      LumSize.screenGutter,
                      LumSpace.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 5,
                            decoration: BoxDecoration(
                              color: c.borderStrong,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(height: LumSpace.md),
                        Row(
                          children: [
                            const _Coin(44),
                            const SizedBox(width: LumSpace.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppUpdateStrings.optionalTitle,
                                    style: LumText.headline
                                        .copyWith(color: c.textPrimary),
                                  ),
                                  Text(
                                    AppUpdateStrings.optionalVersion(
                                        update.config?.latestVersion ?? ''),
                                    style: LumText.footnote
                                        .copyWith(color: c.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: LumSpace.md),
                        Text(
                          AppUpdateStrings.optionalHeadline,
                          style: LumText.title2.copyWith(color: c.textPrimary),
                        ),
                        const SizedBox(height: LumSpace.sm),
                        Text(
                          AppUpdateStrings.optionalBody,
                          style: LumText.subheadline
                              .copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: LumSpace.md),
                        LumButton(
                          label: AppUpdateStrings.update,
                          onPressed: () => _openStore(update.config, error),
                        ),
                        _errorText(context, error.value),
                        const SizedBox(height: LumSpace.sm),
                        TextButton(
                          onPressed: onLater,
                          style: TextButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            foregroundColor: c.textPrimary,
                          ),
                          child: Text(
                            AppUpdateStrings.later,
                            style:
                                LumText.headline.copyWith(color: c.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
