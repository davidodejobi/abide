import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/hymns_viewmodel.dart';
import '../widgets/hymn_stanza.dart';

@RoutePage()
class HymnDetailPage extends ConsumerWidget {
  final String hymnId;

  const HymnDetailPage({super.key, required this.hymnId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(hymnDetailProvider(hymnId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hymn Detail'),
      ),
      body: detailAsync.when(
        data: (data) {
          final translations = data['translations'] as Map;
          if (translations.isEmpty) {
            return const Center(child: Text('No translation found'));
          }

          final firstTranslation = translations.values.first;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstTranslation.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                ...firstTranslation.lyrics.stanzas.asMap().entries.map((entry) {
                  return HymnStanza(number: entry.key + 1, text: entry.value);
                }),
                if (firstTranslation.lyrics.chorus != null)
                  HymnStanza(
                      number: 0,
                      text: firstTranslation.lyrics.chorus!,
                      isChorus: true),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
