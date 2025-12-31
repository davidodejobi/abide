import 'package:flutter/material.dart';

import '../../utils/theme/theme.dart';

class SearchBarWidget extends StatelessWidget {
  final String hintText;
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const SearchBarWidget({
    super.key,
    this.hintText = 'Search hymn...',
    this.onFilterTap,
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          Icon(
            Icons.search,
            size: 32,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTextStyles.bodyLarge.copyWith(
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: colorScheme.outline,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.tune,
                size: 24,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
