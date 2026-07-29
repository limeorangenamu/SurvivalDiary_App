import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';

class DetectedExpensePage extends StatelessWidget {
  const DetectedExpensePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('감지된 결제')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        itemCount: MockData.detectedExpenses.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = MockData.detectedExpenses[index];
          return _DetectedListCard(item: item);
        },
      ),
    );
  }
}

class _DetectedListCard extends StatelessWidget {
  const _DetectedListCard({required this.item});

  final DetectedExpense item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.category.icon, color: item.category.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(item.merchant, style: AppTextStyles.sectionTitle),
              ),
              Text(Formatters.amount(item.amount), style: AppTextStyles.amount),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '${item.detectedTime} · ${item.source}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('이 결제는 제외했어요.'))),
                  child: const Text('제외'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('지출 일기에 추가했어요.')),
                  ),
                  child: const Text('추가'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
