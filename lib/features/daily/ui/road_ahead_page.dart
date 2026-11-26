import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_page_background.dart';

import '../providers/landmark_download_provider.dart';
import 'daily_strings.dart';
import 'road_ahead_strings.dart';
import 'widgets/road_parade.dart';

/// What the landmark download is, made fun: a parade of the real landmarks, a
/// plain size and count, and the one button that fits where the download is.
/// The download lives in [landmarkDownloadProvider], so it carries on if the
/// reader leaves. Not offered on web (no disk to keep models on).
@RoutePage()
class RoadAheadPage extends ConsumerStatefulWidget {
  const RoadAheadPage({super.key});

  @override
  ConsumerState<RoadAheadPage> createState() => _RoadAheadPageState();
}

class _RoadAheadPageState extends ConsumerState<RoadAheadPage> {
  @override
  void initState() {
    super.initState();
    Future(() => ref.read(landmarkDownloadProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final s = ref.watch(landmarkDownloadProvider);
    final notifier = ref.read(landmarkDownloadProvider.notifier);
    final remote = ref.watch(remoteLandmarkModelsProvider).valueOrNull ?? const [];
    final all = ref.watch(landmarkCatalogProvider).valueOrNull?.models.length ?? 0;
    final bytes = remote.fold<int>(0, (a, m) => a + m.bytes);
    final done = s.status == LandmarkDownloadStatus.done;
    final busy = s.status == LandmarkDownloadStatus.downloading;
    final failed = s.status == LandmarkDownloadStatus.failed;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: LumPageBackground()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      LumSize.screenGutter + 4, 8, LumSize.screenGutter + 4, 40),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Semantics(
                        button: true,
                        label: DailyStrings.back,
                        excludeSemantics: true,
                        onTap: () => Navigator.of(context).maybePop(),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            width: LumSize.touchTarget,
                            height: LumSize.touchTarget,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.chip,
                              border: Border.all(color: c.borderSubtle),
                            ),
                            child: Icon(Icons.chevron_left_rounded,
                                size: 28, color: c.textPrimary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: LumSpace.lg),
                    const RoadAheadHero(height: 250),
                    const SizedBox(height: LumSpace.xl),
                    Semantics(
                      header: true,
                      child: Text(
                          done ? RoadAheadStrings.doneTitle : RoadAheadStrings.title,
                          style: LumText.title1.copyWith(color: c.textPrimary)),
                    ),
                    const SizedBox(height: LumSpace.md),
                    Text(done ? RoadAheadStrings.doneBody : RoadAheadStrings.body,
                        style: LumText.body.copyWith(color: c.textSecondary)),
                    const SizedBox(height: LumSpace.lg),
                    Wrap(
                      spacing: LumSpace.sm,
                      runSpacing: LumSpace.sm,
                      children: [
                        _Fact(RoadAheadStrings.toDownload(remote.length)),
                        _Fact(RoadAheadStrings.included(all - remote.length)),
                        _Fact(landmarkSizeLabel(bytes)),
                      ],
                    ),
                    const SizedBox(height: LumSpace.lg),
                    if (busy) ...[
                      Text(RoadAheadStrings.downloading,
                          style: LumText.subheadlineEmphasized
                              .copyWith(color: c.textPrimary)),
                      const SizedBox(height: LumSpace.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(LumRadius.full),
                        child: LinearProgressIndicator(
                          value: s.progress,
                          minHeight: 10,
                          color: c.bgPrimary,
                          backgroundColor: c.borderSubtle,
                        ),
                      ),
                      const SizedBox(height: LumSpace.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(RoadAheadStrings.progress(s.doneFiles, s.totalFiles),
                              style: LumText.footnote
                                  .copyWith(color: c.textSecondary)),
                          Text(
                              RoadAheadStrings.megabytes(
                                  landmarkSizeLabel(s.doneBytes),
                                  landmarkSizeLabel(s.totalBytes)),
                              style: LumText.footnote
                                  .copyWith(color: c.textSecondary)),
                        ],
                      ),
                    ] else ...[
                      if (failed) ...[
                        Text(RoadAheadStrings.failed,
                            style: LumText.footnote.copyWith(color: c.textDanger)),
                        const SizedBox(height: LumSpace.md),
                      ] else if (!done) ...[
                        Text(RoadAheadStrings.wifi,
                            style: LumText.footnote
                                .copyWith(color: c.textSecondary)),
                        const SizedBox(height: LumSpace.md),
                      ],
                      if (done)
                        LumButton(
                          label: RoadAheadStrings.allSet,
                          kind: LumButtonKind.gold,
                          onPressed: () => Navigator.of(context).maybePop(),
                        )
                      else
                        LumButton(
                          label: failed
                              ? RoadAheadStrings.retry
                              : RoadAheadStrings.download,
                          onPressed: notifier.start,
                        ),
                    ],
                    if (done && s.totalBytes > 0) ...[
                      const SizedBox(height: LumSpace.sm),
                      Center(
                        child: TextButton(
                          onPressed: notifier.remove,
                          child: Text(
                              RoadAheadStrings.remove(landmarkSizeLabel(s.totalBytes)),
                              style: LumText.subheadline
                                  .copyWith(color: c.textSecondary)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: LumSpace.md, vertical: 6),
      decoration: BoxDecoration(
        color: c.chip,
        borderRadius: BorderRadius.circular(LumRadius.full),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Text(text,
          style: LumText.footnoteEmphasized.copyWith(color: c.textPrimary)),
    );
  }
}
