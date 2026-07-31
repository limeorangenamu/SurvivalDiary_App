import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/pill_chip.dart';
import '../../auth/auth_session.dart';
import '../data/expense_api_client.dart';

class ExpenseForm extends StatefulWidget {
  const ExpenseForm({
    super.key,
    this.showTitle = true,
    this.onSaved,
  });

  final bool showTitle;
  final VoidCallback? onSaved;

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  final _expenseApiClient = ExpenseApiClient();
  ExpenseCategory? _category;
  DateTime? _date;
  bool _isSaving = false;
  bool _validateOnChange = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate() {
    return showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2028),
      helpText: '지출 날짜 선택',
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      if (!_validateOnChange) {
        setState(() => _validateOnChange = true);
      }
      return;
    }

    final title = _titleController.text.trim();
    final amount = int.parse(
      _amountController.text.trim().replaceAll(',', ''),
    );
    final memo = _memoController.text.trim();
    final category = _category!;
    final date = _date!;

    final currentUser = AuthSession.instance.currentUser;
    final accessToken = AuthSession.instance.accessToken;
    final userId = currentUser?.userId;

    if (userId == null || accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지출을 저장하려면 로그인이 필요해요.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _expenseApiClient.createExpense(
        accessToken: accessToken,
        request: CreateExpenseRequest(
          userId: userId,
          category: category,
          title: title,
          amount: amount,
          spentAt: DateTime(date.year, date.month, date.day),
          memo: memo.isEmpty ? null : memo,
        ),
      );

      if (!mounted) {
        return;
      }
      _titleController.clear();
      _amountController.clear();
      _memoController.clear();
      _formKey.currentState!.reset();
      setState(() {
        _category = null;
        _date = null;
        _validateOnChange = false;
      });
      widget.onSaved?.call();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('지출이 등록되었습니다.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      });
    } on ExpenseApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: _validateOnChange
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          if (widget.showTitle) ...[
            const Text('직접 지출 입력', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 4),
            const Text('알림에 없는 지출을 간단히 기록해요.', style: AppTextStyles.caption),
            const SizedBox(height: 18),
          ],
          FormField<ExpenseCategory>(
            validator: (value) =>
                value == null ? '카테고리를 선택해 주세요.' : null,
            builder: (field) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        selected: field.value == category,
                        onTap: () {
                          field.didChange(category);
                          setState(() => _category = category);
                        },
                      ),
                  ],
                ),
                if (field.hasError) ...[
                  const SizedBox(height: 7),
                  Text(
                    field.errorText!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('expense-title-field'),
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '지출 내용',
              hintText: '예: 점심 김치찌개',
            ),
            validator: (value) {
              final title = value?.trim() ?? '';
              if (title.isEmpty) {
                return '지출 내용을 입력해 주세요.';
              }
              if (title.length > 100) {
                return '지출 내용은 100자 이하로 입력해 주세요.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('expense-amount-field'),
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '금액',
              hintText: '숫자만 입력',
              suffixText: '원',
            ),
            validator: (value) {
              final rawAmount = value?.trim().replaceAll(',', '') ?? '';
              if (rawAmount.isEmpty) {
                return '금액을 입력해 주세요.';
              }
              final amount = int.tryParse(rawAmount);
              if (amount == null || amount <= 0) {
                return '올바른 금액을 입력해 주세요.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          FormField<DateTime>(
            validator: (value) => value == null ? '날짜를 선택해 주세요.' : null,
            builder: (field) => InkWell(
              onTap: () async {
                final selected = await _pickDate();
                if (selected != null) {
                  field.didChange(selected);
                  setState(() => _date = selected);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: '날짜',
                  suffixIcon: const Icon(Icons.calendar_today_rounded),
                  errorText: field.errorText,
                ),
                child: Text(
                  field.value == null
                      ? '날짜를 선택해 주세요.'
                      : Formatters.date(field.value!),
                  style: field.value == null
                      ? AppTextStyles.bodyMuted
                      : AppTextStyles.body,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _memoController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: '메모 (선택)',
              hintText: '기억할 내용을 남겨 보세요.',
            ),
            validator: (value) {
              if ((value?.trim().length ?? 0) > 200) {
                return '메모는 200자 이하로 입력해 주세요.';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          FilledButton(
            key: const ValueKey('expense-save-button'),
            onPressed: _isSaving ? null : _save,
            child: Text(_isSaving ? '저장 중...' : '지출 저장'),
          ),
          ],
        ),
      ),
    );
  }
}
