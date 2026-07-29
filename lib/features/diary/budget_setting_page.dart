import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/pill_chip.dart';

class BudgetSettingPage extends StatefulWidget {
  const BudgetSettingPage({super.key});

  @override
  State<BudgetSettingPage> createState() => _BudgetSettingPageState();
}

class _BudgetSettingPageState extends State<BudgetSettingPage> {
  static const presets = [20000, 30000, 35000, 50000, 70000];
  final _controller = TextEditingController(text: '35000');
  int _selected = 35000;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectPreset(int amount) {
    setState(() {
      _selected = amount;
      _controller.text = amount.toString();
    });
  }

  void _save() {
    final value = int.tryParse(_controller.text.replaceAll(',', ''));
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('올바른 금액을 입력해 주세요.')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${Formatters.amount(value)}으로 설정했어요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사용 가능 금액 설정')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const AppCard(
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
                              '하루에 안심하고 쓸 수 있는 금액을 정해 보세요.',
                              style: AppTextStyles.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('직접 입력', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() => _selected = -1),
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
              FilledButton(onPressed: _save, child: const Text('설정 저장')),
            ],
          ),
        ),
      ),
    );
  }
}
