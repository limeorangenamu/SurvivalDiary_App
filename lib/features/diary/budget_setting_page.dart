import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/pill_chip.dart';
import '../auth/auth_session.dart';
import 'data/budget_api_client.dart';

class BudgetSettingPage extends StatefulWidget {
  const BudgetSettingPage({super.key, this.initialMonthly = false});

  final bool initialMonthly;

  @override
  State<BudgetSettingPage> createState() => _BudgetSettingPageState();
}

class _BudgetSettingPageState extends State<BudgetSettingPage> {
  static const presets = [20000, 30000, 35000, 50000, 70000];
  static const _maxBudgetAmount = 1000000000;

  final _apiClient = BudgetApiClient();
  final _controller = TextEditingController(text: '35000');
  int _selected = 35000;
  int _currentAmount = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isMonthly = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isMonthly = widget.initialMonthly;
    unawaited(_loadBudget());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadBudget() async {
    final token = AuthSession.instance.accessToken;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '예산을 확인하려면 로그인이 필요해요.';
      });
      return;
    }

    try {
      final amount = _isMonthly
          ? await _apiClient.getMonth(accessToken: token)
          : await _apiClient.getToday(accessToken: token);
      if (!mounted) return;
      setState(() {
        _currentAmount = amount;
        _controller.text = amount > 0 ? amount.toString() : '';
        _selected = amount > 0 && presets.contains(amount) ? amount : -1;
        _isLoading = false;
        _errorMessage = null;
      });
    } on BudgetApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    }
  }

  Future<void> _retryLoad() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _loadBudget();
  }

  void _changePeriod(bool monthly) {
    if (_isMonthly == monthly) return;
    setState(() {
      _isMonthly = monthly;
      _currentAmount = 0;
      _controller.clear();
      _selected = -1;
      _isLoading = true;
      _errorMessage = null;
    });
    unawaited(_loadBudget());
  }

  void _selectPreset(int amount) {
    setState(() {
      _selected = amount;
      _currentAmount = amount;
      _controller.text = amount.toString();
    });
  }

  Future<void> _save() async {
    final value = int.tryParse(_controller.text.replaceAll(',', ''));
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 금액을 입력해 주세요.')),
      );
      return;
    }

    if (value > _maxBudgetAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용 가능 금액은 10억원 이하로 입력해 주세요.')),
      );
      return;
    }

    final token = AuthSession.instance.accessToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('예산을 저장하려면 로그인이 필요해요.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final savedAmount = _isMonthly
          ? await _apiClient.saveMonth(accessToken: token, amount: value)
          : await _apiClient.saveToday(accessToken: token, amount: value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${Formatters.amount(savedAmount)}으로 설정했어요.')),
      );
      Navigator.of(context).pop(savedAmount);
    } on BudgetApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사용 가능 금액 설정')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _LoadError(message: _errorMessage!, onRetry: _retryLoad)
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('일일 예산')),
                ButtonSegment(value: true, label: Text('월간 예산')),
              ],
              selected: {_isMonthly},
              onSelectionChanged: (selection) =>
                  _changePeriod(selection.single),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  AppCard(
                    color: AppColors.primarySoft,
                    borderColor: AppColors.primarySoft,
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isMonthly
                                ? '한 달 동안 안심하고 쓸 수 있는 금액을 정해 보세요.'
                                : '하루에 안심하고 쓸 수 있는 금액을 정해 보세요.',
                            style: AppTextStyles.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      Formatters.amount(_currentAmount),
                      style: AppTextStyles.amount.copyWith(fontSize: 34),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 20),
                  const Text('직접 입력', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _controller,
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onChanged: (value) => setState(() {
                      _selected = -1;
                      _currentAmount = int.tryParse(value) ?? 0;
                    }),
                    decoration: const InputDecoration(
                      hintText: '금액을 입력하세요',
                      suffixText: '원',
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('빠른 금액 선택', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final amount in presets)
                        PillChip(
                          label: Formatters.amount(amount),
                          selected: _selected == amount,
                          onTap: () => _selectPreset(amount),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? '저장 중...' : '설정 저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 44),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('다시 불러오기')),
          ],
        ),
      ),
    );
  }
}
