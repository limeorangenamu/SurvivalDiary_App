import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../place_expense_summary.dart';

class PlaceSpendingSummary extends StatelessWidget {
  const PlaceSpendingSummary({
    super.key,
    required this.summary,
    required this.accentColor,
    this.compact = false,
  });

  final PlaceExpenseSummary summary;
  final Color accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        key: const ValueKey('place-spending-summary-compact'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.credit_card_rounded, size: 15, color: accentColor),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                '여기서 총 ${Formatters.amount(summary.totalAmount)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${summary.paymentCount}회',
              style: AppTextStyles.captionTiny.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      key: const ValueKey('place-spending-summary'),
      color: accentColor.withValues(alpha: 0.08),
      borderColor: accentColor.withValues(alpha: 0.24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card_rounded, color: accentColor, size: 20),
              const SizedBox(width: 7),
              const Text('내 카드 사용', style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.amount(summary.totalAmount),
            style: AppTextStyles.amount.copyWith(
              color: accentColor,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '총 ${summary.paymentCount}회 · 최근 '
            '${Formatters.shortDate(summary.latestDate)} '
            '${Formatters.amount(summary.latestAmount)}',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
