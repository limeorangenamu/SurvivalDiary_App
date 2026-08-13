import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';
import '../auth/auth_session.dart';
import 'data/expense_api_client.dart';
import 'expense_stats_page.dart';
import 'notification_detection/detected_expense_list.dart';
import 'widgets/expense_form.dart';

class ExpenseAddPage extends StatefulWidget {
  const ExpenseAddPage({super.key, this.initialDaily = false});

  final bool initialDaily;

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
          ExpenseStatsView(
            key: ValueKey('$_statsRevision-${widget.initialDaily}'),
            initialDaily: widget.initialDaily,
          ),
          DetectedExpenseList(
            showHeader: true,
            onExpenseSaved: _refreshStats,
          ),
          _DirectExpenseTab(onExpenseSaved: _refreshStats),
        ],
      ),
    );
  }
}

class _DirectExpenseTab extends StatefulWidget {
  const _DirectExpenseTab({required this.onExpenseSaved});

  final VoidCallback onExpenseSaved;

  @override
  State<_DirectExpenseTab> createState() => _DirectExpenseTabState();
}

class _DirectExpenseTabState extends State<_DirectExpenseTab> {
  final ExpenseApiClient _expenseApiClient = ExpenseApiClient();

  late DateTime _selectedDate;
  List<Expense> _expenses = const [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(DateTime.now());
    _loadExpenses();
  }

  List<Expense> get _selectedDateExpenses {
    final expenses = _expenses.where((expense) {
      return DateUtils.isSameDay(expense.date, _selectedDate);
    }).toList();
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  Future<void> _loadExpenses() async {
    final accessToken = AuthSession.instance.accessToken;
    if (accessToken == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = '지출 내역을 보려면 로그인이 필요해요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final expenses = await _expenseApiClient.getExpenses(
        accessToken: accessToken,
      );
      if (!mounted) return;
      setState(() {
        _expenses = expenses;
        _isLoading = false;
      });
    } on ExpenseApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = '지출 내역을 불러오지 못했어요.';
      });
    }
  }

  void _handleExpenseSaved() {
    widget.onExpenseSaved();
    _loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    final selectedExpenses = _selectedDateExpenses;
    final totalAmount = selectedExpenses.fold<int>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    return ListView(
      key: const PageStorageKey('direct-tab-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: _ExpenseCalendar(
            selectedDate: _selectedDate,
            firstDate: DateTime(2024),
            lastDate: DateUtils.dateOnly(DateTime.now()),
            onDateChanged: (date) {
              setState(() {
                _selectedDate = DateUtils.dateOnly(date);
              });
            },
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                '${Formatters.date(_selectedDate)} 지출',
                style: AppTextStyles.sectionTitle,
              ),
            ),
            if (!_isLoading && _loadError == null)
              Text(
                '${selectedExpenses.length}건 · ${Formatters.amount(totalAmount)}',
                style: AppTextStyles.caption,
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_isLoading)
          const AppCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              ),
            ),
          )
        else if (_loadError != null)
          AppCard(
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loadExpenses,
                  child: const Text('다시 불러오기'),
                ),
              ],
            ),
          )
        else if (selectedExpenses.isEmpty)
          const AppCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '이날 등록된 지출이 없어요.',
                    style: AppTextStyles.bodyMuted,
                  ),
                ],
              ),
            ),
          )
        else
          ...selectedExpenses.map(
            (expense) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: expense.category.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        expense.category.icon,
                        size: 20,
                        color: expense.category.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            expense.memo == null || expense.memo!.isEmpty
                                ? expense.category.label
                                : '${expense.category.label} · ${expense.memo}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      Formatters.amount(expense.amount),
                      style: AppTextStyles.amount.copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        const Text(
          '선택한 날짜에 지출 등록',
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: 4),
        Text(
          '${Formatters.date(_selectedDate)}에 지출을 추가해요.',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 10),
        ExpenseForm(
          showTitle: false,
          selectedDate: _selectedDate,
          onSaved: _handleExpenseSaved,
        ),
      ],
    );
  }
}

class _ExpenseCalendar extends StatefulWidget {
  const _ExpenseCalendar({
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
  });

  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  State<_ExpenseCalendar> createState() => _ExpenseCalendarState();
}

class _ExpenseCalendarState extends State<_ExpenseCalendar> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = _monthOf(widget.selectedDate);
  }

  @override
  void didUpdateWidget(_ExpenseCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameDay(widget.selectedDate, oldWidget.selectedDate) &&
        !_isSameMonth(widget.selectedDate, _displayedMonth)) {
      _displayedMonth = _monthOf(widget.selectedDate);
    }
  }

  DateTime _monthOf(DateTime date) => DateTime(date.year, date.month);

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  bool _isBeforeFirstMonth(DateTime month) {
    return month.year < widget.firstDate.year ||
        (month.year == widget.firstDate.year &&
            month.month < widget.firstDate.month);
  }

  bool _isAfterLastMonth(DateTime month) {
    return month.year > widget.lastDate.year ||
        (month.year == widget.lastDate.year &&
            month.month > widget.lastDate.month);
  }

  bool _isSelectable(DateTime date) {
    final day = DateUtils.dateOnly(date);
    return !day.isBefore(DateUtils.dateOnly(widget.firstDate)) &&
        !day.isAfter(DateUtils.dateOnly(widget.lastDate));
  }

  void _changeMonth(int offset) {
    final nextMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + offset,
    );
    if (_isBeforeFirstMonth(nextMonth) || _isAfterLastMonth(nextMonth)) {
      return;
    }
    setState(() => _displayedMonth = nextMonth);
  }

  void _changeYear(int year) {
    var month = _displayedMonth.month;
    if (year == widget.firstDate.year && month < widget.firstDate.month) {
      month = widget.firstDate.month;
    }
    if (year == widget.lastDate.year && month > widget.lastDate.month) {
      month = widget.lastDate.month;
    }
    setState(() => _displayedMonth = DateTime(year, month));
  }

  @override
  Widget build(BuildContext context) {
    final firstMonth = _monthOf(widget.firstDate);
    final lastMonth = _monthOf(widget.lastDate);
    final canMovePrevious = !_isSameMonth(_displayedMonth, firstMonth);
    final canMoveNext = !_isSameMonth(_displayedMonth, lastMonth);
    final firstDay = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    final leadingEmptyDays = firstDay.weekday % DateTime.daysPerWeek;
    final daysInMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;
    final weekdays = MaterialLocalizations.of(context).narrowWeekdays;

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: canMovePrevious ? () => _changeMonth(-1) : null,
              enableFeedback: false,
              tooltip: '이전 달',
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Center(
                child: PopupMenuButton<int>(
                  initialValue: _displayedMonth.year,
                  enableFeedback: false,
                  tooltip: '연도 선택',
                  onSelected: _changeYear,
                  itemBuilder: (context) => [
                    for (var year = widget.firstDate.year;
                        year <= widget.lastDate.year;
                        year++)
                      PopupMenuItem<int>(
                        value: year,
                        child: Text('$year년'),
                      ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_displayedMonth.year}년 ${_displayedMonth.month}월',
                          style: AppTextStyles.sectionTitle,
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: canMoveNext ? () => _changeMonth(1) : null,
              enableFeedback: false,
              tooltip: '다음 달',
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var index = 0; index < weekdays.length; index++)
              Expanded(
                child: Center(
                  child: Text(
                    weekdays[index],
                    style: AppTextStyles.caption.copyWith(
                      color: index == 0
                          ? AppColors.danger
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: DateTime.daysPerWeek,
            childAspectRatio: 1.05,
          ),
          itemCount: leadingEmptyDays + daysInMonth,
          itemBuilder: (context, index) {
            if (index < leadingEmptyDays) {
              return const SizedBox.shrink();
            }

            final day = index - leadingEmptyDays + 1;
            final date = DateTime(
              _displayedMonth.year,
              _displayedMonth.month,
              day,
            );
            final isSelected = DateUtils.isSameDay(date, widget.selectedDate);
            final isToday = DateUtils.isSameDay(date, DateTime.now());
            final isSelectable = _isSelectable(date);

            return Padding(
              padding: const EdgeInsets.all(3),
              child: InkWell(
                onTap: isSelectable
                    ? () => widget.onDateChanged(DateUtils.dateOnly(date))
                    : null,
                enableFeedback: false,
                borderRadius: BorderRadius.circular(999),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.primary)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: AppTextStyles.body.copyWith(
                        color: !isSelectable
                            ? AppColors.textTertiary.withValues(alpha: 0.45)
                            : isSelected
                                ? AppColors.surface
                                : AppColors.textPrimary,
                        fontWeight: isSelected || isToday
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
