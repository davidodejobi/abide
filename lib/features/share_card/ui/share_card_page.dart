import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/features/share_card/ui/share_card_composer.dart';
import 'package:openbaptisthymnal/features/share_card/ui/widgets/lyric_card.dart';

/// Composer screen for sharing a hymn lyric card as an image.
@RoutePage()
class ShareCardPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ShareCardComposer(
      filename: 'abide_hymn_$hymnNumber',
      cardBuilder: (style) => LyricCard(
        hymnNumber: hymnNumber,
        title: title,
        body: body,
        style: style,
      ),
    );
  }
}
