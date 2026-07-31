import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/section_header.dart';
import '../auth/auth_session.dart';
import 'data/expense_api_client.dart';
import 'widgets/expense_list_sheet.dart';
import 'widgets/monthly_compare_chart.dart';
import 'widgets/trend_line_chart.dart';

enum _StatsPeriod { monthly, daily }

class ExpenseStatsPage extends StatelessWidget {
  const ExpenseStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('지출 통계')),
      body: const ExpenseStatsView(),
    );
  }
}

class ExpenseStatsView extends StatefulWidget {
  const ExpenseStatsView({super.key});

  @override
  State<ExpenseStatsView> createState() => _ExpenseStatsViewState();
}

class _ExpenseStatsViewState extends State<ExpenseStatsView> {
  final _expenseApiClient = ExpenseApiClient();
  late Future<void> _expensesFuture;
  List<Expense> _expenses = [];
  _StatsPeriod _period = _StatsPeriod.monthly;
  DateTime _visibleDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  @override
  void initState() {
    super.initState();
    _expensesFuture = _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final accessToken = AuthSession.instance.accessToken;
    if (accessToken == null) {
      throw const ExpenseApiException('지출 통계를 확인하려면 로그인이 필요해요.');
    }
    _expenses = await _expenseApiClient.getExpenses(
      accessToken: accessToken,
    );
  }

  void _reload() {
    setState(() => _expensesFuture = _loadExpenses());
  }

  Future<void> _deleteExpense(Expense expense) async {
    final accessToken = AuthSession.instance.accessToken;
    if (accessToken == null) {
      throw const ExpenseApiException('지출을 삭제하려면 로그인이 필요해요.');
    }
    await _expenseApiClient.deleteExpense(
      accessToken: accessToken,
      expenseId: expense.id,
    );
    if (mounted) {
      setState(() {
        _expenses = _expenses
            .where((item) => item.id != expense.id)
            .toList();
      });
    }
  }

  void _changePeriod(_StatsPeriod period) {
    if (period == _period) {
      return;
    }
    final now = DateTime.now();
    setState(() {
      _period = period;
      if (period == _StatsPeriod.daily) {
        final isCurrentMonth = _visibleDate.year == now.year &&
            _visibleDate.month == now.month;
        _visibleDate = isCurrentMonth
            ? DateTime(now.year, now.month, now.day)
            : DateTime(_visibleDate.year, _visibleDate.month + 1, 0);
      } else {
        _visibleDate = DateTime(_visibleDate.year, _visibleDate.month);
      }
    });
  }

  void _movePeriod(int offset) {
    final targetDate = _period == _StatsPeriod.daily
        ? _visibleDate.add(Duration(days: offset))
        : DateTime(_visibleDate.year, _visibleDate.month + offset);
    final now = DateTime.now();
    final limit = _period == _StatsPeriod.daily
        ? DateTime(now.year, now.month, now.day)
        : DateTime(now.year, now.month);
    if (targetDate.isAfter(limit)) {
      return;
    }
    setState(() => _visibleDate = targetDate);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _expensesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyStateView(
            icon: Icons.receipt_long_rounded,
            title: '지출 통계를 불러오지 못했어요',
            description: snapshot.error.toString(),
            actionLabel: '다시 불러오기',
            onAction: _reload,
          );
        }
        return _StatsContent(
          expenses: _expenses,
          period: _period,
          visibleDate: _visibleDate,
          onPeriodChanged: _changePeriod,
          onMovePeriod: _movePeriod,
          onDeleteExpense: _deleteExpense,
        );
      },
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({
    required this.expenses,
    required this.period,
    required this.visibleDate,
    required this.onPeriodChanged,
    required this.onMovePeriod,
    required this.onDeleteExpense,
  });

  final List<Expense> expenses;
  final _StatsPeriod period;
  final DateTime visibleDate;
  final ValueChanged<_StatsPeriod> onPeriodChanged;
  final ValueChanged<int> onMovePeriod;
  final Future<void> Function(Expense expense) onDeleteExpense;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final canMoveNext = period == _StatsPeriod.daily
        ? _dateOnly(visibleDate).isBefore(_dateOnly(now))
        : visibleDate.year < now.year ||
            (visibleDate.year == now.year && visibleDate.month < now.month);
    final currentExpenses = expenses
        .where((expense) => _isInPeriod(expense.date, visibleDate, period))
        .toList();
    final previousDate = period == _StatsPeriod.daily
        ? visibleDate.subtract(const Duration(days: 1))
        : DateTime(visibleDate.year, visibleDate.month - 1);
    final previousExpenses = expenses
        .where((expense) => _isInPeriod(expense.date, previousDate, period))
        .toList();
    final total = _totalAmount(currentExpenses);
    final previousTotal = _totalAmount(previousExpenses);
    final categoryStats = _categoryStats(currentExpenses, total);
    final monthlyCompare = _monthlyCompare(
      currentExpenses,
      previousExpenses,
    );
    final trend = _trendData(expenses, period);
    final comparison = _comparison(total, previousTotal, period);
    final hasComparisonData = monthlyCompare.any(
      (item) => item.previous > 0 || item.current > 0,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
      children: [
        _PeriodSelector(
          selectedPeriod: period,
          onChanged: onPeriodChanged,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: period == _StatsPeriod.daily ? '이전 날' : '이전 달',
              onPressed: () => onMovePeriod(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            SizedBox(
              width: 142,
              child: Text(
                _periodLabel(visibleDate, period),
                style: AppTextStyles.sectionTitle,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              tooltip: period == _StatsPeriod.daily ? '다음 날' : '다음 달',
              onPressed: canMoveNext ? () => onMovePeriod(1) : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await showExpenseListSheet(
                context: context,
                title: period == _StatsPeriod.daily
                    ? '${visibleDate.month}월 ${visibleDate.day}일 지출 목록'
                    : '${visibleDate.year}년 ${visibleDate.month}월 지출 목록',
                expenses: currentExpenses,
                onDelete: onDeleteExpense,
              );
            },
            icon: const Icon(Icons.receipt_long_rounded),
            label: Text('지출 목록 ${currentExpenses.length}건'),
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                period == _StatsPeriod.daily
                    ? '${visibleDate.month}월 ${visibleDate.day}일 총 지출'
                    : '${visibleDate.month}월 총 지출',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 6),
              Text(Formatters.amount(total), style: AppTextStyles.display),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    comparison.icon,
                    size: 16,
                    color: comparison.color,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      comparison.text,
                      style: AppTextStyles.caption.copyWith(
                        color: comparison.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TrendLineChart(
                values: trend.values,
                labels: trend.labels,
              ),
              Center(
                child: Text(
                  period == _StatsPeriod.daily
                      ? '오늘까지 최근 7일 지출 흐름'
                      : '현재 달까지 최근 7개월 지출 흐름',
                  style: AppTextStyles.captionTiny,
                ),
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
              for (var index = 0; index < categoryStats.length; index++) ...[
                _CategoryStatRow(item: categoryStats[index]),
                if (index != categoryStats.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: period == _StatsPeriod.daily ? '전날과 비교' : '지난달과 비교',
          subtitle: period == _StatsPeriod.daily
              ? '회색은 전날, 초록색은 선택한 날이에요.'
              : '회색은 지난달, 초록색은 선택한 달이에요.',
        ),
        const SizedBox(height: 10),
        AppCard(
          child: hasComparisonData
              ? MonthlyCompareChart(items: monthlyCompare)
              : const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      '비교할 지출 내역이 없어요.',
                      style: AppTextStyles.bodyMuted,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool _isInPeriod(
    DateTime expenseDate,
    DateTime visibleDate,
    _StatsPeriod period,
  ) {
    if (expenseDate.year != visibleDate.year ||
        expenseDate.month != visibleDate.month) {
      return false;
    }
    return period == _StatsPeriod.monthly ||
        expenseDate.day == visibleDate.day;
  }

  static String _periodLabel(DateTime date, _StatsPeriod period) {
    if (period == _StatsPeriod.daily) {
      return '${date.year}년 ${date.month}월 ${date.day}일';
    }
    return '${date.year}년 ${date.month}월';
  }

  static int _totalAmount(Iterable<Expense> items) =>
      items.fold(0, (sum, expense) => sum + expense.amount);

  static List<CategoryStat> _categoryStats(
    List<Expense> currentExpenses,
    int total,
  ) {
    return ExpenseCategory.values.map((category) {
      final amount = _totalAmount(
        currentExpenses.where((expense) => expense.category == category),
      );
      return CategoryStat(
        category: category,
        amount: amount,
        ratio: total == 0 ? 0.0 : amount / total,
      );
    }).toList();
  }

  static List<MonthlyCompare> _monthlyCompare(
    List<Expense> currentExpenses,
    List<Expense> previousExpenses,
  ) {
    return ExpenseCategory.values.map((category) {
      final current = _totalAmount(
        currentExpenses.where((expense) => expense.category == category),
      );
      final previous = _totalAmount(
        previousExpenses.where((expense) => expense.category == category),
      );
      return MonthlyCompare(
        label: category.label,
        previous: previous,
        current: current,
      );
    }).toList();
  }

  static ({List<double> values, List<String> labels}) _trendData(
    List<Expense> expenses,
    _StatsPeriod period,
  ) {
    final now = _dateOnly(DateTime.now());
    final dates = List.generate(7, (index) {
      final offset = index - 6;
      return period == _StatsPeriod.daily
          ? now.add(Duration(days: offset))
          : DateTime(now.year, now.month + offset);
    });
    final values = dates.map((date) {
      return _totalAmount(
        expenses.where(
          (expense) => period == _StatsPeriod.daily
              ? expense.date.year == date.year &&
                  expense.date.month == date.month &&
                  expense.date.day == date.day
              : expense.date.year == date.year &&
                  expense.date.month == date.month,
        ),
      ).toDouble();
    }).toList();
    final labels = dates.map((date) {
      return period == _StatsPeriod.daily
          ? Formatters.shortDate(date)
          : '${date.month}월';
    }).toList();
    return (values: values, labels: labels);
  }

  static ({String text, IconData icon, Color color}) _comparison(
    int current,
    int previous,
    _StatsPeriod period,
  ) {
    final previousLabel = period == _StatsPeriod.daily ? '어제' : '지난달';
    final equalComparison =
        period == _StatsPeriod.daily ? '어제와' : '지난달과';
    if (current == previous) {
      return (
        text: '$equalComparison 같은 금액을 사용했어요.',
        icon: Icons.remove_rounded,
        color: AppColors.textSecondary,
      );
    }
    if (previous == 0) {
      return (
        text: '$previousLabel 지출 내역이 없어요.',
        icon: Icons.info_outline_rounded,
        color: AppColors.textSecondary,
      );
    }

    final ratio = ((current - previous).abs() / previous) * 100;
    if (current > previous) {
      return (
        text: '$previousLabel보다 ${ratio.toStringAsFixed(1)}% 늘었어요.',
        icon: Icons.arrow_upward_rounded,
        color: AppColors.danger,
      );
    }
    return (
      text: '$previousLabel보다 ${ratio.toStringAsFixed(1)}% 줄었어요.',
      icon: Icons.arrow_downward_rounded,
      color: AppColors.primary,
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onChanged,
  });

  final _StatsPeriod selectedPeriod;
  final ValueChanged<_StatsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PeriodOption(
              label: '월별',
              icon: Icons.calendar_month_rounded,
              selected: selectedPeriod == _StatsPeriod.monthly,
              onTap: () => onChanged(_StatsPeriod.monthly),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _PeriodOption(
              label: '일별',
              icon: Icons.today_rounded,
              selected: selectedPeriod == _StatsPeriod.daily,
              onTap: () => onChanged(_StatsPeriod.daily),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodOption extends StatelessWidget {
  const _PeriodOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor =
        selected ? AppColors.surface : AppColors.primaryDeep;
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: foregroundColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
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
