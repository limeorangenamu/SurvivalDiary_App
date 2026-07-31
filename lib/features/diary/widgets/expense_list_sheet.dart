import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models.dart';
import '../../../shared/widgets/app_card.dart';
import '../data/expense_api_client.dart';

Future<void> showExpenseListSheet({
  required BuildContext context,
  required String title,
  required List<Expense> expenses,
  required Future<void> Function(Expense expense) onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.86,
        child: _ExpenseListSheet(
          title: title,
          expenses: expenses,
          onDelete: onDelete,
        ),
      ),
    ),
  );
}

class _ExpenseListSheet extends StatefulWidget {
  const _ExpenseListSheet({
    required this.title,
    required this.expenses,
    required this.onDelete,
  });

  final String title;
  final List<Expense> expenses;
  final Future<void> Function(Expense expense) onDelete;

  @override
  State<_ExpenseListSheet> createState() => _ExpenseListSheetState();
}

class _ExpenseListSheetState extends State<_ExpenseListSheet> {
  late final List<Expense> _expenses = [...widget.expenses];
  final Set<String> _deletingExpenseIds = {};

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지출을 삭제할까요?', style: AppTextStyles.sectionTitle),
        content: const Text(
          '지출 내역은 삭제 후 복구할 수 없어요.',
          style: AppTextStyles.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '삭제',
              style: AppTextStyles.body.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _deletingExpenseIds.add(expense.id));
    try {
      await widget.onDelete(expense);
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingExpenseIds.remove(expense.id);
        _expenses.removeWhere((item) => item.id == expense.id);
      });
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('지출이 삭제되었습니다.')),
        );
    } on ExpenseApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _deletingExpenseIds.remove(expense.id));
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 3),
                    Text(
                      '총 ${_expenses.length}건',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '닫기',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: _expenses.isEmpty
              ? const Center(
                  child: Text(
                    '등록된 지출 내역이 없어요.',
                    style: AppTextStyles.bodyMuted,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
                  itemCount: _expenses.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final expense = _expenses[index];
                    final isDeleting = _deletingExpenseIds.contains(expense.id);
                    return AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: expense.category.color.withValues(
                              alpha: 0.12,
                            ),
                            foregroundColor: expense.category.color,
                            child: Icon(expense.category.icon, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense.title,
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${expense.category.label} · '
                                  '${Formatters.date(expense.date)}',
                                  style: AppTextStyles.captionTiny,
                                ),
                                if (expense.memo?.isNotEmpty == true) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    expense.memo!,
                                    style: AppTextStyles.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                Formatters.amount(expense.amount),
                                style: AppTextStyles.amount,
                              ),
                              const SizedBox(height: 2),
                              if (isDeleting)
                                const SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Padding(
                                    padding: EdgeInsets.all(7),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              else
                                IconButton(
                                  tooltip: '지출 삭제',
                                  onPressed: () => _deleteExpense(expense),
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.danger,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
