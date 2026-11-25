import 'dart:ui' as ui;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/utils/services/share_service.dart';
import 'package:openbaptisthymnal/core/utils/toast_helper.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_chip.dart';
import 'package:openbaptisthymnal/core/widgets/lum_circle_button.dart';
import 'package:openbaptisthymnal/core/widgets/lum_page_background.dart';
import 'package:openbaptisthymnal/features/share_card/ui/share_card_style.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Share composer (Figma M4-04): previews the card, lets the reader pick the
/// look and shape, then shares, saves or copies it.
///
/// The top bar and the action area stay pinned; only the preview and options
/// scroll. The card is supplied by [cardBuilder] so hymns and scripture share
/// this chrome while rendering different content.
class ShareCardComposer extends StatefulWidget {
  const ShareCardComposer({
    super.key,
    required this.title,
    required this.filename,
    required this.cardBuilder,
    required this.textBuilder,
    this.options,
  });

  /// Page title, e.g. "Share verse".
  final String title;

  /// Base name for the exported PNG (no extension).
  final String filename;

  /// Builds the card body for the chosen look, shape and reference toggle.
  final Widget Function(
          ShareCardStyle style, ShareCardFormat format, bool showReference)
      cardBuilder;

  /// The card's words as plain text, with the reference line when asked.
  /// The composer appends the app name.
  final String Function(bool showReference) textBuilder;

  /// Extra content controls (e.g. the stanza chips), shown above the look.
  final Widget? options;

  @override
  State<ShareCardComposer> createState() => _ShareCardComposerState();
}

class _ShareCardComposerState extends State<ShareCardComposer> {
  final _cardKey = GlobalKey();
  late ShareCardStyle _style = ShareCardStyle.presets.first;
  ShareCardFormat _format = ShareCardFormat.status;
  bool _showReference = true;
  bool _busy = false;

  Rect? _origin() {
    final box = context.findRenderObject() as RenderBox?;
    return box != null ? box.localToGlobal(Offset.zero) & box.size : null;
  }

  /// Runs [job] one at a time, showing [error] if it throws.
  Future<void> _run(Future<void> Function() job, String error) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job();
    } catch (_) {
      if (mounted) ToastHelper.error(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareImage() => _run(() async {
        final origin = _origin();
        await ShareService().shareImage(
          imageBytes: await _capture(),
          filename: widget.filename,
          sharePositionOrigin: origin,
        );
      }, NotesStrings.shareError);

  Future<void> _saveImage() => _run(() async {
        await ShareService().saveImage(await _capture(), widget.filename);
        if (mounted) ToastHelper.success(context, NotesStrings.imageSaved);
      }, NotesStrings.saveError);

  String get _text =>
      '${widget.textBuilder(_showReference)}\n\n${NotesStrings.appMark}';

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: _text));
    if (mounted) ToastHelper.success(context, NotesStrings.textCopied);
  }

  Future<void> _shareText() => _run(
        () => ShareService().shareText(_text, sharePositionOrigin: _origin()),
        NotesStrings.shareError,
      );

  /// Exports 1080 px wide whatever the preview size (1080 x 1920 or 1080 x 1080).
  Future<Uint8List> _capture() async {
    final boundary =
        _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image =
        await boundary.toImage(pixelRatio: 1080 / boundary.size.width);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LumPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(LumSize.screenGutter,
                    LumSpace.md, LumSize.screenGutter, LumSpace.md),
                child: Row(
                  children: [
                    LumCircleButton(
                      icon: PhosphorIcons.caretLeft(),
                      label: NotesStrings.back,
                      onPressed: () => context.router.maybePop(),
                    ),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style:
                              LumText.headline.copyWith(color: c.textPrimary),
                        ),
                      ),
                    ),
                    // Balances the back button so the title stays centred.
                    const SizedBox(width: LumSize.glassButton),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(LumSize.screenGutter,
                      LumSpace.sm, LumSize.screenGutter, LumSpace.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _preview(c),
                      const SizedBox(height: LumSpace.xl),
                      if (widget.options != null) ...[
                        widget.options!,
                        const SizedBox(height: LumSpace.lg),
                      ],
                      _OptionGroup(
                        label: NotesStrings.lookLabel,
                        children: [
                          for (final preset in ShareCardStyle.presets)
                            LumChip(
                              label: preset.label,
                              selected: preset.id == _style.id,
                              onTap: () => setState(() => _style = preset),
                            ),
                        ],
                      ),
                      const SizedBox(height: LumSpace.lg),
                      _OptionGroup(
                        label: NotesStrings.shapeLabel,
                        children: [
                          for (final f in ShareCardFormat.values)
                            LumChip(
                              label: f.label,
                              selected: f == _format,
                              onTap: () => setState(() => _format = f),
                            ),
                          LumChip(
                            label: NotesStrings.showReference,
                            selected: _showReference,
                            onTap: () => setState(
                                () => _showReference = !_showReference),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _actions(c),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview(LumColors c) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LumRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: c.glassEdgeShadow,
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(LumRadius.xl),
              // The export must not change with the reader's text size.
              child: MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.noScaling),
                child: RepaintBoundary(
                  key: _cardKey,
                  child: widget.cardBuilder(_style, _format, _showReference),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _actions(LumColors c) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.borderSubtle)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(LumSize.screenGutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LumButton(
                label: NotesStrings.shareImage,
                icon: PhosphorIcon(PhosphorIcons.shareNetwork()),
                onPressed: _busy ? null : _shareImage,
              ),
              const SizedBox(height: LumSpace.sm),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: LumSpace.sm,
                children: [
                  _QuietAction(
                    icon: PhosphorIcons.downloadSimple(),
                    label: NotesStrings.saveImage,
                    onTap: _busy ? null : _saveImage,
                  ),
                  _QuietAction(
                    icon: PhosphorIcons.copy(),
                    label: NotesStrings.copyText,
                    onTap: _copyText,
                  ),
                  _QuietAction(
                    icon: PhosphorIcons.textT(),
                    label: NotesStrings.shareTextAction,
                    onTap: _busy ? null : _shareText,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

/// A small caption over a wrap of chips. Also used for the stanza picker.
class ShareOptionGroup extends StatelessWidget {
  const ShareOptionGroup({
    super.key,
    required this.label,
    required this.children,
  });

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => _OptionGroup(
        label: label,
        children: children,
      );
}

class _OptionGroup extends StatelessWidget {
  const _OptionGroup({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(label,
              style:
                  LumText.footnoteEmphasized.copyWith(color: c.textSecondary)),
        ),
        const SizedBox(height: LumSpace.sm),
        Wrap(
            spacing: LumSpace.sm, runSpacing: LumSpace.sm, children: children),
      ],
    );
  }
}

/// Icon + label text action, a full 48pt touch target.
class _QuietAction extends StatelessWidget {
  const _QuietAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: LumSpace.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: LumSize.iconSm, color: c.textPrimary),
                  const SizedBox(width: LumSpace.xs),
                  Text(label,
                      style: LumText.subheadlineEmphasized
                          .copyWith(color: c.textPrimary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
