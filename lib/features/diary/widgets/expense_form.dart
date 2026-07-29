import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/pill_chip.dart';

class ExpenseForm extends StatefulWidget {
  const ExpenseForm({super.key, this.showTitle = true});

  final bool showTitle;

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.food;
  DateTime _date = DateTime(2026, 7, 27);

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2028),
      helpText: '지출 날짜 선택',
    );
    if (selected != null) {
      setState(() => _date = selected);
    }
  }

  void _save() {
    if (_titleController.text.trim().isEmpty ||
        _amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('지출 내용과 금액을 입력해 주세요.')));
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('지출이 저장된 것처럼 처리했어요.')));
    _titleController.clear();
    _amountController.clear();
    _memoController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle) ...[
            const Text('직접 지출 입력', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 4),
            const Text('알림에 없는 지출을 간단히 기록해요.', style: AppTextStyles.caption),
            const SizedBox(height: 18),
          ],
          const Text('카테고리', style: AppTextStyles.body),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final category in ExpenseCategory.values)
                PillChip(
                  label: category.label,
                  icon: category.icon,
                  color: category.color,
                  selected: _category == category,
                  onTap: () => setState(() => _category = category),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('expense-title-field'),
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '지출 내용',
              hintText: '예: 점심 김치찌개',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('expense-amount-field'),
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '금액',
              hintText: '숫자만 입력',
              suffixText: '원',
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '날짜',
                suffixIcon: Icon(Icons.calendar_today_rounded),
              ),
              child: Text(Formatters.date(_date), style: AppTextStyles.body),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _memoController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: '메모 (선택)',
              hintText: '기억할 내용을 남겨 보세요.',
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            key: const ValueKey('expense-save-button'),
            onPressed: _save,
            child: const Text('지출 저장'),
          ),
        ],
      ),
    );
  }
}
