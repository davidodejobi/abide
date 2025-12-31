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
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          const Icon(
            Icons.search,
            size: 32,
            color: AppColors.neutral500,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.neutral800,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.neutral300,
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
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.tune,
                size: 24,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
