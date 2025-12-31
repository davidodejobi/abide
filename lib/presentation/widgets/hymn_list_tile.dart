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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: AppColors.secondary50,
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
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  number.padLeft(3, '0'),
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
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
                  color: AppColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Arrow icon
            const Icon(
              Icons.chevron_right,
              size: 24,
              color: AppColors.primary,
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
