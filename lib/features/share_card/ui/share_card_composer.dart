import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
/// look and shape, then captures it as a PNG and hands it to [ShareService].
///
/// The card is supplied by [cardBuilder] so hymns and scripture share this
/// chrome while rendering different content.
class ShareCardComposer extends StatefulWidget {
  const ShareCardComposer({
    super.key,
    required this.title,
    required this.filename,
    required this.cardBuilder,
  });

  /// Page title, e.g. "Share verse".
  final String title;

  /// Base name for the exported PNG (no extension).
  final String filename;

  /// Builds the card body for the chosen look and shape.
  final Widget Function(ShareCardStyle style, ShareCardFormat format)
      cardBuilder;

  @override
  State<ShareCardComposer> createState() => _ShareCardComposerState();
}

class _ShareCardComposerState extends State<ShareCardComposer> {
  final _cardKey = GlobalKey();
  late ShareCardStyle _style = ShareCardStyle.presets.first;
  ShareCardFormat _format = ShareCardFormat.status;
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin =
          box != null ? box.localToGlobal(Offset.zero) & box.size : null;
      final bytes = await _capture();
      await ShareService().shareImage(
        imageBytes: bytes,
        filename: widget.filename,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (mounted) ToastHelper.error(context, NotesStrings.shareError);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(LumSize.screenGutter,
                LumSpace.md, LumSize.screenGutter, LumSpace.xl),
            children: [
              Row(
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
                        style: LumText.headline.copyWith(color: c.textPrimary),
                      ),
                    ),
                  ),
                  // Balances the back button so the title stays centred.
                  const SizedBox(width: LumSize.glassButton),
                ],
              ),
              const SizedBox(height: LumSpace.xl),
              Center(
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
                          child: widget.cardBuilder(_style, _format),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: LumSpace.xl),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: LumSpace.sm,
                runSpacing: LumSpace.sm,
                children: [
                  for (final preset in ShareCardStyle.presets)
                    LumChip(
                      label: preset.label,
                      selected: preset.id == _style.id,
                      onTap: () => setState(() => _style = preset),
                    ),
                ],
              ),
              const SizedBox(height: LumSpace.sm),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: LumSpace.sm,
                runSpacing: LumSpace.sm,
                children: [
                  for (final f in ShareCardFormat.values)
                    LumChip(
                      label: f.label,
                      selected: f == _format,
                      onTap: () => setState(() => _format = f),
                    ),
                ],
              ),
              const SizedBox(height: LumSpace.xl),
              LumButton(
                label: NotesStrings.shareImage,
                onPressed: _sharing ? null : _share,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
