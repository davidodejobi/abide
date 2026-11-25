import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/core/widgets/lum_chip.dart';
import 'package:openbaptisthymnal/features/hymn/model/lyrics.dart';
import 'package:openbaptisthymnal/features/share_card/ui/share_card_composer.dart';
import 'package:openbaptisthymnal/features/share_card/ui/widgets/lyric_card.dart';
import 'package:openbaptisthymnal/features/tablet/ui/notes_strings.dart';

/// One shareable part of a hymn: a stanza or the chorus.
typedef SharePart = ({String label, String text});

/// Stanzas and chorus in singing order (chorus after verse 1). A blank chorus
/// is skipped.
List<SharePart> shareParts(Lyrics lyrics) {
  final chorus = lyrics.chorus;
  final hasChorus = chorus != null && chorus.trim().isNotEmpty;
  return [
    for (final (i, st) in lyrics.stanzas.indexed) ...[
      (label: NotesStrings.stanzaLabel(i + 1), text: st.text),
      if (i == 0 && hasChorus) (label: NotesStrings.chorusLabel, text: chorus),
    ],
  ];
}

/// Composer screen for sharing a hymn lyric card as an image.
@RoutePage()
class ShareCardPage extends StatefulWidget {
  const ShareCardPage({
    super.key,
    required this.hymnNumber,
    required this.title,
    this.body = '',
    this.parts = const [],
  });

  final String hymnNumber;
  final String title;

  /// The text the reader opened the composer from; pre-selects its part. Empty
  /// means the whole hymn: every part is preselected.
  final String body;

  /// Every stanza and the chorus, in singing order, for the part chips.
  final List<SharePart> parts;

  @override
  State<ShareCardPage> createState() => _ShareCardPageState();
}

class _ShareCardPageState extends State<ShareCardPage> {
  late final List<SharePart> _parts;
  late final Set<int> _selected;

  @override
  void initState() {
    super.initState();
    final body = widget.body.trim();
    final at = widget.parts.indexWhere((p) => p.text.trim() == body);
    if (body.isEmpty || at >= 0) {
      _parts = widget.parts;
      _selected =
          body.isEmpty ? {for (var i = 0; i < _parts.length; i++) i} : {at};
    } else {
      // A highlighted selection is not a whole part, so it gets its own chip.
      _parts = [
        (label: NotesStrings.selectionLabel, text: body),
        ...widget.parts
      ];
      _selected = {0};
    }
  }

  String get _body => [
        for (var i = 0; i < _parts.length; i++)
          if (_selected.contains(i)) _parts[i].text.trim(),
      ].join('\n\n');

  void _toggle(int i) => setState(() {
        // Keep at least one part so the card is never empty.
        if (_selected.contains(i)) {
          if (_selected.length > 1) _selected.remove(i);
        } else {
          _selected.add(i);
        }
      });

  @override
  Widget build(BuildContext context) {
    final number = widget.hymnNumber;
    return ShareCardComposer(
      title: NotesStrings.shareHymn,
      filename: 'abide_hymn_$number',
      options: _parts.length < 2
          ? null
          : ShareOptionGroup(
              label: NotesStrings.includeLabel,
              children: [
                for (var i = 0; i < _parts.length; i++)
                  LumChip(
                    label: _parts[i].label,
                    selected: _selected.contains(i),
                    onTap: () => _toggle(i),
                  ),
              ],
            ),
      cardBuilder: (style, format, showReference) => LyricCard(
        hymnNumber: number,
        title: widget.title,
        body: _body,
        style: style,
        format: format,
        showReference: showReference,
      ),
      textBuilder: (showReference) => [
        widget.title,
        _body,
        if (showReference) NotesStrings.hymnEyebrow(number),
      ].join('\n\n'),
    );
  }
}
