import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/features/share_card/ui/share_card_composer.dart';
import 'package:openbaptisthymnal/features/share_card/ui/widgets/scripture_card.dart';

/// Composer screen for sharing selected Bible verses as an image.
@RoutePage()
class ScriptureShareCardPage extends StatelessWidget {
  const ScriptureShareCardPage({
    super.key,
    required this.reference,
    required this.body,
  });

  /// Full citation, e.g. `John 3:16–18`.
  final String reference;

  /// The selected verse text, already joined.
  final String body;

  @override
  Widget build(BuildContext context) {
    return ShareCardComposer(
      filename: 'abide_${_slug(reference)}',
      cardBuilder: (style) => ScriptureCard(
        reference: reference,
        body: body,
        style: style,
      ),
    );
  }

  static String _slug(String reference) {
    final cleaned = reference
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return cleaned.isEmpty ? 'scripture' : cleaned;
  }
}
