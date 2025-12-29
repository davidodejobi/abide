import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/hymns_viewmodel.dart';
import '../widgets/hymn_card.dart';
import 'hymn_detail_page.dart';

class HymnListPage extends ConsumerWidget {
  const HymnListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hymnsAsync = ref.watch(hymnsViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Baptist Hymnal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              // Toggle language for demo
              // Simplified toggle logic
              // current.changeLanguage('yo');
            },
          ),
        ],
      ),
      body: hymnsAsync.when(
        data: (hymns) => ListView.builder(
          itemCount: hymns.length,
          itemBuilder: (context, index) {
            final item = hymns[index];
            return HymnCard(
              hymn: item['hymn'],
              translation: item['translation'],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HymnDetailPage(hymnId: item['hymn'].id),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
