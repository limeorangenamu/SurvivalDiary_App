import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/section_header.dart';
import '../auth/auth_session.dart';
import '../diary/data/expense_api_client.dart';
import 'data/home_api_client.dart';

class DailySummaryPage extends StatefulWidget {
  const DailySummaryPage({super.key});

  @override
  State<DailySummaryPage> createState() => _DailySummaryPageState();
}

class _DailySummaryPageState extends State<DailySummaryPage> {
  final _homeApiClient = HomeApiClient();
  final _expenseApiClient = ExpenseApiClient();

  late Future<void> _loadFuture;
  BudgetSummary? _budget;
  List<Expense> _todayExpenses = [];

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<void> _load() async {
    final token = AuthSession.instance.accessToken;
    if (token == null) {
      throw const HomeApiException('오늘의 요약을 확인하려면 로그인이 필요해요.');
    }

    final results = await Future.wait<Object>([
      _homeApiClient.getSummary(accessToken: token),
      _expenseApiClient.getExpenses(accessToken: token),
    ]);
    final now = DateTime.now();
    _budget = results[0] as BudgetSummary;
    _todayExpenses = (results[1] as List<Expense>)
        .where((expense) => _isSameDay(expense.date.toLocal(), now))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _refresh() async {
    setState(() => _loadFuture = _load());
    await _loadFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('오늘의 요약')),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || _budget == null) {
            return EmptyStateView(
              icon: Icons.receipt_long_rounded,
              title: '오늘의 요약을 불러오지 못했어요',
              description: snapshot.error.toString(),
              actionLabel: '다시 불러오기',
              onAction: _refresh,
            );
          }
          return _SummaryContent(
            budget: _budget!,
            expenses: _todayExpenses,
            onRefresh: _refresh,
          );
        },
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({
    required this.budget,
    required this.expenses,
    required this.onRefresh,
  });

  final BudgetSummary budget;
  final List<Expense> expenses;
  final Future<void> Function() onRefresh;

  int get _score {
    if (budget.dailyLimit <= 0) return 0;
    return ((budget.remainingToday / budget.dailyLimit) * 100)
        .round()
        .clamp(0, 100)
        .toInt();
  }

  String get _scoreDescription {
    if (budget.dailyLimit <= 0) {
      return '예산을 설정하면 오늘의 점수를 확인할 수 있어요';
    }
    if (budget.spentToday > budget.dailyLimit) {
      return '계획보다 ${Formatters.amount(budget.spentToday - budget.dailyLimit)} 더 사용했어요';
    }
    return '오늘 예산이 ${Formatters.amount(budget.remainingToday)} 남았어요';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                      '$_score점',
                      style: AppTextStyles.display.copyWith(
                        color: AppColors.primaryDeep,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          _scoreDescription,
                          style: AppTextStyles.caption,
                        ),
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
          if (expenses.isEmpty)
            const AppCard(
              child: Text(
                '오늘 등록된 지출이 없어요.',
                style: AppTextStyles.bodyMuted,
                textAlign: TextAlign.center,
              ),
            )
          else
            for (final expense in expenses)
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

bool _isSameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
