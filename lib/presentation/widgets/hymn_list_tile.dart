import 'package:flutter/material.dart';

import '../../utils/theme/theme.dart';

class HymnListTile extends StatelessWidget {
  final String number;
  final String title;
  final VoidCallback? onTap;

  const HymnListTile({
    super.key,
    required this.number,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(33),
          child: Ink(
            height: 65,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(33),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                // Hymn number badge
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      number.padLeft(3, '0'),
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 22),
                // Hymn title
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Arrow icon
                Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
