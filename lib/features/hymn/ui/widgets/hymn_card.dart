import 'package:flutter/material.dart';
import 'package:openbaptisthymnal/features/hymn/model/hymn.dart';
import 'package:openbaptisthymnal/features/hymn/model/language_pack.dart';

class HymnCard extends StatelessWidget {
  final Hymn hymn;
  final HymnTranslation translation;
  final VoidCallback onTap;

  const HymnCard({
    super.key,
    required this.hymn,
    required this.translation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(translation.title),
        subtitle: Text(hymn.category),
        onTap: onTap,
      ),
    );
  }
}
