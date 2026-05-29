import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:openbaptisthymnal/core/theme/app_colors.dart';
import 'package:openbaptisthymnal/core/theme/app_text_styles.dart';
import 'package:openbaptisthymnal/core/utils/services/share_service.dart';
import 'package:openbaptisthymnal/core/utils/toast_helper.dart';
import 'package:openbaptisthymnal/features/share_card/ui/share_card_style.dart';
import 'package:openbaptisthymnal/features/share_card/ui/widgets/lyric_card.dart';

/// Composer screen that previews a lyric card, lets the user pick a style
/// preset, then captures the card as a PNG and shares it.
@RoutePage()
class ShareCardPage extends StatefulWidget {
  const ShareCardPage({
    super.key,
    required this.hymnNumber,
    required this.title,
    required this.body,
  });

  final String hymnNumber;
  final String title;
  final String body;

  @override
  State<ShareCardPage> createState() => _ShareCardPageState();
}

class _ShareCardPageState extends State<ShareCardPage> {
  final _cardKey = GlobalKey();
  late ShareCardStyle _style = ShareCardStyle.presets.first;
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
        filename: 'abide_hymn_${widget.hymnNumber}',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (mounted) ToastHelper.error(context, 'Could not create image to share');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<Uint8List> _capture() async {
    final boundary =
        _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.neutral900 : AppColors.neutral100;
    final ink = isDark ? AppColors.neutral100 : AppColors.primaryDark;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AutoLeadingButton(),
        title: Text('Share', style: AppTextStyles.titleLarge.copyWith(color: ink)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: LyricCard(
                      hymnNumber: widget.hymnNumber,
                      title: widget.title,
                      body: widget.body,
                      style: _style,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: ShareCardStyle.presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final preset = ShareCardStyle.presets[index];
                final selected = preset.id == _style.id;
                return GestureDetector(
                  onTap: () => setState(() => _style = preset),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: preset.gradient,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? AppColors.secondary : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _sharing ? null : _share,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _sharing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.neutral100,
                        ),
                      )
                    : Text(
                        'Share image',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.neutral100,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
