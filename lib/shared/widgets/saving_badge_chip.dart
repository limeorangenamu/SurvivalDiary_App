import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models.dart';

class SavingBadgeChip extends StatelessWidget {
  const SavingBadgeChip({
    super.key,
    required this.badge,
    this.compact = false,
  });

  final SavingBadge badge;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: badge.message,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge.emoji, style: TextStyle(fontSize: compact ? 12 : 14)),
            const SizedBox(width: 3),
            Text(
              badge.label,
              style: AppTextStyles.captionTiny.copyWith(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
