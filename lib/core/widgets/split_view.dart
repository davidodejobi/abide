import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';
import 'package:openbaptisthymnal/features/hymn/ui/widgets/hymn_stanza.dart';

class SplitView extends StatelessWidget {
  final Map<String, HymnTranslation> translations;
  final List<String> languages;

  const SplitView({
    super.key,
    required this.translations,
    required this.languages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: languages.map((lang) {
        final t = translations[lang];
        if (t == null) return const Spacer();
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                ...t.lyrics.stanzas.map((stanza) {
                  return HymnStanza(number: stanza.index, text: stanza.text);
                }),
                if (t.lyrics.chorus != null)
                  HymnStanza(number: 0, text: t.lyrics.chorus!, isChorus: true),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
