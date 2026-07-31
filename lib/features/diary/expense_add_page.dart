import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_header.dart';
import 'expense_stats_page.dart';
import 'widgets/expense_form.dart';

class ExpenseAddPage extends StatefulWidget {
  const ExpenseAddPage({super.key});

  @override
  State<ExpenseAddPage> createState() => _ExpenseAddPageState();
}

class _ExpenseAddPageState extends State<ExpenseAddPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _statsRevision = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshStats() {
    setState(() => _statsRevision++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('지출 일기'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primaryDeep,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: '지출 통계'),
            Tab(text: '자동 등록'),
            Tab(text: '직접 입력'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ExpenseStatsView(key: ValueKey(_statsRevision)),
          const _DetectedExpenseTab(),
          _DirectExpenseTab(onExpenseSaved: _refreshStats),
        ],
      ),
    );
  }
}

class _DetectedExpenseTab extends StatelessWidget {
  const _DetectedExpenseTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('detected-tab-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        SectionHeader(
          title: '결제 알림에서 찾았어요',
          subtitle: '확인한 지출만 일기에 추가돼요.',
          actionLabel: '전체 보기',
          onAction: () =>
              Navigator.pushNamed(context, AppRoutes.detectedExpenses),
        ),
        const SizedBox(height: 10),
        for (final item in MockData.detectedExpenses.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DetectedExpenseCard(item: item),
          ),
      ],
    );
  }
}

class _DirectExpenseTab extends StatelessWidget {
  const _DirectExpenseTab({required this.onExpenseSaved});

  final VoidCallback onExpenseSaved;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('direct-tab-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        ExpenseForm(
          showTitle: false,
          onSaved: onExpenseSaved,
        ),
      ],
    );
  }
}

class _DetectedExpenseCard extends StatelessWidget {
  const _DetectedExpenseCard({required this.item});

  final DetectedExpense item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: item.category.color.withValues(alpha: 0.12),
            foregroundColor: item.category.color,
            child: Icon(item.category.icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.merchant,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.detectedTime} · ${item.source}',
                  style: AppTextStyles.captionTiny,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.amount(item.amount),
                  style: AppTextStyles.amount,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 38,
                child: OutlinedButton(
                  key: ValueKey('edit-detected-${item.id}'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 38),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  onPressed: () {},
                  child: Text(
                    '수정',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 48,
                height: 38,
                child: FilledButton(
                  key: ValueKey('add-detected-${item.id}'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 38),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.merchant} 지출을 추가했어요.')),
                  ),
                  child: Text(
                    '추가',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
