import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_header.dart';
import 'widgets/monthly_compare_chart.dart';
import 'widgets/trend_line_chart.dart';

class ExpenseStatsPage extends StatefulWidget {
  const ExpenseStatsPage({super.key});

  @override
  State<ExpenseStatsPage> createState() => _ExpenseStatsPageState();
}

class _ExpenseStatsPageState extends State<ExpenseStatsPage> {
  DateTime _visibleMonth = DateTime(2026, 7);

  void _moveMonth(int offset) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + offset,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = MockData.categoryStats.fold<int>(
      0,
      (sum, item) => sum + item.amount,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('지출 통계')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: '이전 달',
                onPressed: () => _moveMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              SizedBox(
                width: 118,
                child: Text(
                  '${_visibleMonth.year}년 ${_visibleMonth.month}월',
                  style: AppTextStyles.sectionTitle,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                tooltip: '다음 달',
                onPressed: () => _moveMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('이번 달 총 지출', style: AppTextStyles.bodyMuted),
                const SizedBox(height: 6),
                Text(Formatters.amount(total), style: AppTextStyles.display),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.arrow_upward_rounded,
                      size: 16,
                      color: AppColors.danger,
                    ),
                    Text(
                      '지난달보다 7.8% 늘었어요',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const TrendLineChart(values: MockData.trendValues),
                const Center(
                  child: Text('최근 7일 지출 흐름', style: AppTextStyles.captionTiny),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: '카테고리별 지출'),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              children: [
                for (var index = 0;
                    index < MockData.categoryStats.length;
                    index++) ...[
                  _CategoryStatRow(item: MockData.categoryStats[index]),
                  if (index != MockData.categoryStats.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(
            title: '지난달과 비교',
            subtitle: '회색은 지난달, 초록색은 이번 달이에요.',
          ),
          const SizedBox(height: 10),
          const AppCard(
            child: MonthlyCompareChart(items: MockData.monthlyCompare),
          ),
        ],
      ),
    );
  }
}

class _CategoryStatRow extends StatelessWidget {
  const _CategoryStatRow({required this.item});

  final CategoryStat item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: item.category.color.withValues(alpha: 0.12),
          foregroundColor: item.category.color,
          child: Icon(item.category.icon, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.category.label,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    Formatters.amount(item.amount),
                    style: AppTextStyles.body,
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: item.ratio,
                  color: item.category.color,
                  backgroundColor: AppColors.surfaceAlt,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 36,
          child: Text(
            Formatters.percent(item.ratio),
            style: AppTextStyles.caption,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
