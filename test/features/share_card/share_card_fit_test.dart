import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/features/share_card/ui/share_card_style.dart';
import 'package:openbaptisthymnal/features/share_card/ui/widgets/lyric_card.dart';
import 'package:openbaptisthymnal/features/share_card/ui/widgets/scripture_card.dart';

import 'package:openbaptisthymnal/features/share_card/ui/share_text_fit.dart';

import '../../support/reader_harness.dart' show setView, settle;

const _john = [
  (
    number: 16,
    text: 'For God so loved the world, that he gave his only begotten Son, '
        'that whosoever believeth in him should not perish, but have '
        'everlasting life.'
  ),
  (
    number: 17,
    text: 'For God sent not his Son into the world to condemn the world; '
        'but that the world through him might be saved.'
  ),
  (
    number: 18,
    text: 'He that believeth on him is not condemned: but he that believeth '
        'not is condemned already, because he hath not believed in the name '
        'of the only begotten Son of God.'
  ),
];

const _stanza = 'Holy, holy, holy! Lord God Almighty!\n'
    'Early in the morning our song shall rise to Thee;\n'
    'Holy, holy, holy, merciful and mighty!\n'
    'God in three Persons, blessed Trinity!';

/// Pumps [card] in a 300 wide slot and returns the card's words paragraph.
Future<RenderParagraph> _words(WidgetTester t, Widget card) async {
  setView(t, const Size(390, 844));
  await t.pumpWidget(MaterialApp(
    home: Scaffold(body: Center(child: SizedBox(width: 300, child: card))),
  ));
  await settle(t);
  // The words are the paragraph that fills the panel: the tallest one.
  final paragraphs = t
      .renderObjectList<RenderParagraph>(find.byType(RichText))
      .toList()
    ..sort((a, b) => b.size.height.compareTo(a.size.height));
  return paragraphs.first;
}

/// The suite renders in Ahem; the real faces are wider or narrower, and the fit
/// is about their metrics, so load the two the cards use.
Future<void> _loadFonts() async {
  for (final (family, file) in const [
    ('Inter', 'Inter-Regular'),
    ('GentiumBookPlus', 'GentiumBookPlus-Regular'),
  ]) {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(
          File('assets/fonts/$file.ttf').readAsBytesSync())));
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);
  final style = ShareCardStyle.presets.first; // Day road, the road to give up.

  for (final format in ShareCardFormat.values) {
    testWidgets('John 3:16-18 fits whole on a ${format.name} card', (t) async {
      final p = await _words(
          t,
          ScriptureCard(
              reference: 'John 3:16-18',
              verses: _john,
              style: style,
              format: format));
      expect(t.takeException(), isNull);
      // Nothing is cut: every line is laid out and nothing is ellipsised.
      expect(p.didExceedMaxLines, isFalse);
      expect(p.getMinIntrinsicHeight(p.size.width),
          lessThanOrEqualTo(p.size.height + 0.5));
    });

    testWidgets('a 4 line stanza shows every line on a ${format.name} card',
        (t) async {
      final p = await _words(
          t,
          LyricCard(
              hymnNumber: '1',
              title: 'Holy, Holy, Holy',
              body: _stanza,
              style: style,
              format: format));
      expect(t.takeException(), isNull);
      expect(p.didExceedMaxLines, isFalse);
      expect(p.getMinIntrinsicHeight(p.size.width),
          lessThanOrEqualTo(p.size.height + 0.5));
      // Four lyric lines plus the title: more than one line of text got drawn.
      expect(p.size.height, greaterThan(100));
    });
  }

  test('an overlong passage is capped with an ellipsis, not clipped', () {
    final fit = fitShareText(
      span: TextSpan(
        text: List.filled(80, 'a long line of scripture that keeps going')
            .join(' '),
        style: const TextStyle(fontFamily: 'GentiumBookPlus', fontSize: 20),
      ),
      textWidth: 252,
      cardHeight: 300,
      fullRoad: 114,
      chrome: 118,
    );
    expect(fit.roadFraction, 0);
    expect(fit.maxLines, isNotNull);
  });
}
