import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_header.dart';

class DailySummaryPage extends StatelessWidget {
  const DailySummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    const budget = MockData.budget;
    return Scaffold(
      appBar: AppBar(title: const Text('오늘의 요약')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          AppCard(
            color: AppColors.primarySoft,
            borderColor: AppColors.primarySoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('오늘의 생존 점수', style: AppTextStyles.bodyMuted),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '82점',
                      style: AppTextStyles.display.copyWith(
                        color: AppColors.primaryDeep,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 5),
                      child: Text(
                        '계획보다 7,000원 절약했어요',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: '오늘 지출 내역'),
          const SizedBox(height: 10),
          for (final expense in MockData.expenses.where(
            (item) => item.date.day == 27,
          ))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExpenseRow(expense: expense),
            ),
          const SizedBox(height: 12),
          AppCard(
            child: Row(
              children: [
                const Expanded(
                  child: Text('오늘 남은 예산', style: AppTextStyles.bodyMuted),
                ),
                Text(
                  Formatters.amount(budget.remainingToday),
                  style: AppTextStyles.amount.copyWith(
                    color: AppColors.primaryDeep,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: expense.category.color.withValues(alpha: 0.13),
            foregroundColor: expense.category.color,
            child: Icon(expense.category.icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.title, style: AppTextStyles.body),
                Text(expense.category.label, style: AppTextStyles.captionTiny),
              ],
            ),
          ),
          Text(
            '-${Formatters.amount(expense.amount)}',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
