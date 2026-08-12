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

enum SummaryMode { today, monthlyCategory }

class DailySummaryPage extends StatefulWidget {
  const DailySummaryPage({super.key, this.mode = SummaryMode.today});
  final SummaryMode mode;

  @override
  State<DailySummaryPage> createState() => _DailySummaryPageState();
}

class _DailySummaryPageState extends State<DailySummaryPage> {
  final _home = HomeApiClient();
  final _expensesApi = ExpenseApiClient();
  late Future<void> _future;
  BudgetSummary? _budget;
  List<Expense> _expenses = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _load() async {
    final token = AuthSession.instance.accessToken;
    if (token == null) throw const HomeApiException('로그인이 필요해요.');
    final result = await Future.wait<Object>([
      _home.getSummary(accessToken: token),
      _expensesApi.getExpenses(accessToken: token),
    ]);
    _budget = result[0] as BudgetSummary;
    _expenses = (result[1] as List<Expense>).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(
                widget.mode == SummaryMode.today ? '오늘의 요약' : '월간 카테고리 지출')),
        body: FutureBuilder<void>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError || _budget == null) {
              return EmptyStateView(
                  icon: Icons.receipt_long_rounded,
                  title: '요약을 불러오지 못했어요',
                  description: snapshot.error.toString(),
                  actionLabel: '다시 불러오기',
                  onAction: _refresh);
            }
            return _SummaryBody(
                mode: widget.mode,
                budget: _budget!,
                expenses: _expenses,
                onRefresh: _refresh);
          },
        ),
      );
}

class _SummaryBody extends StatelessWidget {
  const _SummaryBody(
      {required this.mode,
      required this.budget,
      required this.expenses,
      required this.onRefresh});
  final SummaryMode mode;
  final BudgetSummary budget;
  final List<Expense> expenses;
  final Future<void> Function() onRefresh;

  bool get monthly => mode == SummaryMode.monthlyCategory;
  List<Expense> get todayExpenses {
    final now = DateTime.now();
    return expenses.where((e) {
      final d = e.date.toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
  }

  List<Expense> get monthExpenses {
    final now = DateTime.now();
    return expenses.where((e) {
      final d = e.date.toLocal();
      return d.year == now.year && d.month == now.month;
    }).toList();
  }

  int get dailyScore => _score(budget.spentToday, budget.dailyLimit);
  int get monthlyScore => _score(budget.monthlySpent, budget.monthlyBudget);
  int _score(int spent, int limit) {
    if (limit <= 0) return 0;
    final usage = spent / limit;
    return (usage <= 1 ? 50 + (1 - usage) * 50 : 50 - (usage - 1) * 50)
        .round()
        .clamp(0, 100)
        .toInt();
  }

  List<_Rank> get ranks {
    final grouped = <ExpenseCategory, _Rank>{};
    for (final e in monthExpenses) {
      final old = grouped[e.category];
      grouped[e.category] = _Rank(
          e.category, (old?.amount ?? 0) + e.amount, (old?.count ?? 0) + 1);
    }
    final list = grouped.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final visible = monthly ? monthExpenses : todayExpenses;
    final total = visible.fold(0, (sum, e) => sum + e.amount);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _ScoreCard(
              score: monthly ? monthlyScore : dailyScore,
              title: monthly ? '월간 생존 점수' : '오늘의 생존 점수'),
          const SizedBox(height: 18),
          AppCard(
              child: Row(children: [
            Expanded(
                child: Text(monthly ? '월간 잔여 예산' : '오늘 남은 예산',
                    style: AppTextStyles.bodyMuted)),
            Text(
                Formatters.amount(monthly
                    ? (budget.monthlyBudget - budget.monthlySpent)
                        .clamp(0, 1 << 31)
                    : budget.remainingToday),
                style: AppTextStyles.amount
                    .copyWith(color: AppColors.primaryDeep)),
          ])),
          if (monthly) ...[
            const SizedBox(height: 22),
            const SectionHeader(title: '월간 카테고리 지출 순위'),
            const SizedBox(height: 10),
            _RankCard(title: '지출 금액 기준 순위', ranks: ranks, byCount: false),
            const SizedBox(height: 10),
            _RankCard(title: '지출 횟수 기준 순위', ranks: ranks, byCount: true),
          ],
          const SizedBox(height: 22),
          if (monthly)
            AppCard(
                child: Row(children: [
              const Expanded(
                  child: Text('월간 총 지출 금액', style: AppTextStyles.bodyMuted)),
              Text(Formatters.amount(total),
                  style: AppTextStyles.amount
                      .copyWith(color: AppColors.primaryDeep))
            ]))
          else ...[
            const SectionHeader(title: '오늘의 지출 내역'),
            const SizedBox(height: 10),
            if (visible.isEmpty)
              const AppCard(
                  child: Text('지출 내역이 없어요',
                      style: AppTextStyles.bodyMuted,
                      textAlign: TextAlign.center)),
            for (final expense in visible)
              Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ExpenseRow(expense: expense)),
            const SizedBox(height: 8),
            AppCard(
                child: Row(children: [
              const Expanded(
                  child: Text('오늘 총 지출', style: AppTextStyles.bodyMuted)),
              Text(Formatters.amount(total),
                  style: AppTextStyles.amount
                      .copyWith(color: AppColors.primaryDeep))
            ])),
          ],
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score, required this.title});
  final int score;
  final String title;
  @override
  Widget build(BuildContext context) => AppCard(
      color: AppColors.primarySoft,
      borderColor: AppColors.primarySoft,
      child: Row(children: [
        Expanded(child: Text(title, style: AppTextStyles.bodyMuted)),
        Text('$score점',
            style: AppTextStyles.display.copyWith(color: AppColors.primaryDeep))
      ]));
}

class _Rank {
  const _Rank(this.category, this.amount, this.count);
  final ExpenseCategory category;
  final int amount;
  final int count;
}

class _RankCard extends StatelessWidget {
  const _RankCard(
      {required this.title, required this.ranks, required this.byCount});
  final String title;
  final List<_Rank> ranks;
  final bool byCount;
  @override
  Widget build(BuildContext context) {
    final ordered = [...ranks]..sort((a, b) =>
        byCount ? b.count.compareTo(a.count) : b.amount.compareTo(a.amount));
    return AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTextStyles.bodyMuted),
      const SizedBox(height: 8),
      if (ordered.isEmpty)
        const Text('이번 달 지출 내역이 없어요', style: AppTextStyles.bodyMuted),
      for (var i = 0; i < ordered.length; i++)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              Text('${i + 1}', style: AppTextStyles.sectionTitle),
              const SizedBox(width: 12),
              Icon(ordered[i].category.icon, color: ordered[i].category.color),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(ordered[i].category.label,
                      style: AppTextStyles.body)),
              Text(
                  byCount
                      ? '${ordered[i].count}회'
                      : Formatters.amount(ordered[i].amount),
                  style:
                      AppTextStyles.body.copyWith(fontWeight: FontWeight.w700))
            ]))
    ]));
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense});
  final Expense expense;
  @override
  Widget build(BuildContext context) => AppCard(
          child: Row(children: [
        CircleAvatar(
            backgroundColor: expense.category.color.withValues(alpha: .13),
            foregroundColor: expense.category.color,
            child: Icon(expense.category.icon, size: 20)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(expense.title, style: AppTextStyles.body),
          Text(expense.category.label, style: AppTextStyles.captionTiny)
        ])),
        Text('-${Formatters.amount(expense.amount)}',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700))
      ]));
}
